#!/usr/bin/perl

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::Farthest;

use Benchmark qw(cmpthese);

$| = 1;

my $dim = 2;

my $iters = shift @ARGV || 30;

for my $p2 (0..$iters) {
    my $size = int(100 * 1.3 ** $p2);
    print "\nsize: $size\n";
    my @v = map Math::Vector::Real->random_normal($dim), 1..$size;
    cmpthese(-1,
             {
              none => sub {
                  $Math::Vector::Real::Farthest::optimization_convex_hull = 0;
                  my $d = Math::Vector::Real::Farthest->find(@v)
              },
              convex_hull => sub {
                  $Math::Vector::Real::Farthest::optimization_convex_hull = 1;
                  my $d = Math::Vector::Real::Farthest->find(@v)
              },
             }
            );
}
