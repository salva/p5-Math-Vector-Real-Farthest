#!/usr/bin/perl

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::Farthest;

use Benchmark qw(cmpthese);

$| = 1;

for my $p2 (0..100) {
    my $size = int(10 * 1.1 ** $p2);
    print "\nsize: $size";
    for my $dim (1..6) {
        print "\ndim: $dim\n";
        my @v = map Math::Vector::Real->random_normal($dim), 1..$size;
        cmpthese(-1,
                 {
                  kdtree => sub { my $d = Math::Vector::Real::Farthest->find(@v) },
                  brute_force => sub { my $d = Math::Vector::Real::Farthest->find_brute_force(@v) },
                 }
                );
    }
}
