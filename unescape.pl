#!/usr/bin/perl

# unescape.pl - write URL-unescaped string
# dprelec, 2020-08-31

use 5.010;
use strict;
use warnings;
use URI::Escape qw/uri_unescape/;

if (defined (my $line = shift)) {
    say uri_unescape($line);
    exit;
}

while (defined (my $line = <>)) {
    print uri_unescape($line);
}
