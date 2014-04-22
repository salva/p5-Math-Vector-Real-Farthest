package Math::Vector::Real::Farthest;

our $VERSION = '0.01';

use strict;
use warnings;

use Math::Vector::Real;
use Sort::Key::Top qw(nkeypartref);
use Math::nSphere qw(nsphere_volumen);

our $optimization_core = 1;
our $optimization_asymmetric = 1;

use constant _c0 => 0;
use constant _c1 => 1;
use constant _n  => 2;
use constant _vs => 3;
use constant _s0 => 4;
use constant _s1 => 5;

use constant _threshold => 5;

sub find_brute_force {
    my $class = shift;
    return unless @_;
    my $best_d2 = 0;
    my $best_v0 = $_[0];
    my $best_v1 = $_[0];

    for my $i (0..$#_) {
        for my $j ($i + 1..$#_) {
            my $vi = $_[$i];
            my $vj = $_[$j];
            my $d2 = Math::Vector::Real::dist2($vi, $vj);
            if ($d2 > $best_d2) {
                $best_d2 = $d2;
                $best_v0 = $vi;
                $best_v1 = $vj;
            }
        }
    }

    wantarray ? ($best_d2, V(@$best_v0), V(@$best_v1)) : $best_d2;
}

sub find {

    # for a few elements the brute force algorithm works better
    @_ < 11 and goto &find_brute_force;

    my $class = shift;
    my $O = 1;
    my ($best_v0, $best_v1,);
    my ($c0, $c1) = Math::Vector::Real->box(@_);
    my $diag = $c1 - $c0;
    my $max_comp = $diag->max_component;
    my $best_d2 = $max_comp * $max_comp;
    if ($best_d2) {

        my $vs0;
        my $zero = 0.5 * ($c0 + $c1);

        if ($optimization_core) {
            # There is a place in the center of the box which is
            # guaranteed to not contain any of the target vectors.  We
            # calculate its aproximate hyper-volumen and if it is at least
            # 10% of that of the box we filter out the points within. This
            # heuristic works well when the vectors are evenly
            # distributed.

            # TODO: benchmark with and without this optimization to
            # discover if it really makes a difference

            my $nellipsoid_volumen = nsphere_volumen(scalar(@$diag));
            my $ncube_volumen = 1;
            my $half = 0.5 * $diag;
            my $t2 = $half->abs2 - $best_d2;
            for my $ix (0..$#$half) {
                my $y = $half->[$ix];
                my $y2 = $y * $y;
                if ($t2 + 3 * $y2 > 0) {
                    if ($y2 > $t2) {
                        $y = sqrt($y2 - $t2) - $y;
                    }
                    else {
                        $y = 0;
                    }
                }
                $nellipsoid_volumen *= $y;
                $ncube_volumen *= $diag->[$ix];
            }

            # we don't want to discard points that are at a distance
            # exactly equal to the bigest box side, so we apply a small
            # correction factor here:
            $best_d2 *= 0.99999;

            if ($nellipsoid_volumen > $ncube_volumen * 0.1) {
                # we aim at discarding at least 10% of the points
                my $corner = $c0 - $zero;
                $vs0 = [grep { Math::Vector::Real::dist2($corner, ($_ - $zero)->first_orthant_reflection) > $best_d2 } @_];
                # printf("filtered %d => %d (%.2f%%, estimated %.2f%%)\n",
                #        scalar(@_), scalar(@$vs0),
                #        100 * @$vs0/@_,
                #        100 * (1 - $nellipsoid_volumen / $ncube_volumen));
            }
            else {
                $vs0 = \@_;
                # printf "skipping filtering, volumen ratio: %.2%%f)\n", $nellipsoid_volumen / $ncube_volumen * 100;
            }
        }
        else {
            $best_d2 *= 0.99999;
            $vs0 = \@_;
        }

        my @d2 = $diag->abs2;
        my @a = [$c0, $c1, scalar(@$vs0), $vs0];
        my @b;

        if ($optimization_asymmetric) {
            my $best_half_d2 = 0.25 * $best_d2;
            my $vs1 = [ grep { Math::Vector::Real::dist2($zero, $_) > $best_half_d2 } @$vs0];
            @b = [$c0, $c1, scalar(@$vs1), $vs1];
        }
        else {
            @b = @a;
        }

        while (@d2) {
            my $d2 = pop @d2;
            $d2 > $best_d2 or last;
            $O++;
            my $a = pop @a;
            my $b = pop @b;
            ($a, $b) = ($b, $a) if ($a->[_n] < $b->[_n]);
            if (my $avs = $a->[_vs]) {
                if ($a->[_n] <= _threshold) {
                    # brute force
                    for my $v0 (@{$b->[_vs]}) {
                        for my $v1 (@$avs) {
                            my $d2 = Math::Vector::Real::dist2($v0, $v1);
                            if ($best_d2 < $d2) {
                                $best_d2 = $d2;
                                $best_v0 = $v0;
                                $best_v1 = $v1;
                            }
                        }
                    }
                    next;
                }

                # else part it in two...

                my $ix = ($a->[_c0] - $a->[_c1])->max_component_index;
                my ($avs0, $avs1) = nkeypartref { $_->[$ix] } @$avs / 2 => @$avs;
                $a->[_s0] = [Math::Vector::Real->box(@$avs0), scalar(@$avs0), $avs0];
                $a->[_s1] = [Math::Vector::Real->box(@$avs1), scalar(@$avs1), $avs1];
                undef $a->[_vs];

                # and fall-through...
            }

            for my $s (@{$a}[_s0, _s1]) {
                my $d2 = Math::Vector::Real->max_dist2_between_boxes(@{$s}[_c0, _c1], @{$b}[_c0, _c1]);
                if ($d2 > $best_d2) {
                    my $p;
                    for ($p = @d2; $p > 0; $p--) {
                        last if $d2[$p - 1] <= $d2;
                    }
                    splice @d2, $p, 0, $d2;
                    splice @a, $p, 0, $s;
                    splice @b, $p, 0, $b;
                }
            }
            # print "@d2\n";
        }
    }
    else {
        $best_v0 = $_[0];
        $best_v1 = $_[0];
    }
    wantarray ? ($best_d2, V(@$best_v0), V(@$best_v1), $O) : $best_d2;
}

1;
__END__

=head1 NAME

Math::Vector::Real::Farthest - Find the two more distant vectors from a set

=head1 SYNOPSIS

  use Math::Vector::Real::Farthest;
  my ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@vs);

=head1 DESCRIPTION

This module implements an algorithm based on a k-d Tree for finding
the two more distant vectors from a given set.

The complexity of the algorithm is O(N*logN)

=head2 METHODS

The methods available are as follows:

=over 4

=item ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find(@vs)

Returns the square of the maximun distance between any two vectors on
the given set and some two vectors which are actually that far away.

=item ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find_brute_force(@vs)

This is an alternate version that uses the brute force algorithm.

Note that C<find> switchs automatically to this algorithm when the
number of vectors is low.

This method is provided just for testing pourposes. Though, note that
the vectors returned by C<find> and C<find_brute_force> for the same
given set may be different.

=back

=head1 SEE ALSO

L<Math::Vector::Real>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Salvador FandiE<ntilde>o
E<lt>sfandino@yahoo.comE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
