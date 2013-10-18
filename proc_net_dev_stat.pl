#!/usr/bin/perl 

# NAME.pl
# date

use 5.010;
use strict;
use warnings;

sub read_proc_net_dev () {
    my $file = '/proc/net/dev';
    my @lines;
    my $fh;
    open $fh, "<", $file or die $!;
    while (<$fh>) {
        chomp;
        push @lines, $_;
    }
    return @lines;
}

sub parse_proc_net_dev ($) {
    my $dev = shift;
    my @k = qw/bytes packets errs drop fifo frame compressed multicast/;
        
    my @lines = read_proc_net_dev();
    my @stat = (split /[: ]+/, (grep /$dev/, @lines)[0])[2..17]; 
        
    my %rx;
    my %tx;
        
    @rx{@k} = @stat[0..7];
    @tx{@k} = @stat[8..15];

    return \%rx, \%tx;
}

sub display_rx_tx_speed ($) {
    my $dev = shift;
    my $rx_bytes = 0;
    my $tx_bytes = 0;
    my $dt = 1000;

    my $cnt = 0;
    while (++$cnt) {
        my ($rx, $tx) = parse_proc_net_dev($dev);
        my $rx_bytes_1 = $rx->{bytes};
        my $tx_bytes_1 = $tx->{bytes};
    
        my $rx_speed = ($rx_bytes_1 - $rx_bytes)/$dt;
        my $tx_speed = ($tx_bytes_1 - $tx_bytes)/$dt;
    
        my $rxs = "RX: " . sprintf("%10.2f", $rx_speed) . "KB/s";
        my $txs = "TX: " . sprintf("%10.2f", $tx_speed) . "KB/s";
    
        if ($cnt > 1) {
            say "$dev: $rxs $txs";
        }

        $rx_bytes = $rx_bytes_1;
        $tx_bytes = $tx_bytes_1;
    
        sleep(1);
    }
}

display_rx_tx_speed('eth0');


