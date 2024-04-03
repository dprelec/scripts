#!/usr/bin/perl

=head1 NAME

mgrep (multi-grep) - expand search patterns into piped greps

=cut

=head1 SYNOPSIS
   
mgrep pattern1 [pattern2, pattern3 ...] files

Search multiple patterns in any order:

mgrep alfa beta input.txt

Combine search patterns with skip patterns (specified with `-'):

mgrep alfa -beta input.txt 

Search list of files:

mgrep alfa -beta *.txt

Search all files in current directory (default):

mgrep alfa -beta

Search standard input (specified with `--'):

mgrep alfa -beta --

=cut

=head1 DESCRIPTION

Mgrep converts search patterns into a single command where each pattern greps 
the previous one, and then it executes this command.

Mgrep expects a list of search and skip patterns to convert them
into piped grep calls. If any of the input arguments is a file name, this
file name will be searched with the first grep command. 

If no file name is specified, all files found in current directory will be 
searched.

If passed `--' as argument, standard input will be searched. If any other 
file is specified alongside this argument it gets ignored.

Skip patterns will be performed first in the chain although performance-wise
this is probably unnecessary.

In the final output the search patterns will be printed in color.

NOTE: All patterns will be performed as case-insensitive searches.

=head1 HOW IT WORKS

The list of patterns gets converted to pipe grep calls like this:

mgrep pat1 pat2 -pat3 input.txt

is converted to:

grep -i pat1 input.txt | grep -i pat2 | grep -v -i pat3

=cut

=head1 CONFIGURATION 

To print debug statements call with DEBUG=1.

To override default grep command set GREP='other-grep'.
Example: `GREP=ag mgrep.pl search me -not -you in.txt`.

=cut

# dprelec, 2020-08-19

use 5.010;
use autodie;
use strict;
use warnings;
use Cwd;
use Pod::Usage;
use Term::ANSIColor;

$|++;

sub debug {
    return unless $ENV{DEBUG} and $ENV{DEBUG} == 1;
    print STDERR "[DEBUG] @_\n";
}

my @colors = (
    'red bold',
    'blue bold',
    'green bold',
    'yellow bold',
);

sub color_substr {
    my $str = shift;
    my $substr = shift;
    state $color_idx = 0;
    state %color_map;
    if (not exists $color_map{$substr}) {
        $color_map{$substr} = $colors[$color_idx++ % $#colors];
    }
    $str =~ s/($substr)/colored($1, $color_map{$substr})/egi;
    return $str;
}

sub check_regex {
    my $re_str = shift;
    eval {qr/$re_str/};
    if ($@) {
        say "Error compilining regex '$re_str': $@";
        exit 1;
    }
}

sub grep_command {
    return $ENV{GREP} if defined $ENV{GREP} and $ENV{GREP} ne "";
    return "grep";
}

sub local_files {
    opendir(my $dh, getcwd());
    my @files = grep {-f $_} readdir($dh);
    closedir($dh);
    return @files;
}

if (scalar(@ARGV) == 0) {
    say pod2usage();
    exit 0;
}

my $grep = grep_command();

my $stdin;
my @files;
my @search;
my @skip;

debug("args: @ARGV");

for my $arg (@ARGV) {
    # argument is file
    if (-f $arg) {
        push @files, $arg;
        next;
    }
    # argument is '--' - check it before skip patterns
    if ($arg eq '--') {
        $stdin = $arg;
        next;
    }
    # argument is skip pattern
    if ($arg =~ /^\-(.+)/) {
        push @skip, $1;
        next;
    }
    # normal search pattern
    push @search, $arg;
}

# override input files if reading from stdin
if (defined $stdin and $stdin eq '--') {
    @files = ($stdin);
}

# search files in current directory
if (scalar(@files) == 0) {
    @files = local_files();
}

if (scalar(@search) == 0 and scalar(@skip) == 0) {
    say "No patterns specified.";
    say pod2usage();
    exit 1;
}

my @cmd;
for my $pat (@skip) {
    check_regex($pat);
    push @cmd, qq/$grep -i -v "$pat"/;
}
for my $pat (@search) {
    check_regex($pat);
    push @cmd, qq/$grep -i "$pat"/;
}

# quote file names
my $input = join(" ", map qq("$_"), @files);

# inject file names to first grep call
my $first = shift @cmd;
unshift @cmd, "$first $input";

my $cmd = join(" | ", @cmd);
debug($cmd);

my $out = `$cmd`;
my @lines = split /[\r\n]+/, $out;

for my $line (@lines) {
    for my $pat (@search) {
        $line = color_substr($line, $pat);
    }
    say $line;
}

# print basic stats
my $sum_lines = scalar(@lines);
my $result = "result";
if ($sum_lines == 0 or $sum_lines > 1) {
    $result = "results";
}
        
say "$sum_lines ${result}.";
