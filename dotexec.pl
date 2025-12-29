#!/usr/bin/perl

# dotexec.pl - execute command with environment loaded from dot env file
#
# Usage: dotexec.pl <path-to-env-file> [command]
#
# Path to env file is optional. If not present, several options for the name
# of the file will be checked:
#
# .env
# .env.local
# .env.prod
# env
# envlocal
# 
# Run command with DEBUG=1 to see parsed variables.
#
# dprelec, 2024-05-14

use 5.014;
use strict;
use warnings;
use File::Slurp qw/read_file/;

sub debug {
    if (not defined $ENV{DEBUG} or $ENV{DEBUG} ne "1") {
        return;
    }
    say "DEBUG[$0]: @_";
}

if ((scalar @ARGV) < 1) {
    die "Usage: $0 <optional-dot-env-file> <command>";
}

if ($ARGV[0] =~ /\-\-?he?l?p?/) {
    say "Usage: $0 <optional-dot-env-file> <command>";
    exit;
}

my $dot_env_file;
my @command;

if ($ARGV[0] =~ /\.?env.*/) {
    $dot_env_file = $ARGV[0];
    shift @ARGV;
    @command = @ARGV;
}
else {
    $dot_env_file = '.env';
    @command = @ARGV;
}

debug("dotenv:", $dot_env_file);
debug("command:", @command);

# parse and export dotenv entries
my @dot_env_contents = read_file($dot_env_file);
for my $line (@dot_env_contents) {
    chomp $line;

    # skip empty lines
    next if $line =~ /^\s*$/;

    # skip comments
    next if $line =~ /^#/;
 
    my @parts = split(/\s*=\s*/, $line);
    next if (scalar @parts) != 2;

    debug($parts[0]."=".$parts[1]);    
    $ENV{$parts[0]} = $parts[1];
}

# execute command with the environment containing exported entries above
system(@command);
