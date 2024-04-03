#!/usr/bin/perl

# collect and print imported libraries in Go files
# dprelec, 2018-11-19

use 5.010;
use strict;
use warnings;

# collect libraries by type
my %std; 
my %external;

die "Usage: $0 FILENAMEs\n" if not @ARGV;
for my $file (@ARGV) {
    next unless -f $file;
    open my $fh, '<:encoding(UTF-8)', $file or die "Error: $!";
    my $seen_import = 0;
    while (defined(my $line = <$fh>)) {
        # skip empty import
        if ($line =~ /^import\s*\(\s*\)\s*$/) {
            next;
        }
        # single line import
        if ($line =~ /^import\s*\"([^"]+)\"\s*$/) {
            my $match = "\"$1\"";
            if ($match =~ /\./) {
                $external{$match}++;
            }
            else {
                $std{$match}++;
            }
            next;
        }
        # start collecting imports
        if ($line =~ /^import\s*\(/) {
            $seen_import = 1;
            next;
        }
        # stop collecting imports
        if ($seen_import and $line =~ /^\s*\)\s*$/) {
            $seen_import = 0;
            last;
        }
        # process import line
        if ($seen_import) {
            # ignore commented-out import lines
            if ($line =~ m|^\s*//|) {
                next;
            }
            # trim spaces
            $line =~ s/^\s+//;
            $line =~ s/\s+$//;
            # filter out aliases
            my @parts = grep /\"/, split(/\s+/, $line);
            if (@parts > 0) {
                my $match = $parts[0];

                # doesnt look like import line
                if ($match !~ /^\"[^\"]+\"$/) {
                    next;
                }

                # external libs mostly look like URLs
                if ($match =~ /\./) {
                    $external{$match}++;
                }
                else {
                    $std{$match}++;
                }
            }
        }
    }
}

for my $key (sort keys %std) {
    say $key;
}

for my $key (sort keys %external) {
    say $key;
}
