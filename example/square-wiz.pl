#!/usr/bin/env perl
use strict;
use warnings;

my $res;
use Variable::Magic qw(wizard cast);
 
my $wiz = wizard(
    set => sub { Devel::Trepan::debugger() },
    # set  => sub { Enbugger->stop; },
    # fetch => sub { Devel::Trepan::debugger },
 );


cast $res, $wiz;

unshift @INC, '../lib' ;
require Devel::Trepan;

# GCD. We assume positive numbers
sub square($) 
{ 
    my ($n) = @_;
    $res = 1;
    my $odd = 1;
    for (my $i=1; $i<$n; $i++) {
	$odd += 2;
	$res += $odd
    }
    return $res;
}

for my $i (2, 3, 4, 5) {
    printf "The square of %d is %d\n", $i, square($i);
}
