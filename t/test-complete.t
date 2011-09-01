#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::Complete" );

BEGIN {
use_ok( 'Devel::Trepan::Complete' );
}

import Devel::Trepan::Complete;

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
}
