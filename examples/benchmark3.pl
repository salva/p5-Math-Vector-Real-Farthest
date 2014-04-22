#!/usr/bin/perl

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::Farthest;

use Benchmark qw(cmpthese);
use Time::HiRes qw(time);

$|=1;

my $max_size = shift // 1e6;


for (1..1000) {
    my $dim = 1 + int rand 6;
    my $box = Math::Vector::Real->random_in_box($dim, 1);
    my $n = 100 + int(2**rand(17));
    my @v = map $box->random_in_box, 1..$n;

    # printf "running benchmark with dim: $dim, n: $n";

    my $start = time;
    my ($d2, $v0, $v1, $comp) = Math::Vector::Real::Farthest->find(@v);
    my $end = time;
    printf "dim: %i, n: %i time: %f comp: %i\n", $dim, $n, $end-$start, $comp;
}
