#!/usr/bin/perl 

# knights_tour_graph.pl
# - generate graphviz graph of knight's tour on chess board
# dprelec, 2013-09-20

use 5.010;
use strict;
use warnings;
use signatures;
use Graph::Undirected;

sub on_board ($pos, $X, $Y) {
    my ($x, $y) = @$pos;
    return ($x >= 0 and $x < $X and $y >= 0 and $y < $Y) ? $pos : ();
}

sub positions ($pos, $X, $Y) {
    my ($x, $y) = @$pos;
    return map on_board($_, $X, $Y),  
    (
        [$x + 2, $y + 1], [$x + 2, $y - 1], [$x + 1, $y + 2], [$x + 1, $y - 2],
        [$x - 2, $y + 1], [$x - 2, $y - 1], [$x - 1, $y + 2], [$x - 1, $y - 2],
    );
}

sub name ($pos) {
    my ($x, $y) = @$pos;
    my @names = 'A' .. 'Z';
    $y++;
    return "$names[$x]$y";
}

sub knights_graph ($X, $Y) {
    my $graph = Graph::Undirected->new;

    # starting position
    my @stack = ([0, 0]);

    while (@stack != 0) {
        my @add_to_stack;

        while (my $node = pop @stack) {
            my @children = positions($node, $X, $Y);
            for my $child (@children) {
                next if $graph->has_edge(name($node), name($child));

                push @add_to_stack, $child;
                $graph->add_edge(name($node), name($child));
            }
        }

        push @stack, @add_to_stack;
    }

    return $graph;
}

sub dump_dot ($file, $graph, $X, $Y) {
    open my $fh, , ">", $file or die "Cannot open $file: $!";
    
    say $fh "graph chess_knights_tour_${X}x$X {";
    say $fh "node [shape=box, width=0.4, height=0.4]";

    for my $edge ($graph->edges) {
        my ($from, $to) = @$edge;
        say $fh "  $from -- $to;";
    }

    say $fh "}";
    close $fh;
}

sub main ($X, $Y) {
    my $graph = knights_graph($X, $Y);
    my $file = "tour_${X}x$Y.dot";
    my $img = "tour_${X}x$Y.gif";

    dump_dot($file, $graph, $X, $Y);
    system "neato -Tgif $file > $img";

    say "Knight's Tour ${X}x$Y";
    say " + generated dot $file";
    say " + generated neato $img";
}

main(4, 4);

