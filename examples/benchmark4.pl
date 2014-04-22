#!/usr/bin/perl

use strict;
use warnings;

use Math::Vector::Real;
use Math::Vector::Real::Random;
use Math::Vector::Real::Farthest;

use Benchmark qw(cmpthese);

$| = 1;

for my $p2 (0..30) {
    my $size = int(100 * 1.3 ** $p2);
    print "\nsize: $size";
    for my $dim (2..6) {
        print "\ndim: $dim\n";
        my @v = map Math::Vector::Real->random_in_box($dim), 1..$size;
        cmpthese(-1,
                 {
                  none => sub {
                      $Math::Vector::Real::Farthest::optimization_core = 0;
                      $Math::Vector::Real::Farthest::optimization_asymmetric = 0;
                      my $d = Math::Vector::Real::Farthest->find(@v)
                  },
                  core => sub {
                      $Math::Vector::Real::Farthest::optimization_core = 1;
                      $Math::Vector::Real::Farthest::optimization_asymmetric = 0;
                      my $d = Math::Vector::Real::Farthest->find(@v)
                  },
                  asymmetric => sub {
                      $Math::Vector::Real::Farthest::optimization_core = 0;
                      $Math::Vector::Real::Farthest::optimization_asymmetric = 1;
                      my $d = Math::Vector::Real::Farthest->find(@v)
                  },
                  both => sub {
                      $Math::Vector::Real::Farthest::optimization_core = 1;
                      $Math::Vector::Real::Farthest::optimization_asymmetric = 1;
                      my $d = Math::Vector::Real::Farthest->find(@v)
                  },
                 }
                );
    }
}
