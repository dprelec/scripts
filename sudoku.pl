#!/bin/env perl

# sudoku.pl - backtracking brute force sudoku solver
#
# Implementacija obiènog brute force solvera za sudoku, koji za backtracking
# koristi samo moguæe vrijednosti (a ne sve moguæe) generirane u
# init_generators().
#
# dprelec, 2012-08-29

# Input example:
# 003020600900305001001806400008102900700000008006708200002609500800203009005010300
# Outputs:
# 483921657967345821251876493548132976729564138136798245372689514814253769695417382

use 5.010;
use strict;
use warnings;
use signatures;

my $puzzle_str = shift or die "ERROR: Puzzle string needed!\n";
$puzzle_str =~ s/[^0-9]/0/g;
my @puzzle = split(//, $puzzle_str);
if (@puzzle != 81) {
    die "ERROR: Invalid puzzle form!\n";
}

my $POINTER = -1;
my @G = init_generators();

solve_puzzle();
draw_puzzle(join '', @puzzle);

# all elements in a given 3x3 box
sub box_elems ($idx) {
    my $max_div9 = int($idx/9) * 9;
    my $off_x = ($idx - $max_div9) % 3;
    my $off_y = ($max_div9/9) % 3;
    my $ul = $idx - $off_x - $off_y * 9;
    return @puzzle[map $ul+$_, 0, 1, 2, 9, 10, 11, 18, 19, 20];
}

# all elements along the vertical line
sub vline_elems ($idx) {
    my $max_div9 = int($idx/9) * 9;
    return @puzzle[$max_div9 .. $max_div9 + 8]
}

# all elements along the horizontal line
sub hline_elems ($idx) {
    my $max_div9 = int($idx/9) * 9;
    my $dx = $idx - $max_div9;
    return map $puzzle[$dx + $_*9], (0 .. 8);
}

# return numbers > 0 (0 is a magic number, meaning empty cell)
sub nums (@e) {
    return grep $_ != 0, @e;
}

# are elements unique
sub is_uniq_nums (@elems) {
    my %f;
    for my $i (nums(@elems)) {
        return if ++$f{$i} > 1;
    }
    return 1;
}

# are elements unique along the horizontal and vertical line for a given cell
sub is_uniq_cross ($idx) {
    return unless is_uniq_nums(vline_elems($idx));
    return unless is_uniq_nums(hline_elems($idx));
    return 1;
}

# are elements unique in a given box 
sub is_uniq_box ($idx) {
    return is_uniq_nums(box_elems($idx));
}

# initiate all possible states for the empty cells
sub init_generators {
    my @generators;
    my @empty_cells = grep $puzzle[$_] == 0, 0 .. $#puzzle;
    for my $i (@empty_cells) {
        my %f;
        $f{$_}++ for nums(box_elems($i), vline_elems($i), hline_elems($i));
        my @gens = grep {not exists $f{$_}} 1 .. 9;
        if (@gens == 1) {
            $puzzle[$i] = $gens[0];
        }
        else {
            push @generators, {
                p => -1,
                cell => $i,
                nums => [@gens],
            };
        }
    }
    return @generators;
}

# check if a cell configuration is OK for a given cell
sub cell_conf_ok ($cell) {
    my $idx = $cell->{cell};
    return unless is_uniq_cross($idx);
    return unless is_uniq_box($idx);
    return 1;
}

# loop possible states until there are states
sub next_num ($cell) {
    $cell->{p}++;
    return $cell->{nums}[$cell->{p}];
}

# increment pointer to the next cell to be inspected
sub next_cell {
    return $G[++$POINTER];
}

# decrement pointer to previous cell
sub prev_cell {
    put_num(0, $G[$POINTER]);
    $G[$POINTER]{p} = -1;
    $POINTER--;
    if ($POINTER < 0) {
        die "ERROR: we've backtracked too far. Puzzle is not correct!\n";
    }
    else {
        return $G[$POINTER];
    }
}

# we'll try this current $n for a possible solution 
sub put_num ($n, $cell) {
    my $idx = $cell->{cell};
    $puzzle[$idx] = $n;
}

# main logic - iterate and backtrack
sub solve_puzzle {
    CELL: while (my $cell = next_cell()) {
        NUM: while (my $n = next_num($cell)) {
            put_num($n, $cell);
            cell_conf_ok($cell) and next CELL;
        }
        $cell = prev_cell() and goto NUM;
    }
}

# print simple representation of a puzzle string
sub draw_puzzle ($puzzle) {
    $puzzle =~ s/0/./g;
    my (@cells) = $puzzle =~ /(...)/g;
    my $cols = 1;
    my $rows = 1;
    print '-' x 13 . "\n";
    for my $cell (@cells) {
        print "|$cell";
        if ($cols++ % 3 == 0) {
            print "|\n";
            if ($rows++ % 3 == 0) {
                print "" . ('-' x 13) . "\n";
            }
        }
    }
    print "\n";
}



