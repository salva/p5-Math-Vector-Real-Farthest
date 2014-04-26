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

my @v = ();
while (@v < $max_size) {
    my $inc = @v * 0.3;

    push @v, map Math::Vector::Real->random_normal(3), 0..$inc;
    # push @v, map Math::Vector::Real->random_in_box(3, 1), 0..$inc;
    my $size = @v;

    # print "benchmarking, size: $size\n";

    my $start = time;
    my ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@v);
    my $end = time;
    printf "size: %i time: %f\n", $size, $end-$start;
}
