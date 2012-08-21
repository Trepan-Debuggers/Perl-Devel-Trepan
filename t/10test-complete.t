#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::Complete" );

BEGIN {
use_ok( 'Devel::Trepan::Complete' );
}

import Devel::Trepan::Complete;

note 'test next_token';
my $x = '  now is  the  time';
for my $pair ([ 0, ( 5, 'now')], 
	      [ 2, ( 5, 'now')], 
	      [ 5, ( 8, 'is')], 
	      [ 6, ( 8, 'is')],
	      [ 8, (13, 'the')],
	      [ 9, (13, 'the')],
	      [13, (19, 'time')],
	      [18, (19, 'e')],
	      [19, (1, '')]) { 
    my $pos = shift @$pair;
    my @expect = @$pair;
    my @ary = next_token($x, $pos);
    is($ary[0], $expect[0], "next_token($pos) position");
    is($ary[1], $expect[1], "next_token($pos) token");
}

note 'Test complete';
my $hash_ref = {'ab' => 1, 'aac' => 2, 'aa' => 3, 'a' => 4};
my @ary = keys %{$hash_ref};
my @data = (
    [[], 'b'], 
    [\@ary, 'a'], 
    [['aa', 'aac'], 'aa'], 
    [\@ary, ''], 
    [['ab'], 'ab'], 
    [[], 'abc']
    );
for my $tuple (@data) {
    my ($res_ary, $prefix) = @$tuple;
    my @got = complete_token(\@ary, $prefix);
    my @result = @$res_ary;
    is(@got, @result, "matching on $prefix");
}

for my $tuple (
    [\@ary, 'a'], 
    [['aa', 'aac'], 'aa'], 
    [['ab'], 'ab'], 
    [[], 'abc']
    ) {
    my ($result_keys, $prefix) = @$tuple;
    my @expect = map {[$_, $hash_ref->{$_}]} @$result_keys;
    my @result = complete_token_with_next($hash_ref, $prefix);
    is(@result, @expect, "matching ${prefix}");
    my @c = signal_complete('');
    cmp_ok(scalar @c, '>', '1', 'complete on empty string');
}
done_testing();
