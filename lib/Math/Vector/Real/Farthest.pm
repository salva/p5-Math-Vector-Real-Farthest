package Math::Vector::Real::Farthest;

our $VERSION = '0.01';

use strict;
use warnings;

use Math::Vector::Real;
use Sort::Key::Top qw(nkeypartref);

use constant _c0 => 0;
use constant _c1 => 1;
use constant _n  => 2;
use constant _vs => 3;
use constant _s0 => 4;
use constant _s1 => 5;

use constant _threshold => 5;

sub find {
    my $class = shift;
    return unless @_;
    my $best_d2 = 0;
    my $O = 1;
    my ($best_v0, $best_v1);
    my ($c0, $c1) = Math::Vector::Real->box(@_);
    my $max_comp = ($c1 - $c0)->max_component;
    $best_d2 = 0; # 0.99999 * $max_comp * $max_comp;
    if (my $d2 = Math::Vector::Real::dist2($c0, $c1)) {
        my $s = [$c0, $c1, scalar(@_), [@_]];
        my @a = $s;
        my @b = $s;
        my @d2 = $d2;
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

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Math::Vector::Real::Farthest - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Math::Vector::Real::Farthest;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Math::Vector::Real::Farthest, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Salvador Fandiño, E<lt>salva@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
