#!/usr/bin/env perl
=head1 C<10test-pod2text>

Some POD text to be able to test Devel::Trepan::Pod2Text

=cut

use strict; use warnings;
use Test::More;
use rlib '../lib';
use Devel::Trepan::Pod2Text;

my $string = Devel::Trepan::Pod2Text::pod2string(__FILE__);
my @array = split("\n", $string);
ok($string);
is(scalar @array, 2);
my $string2 = Devel::Trepan::Pod2Text::pod2string(__FILE__, 0, 30);
@array = split("\n", $string2);
ok($string2);
is(scalar @array, 3);

done_testing;
