#!/usr/bin/perl

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::Farthest;
use Time::HiRes qw(time);
use List::Util qw(shuffle);
$| = 1;

my $reps = 10;
my @ths = (4..30);
print "# ", join(', ', 'size/th', @ths), "\n";
my $p2 = 0;
while (1) {
    my $size = int(20 * 1.05 ** $p2);
    $p2 += 1;
    last if $size > 2e5;

    for my $dim (2) {
        my @times;
        for (1..$reps) {
            my @v = map Math::Vector::Real->random_normal($dim), 1..$size;
            for my $th (shuffle @ths) {
                $Math::Vector::Real::Farthest::threshold_brute_force = $th;
                my $start = time;
                my $d2 = Math::Vector::Real::Farthest->find(@v);
                my $end = time;
                $times[$th] += $end - $start;
            }
        }
        print join(', ', $size, map $times[$_]/$reps/$size, @ths), "\n";
    }
}
