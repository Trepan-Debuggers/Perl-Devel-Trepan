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

# [[ary, 'a'], [%w(aa aac), 'aa'], 
#  [['ab'], 'ab'], [[], 'abc']].each do |result_keys, prefix|
#     result = result_keys.map {|key| [key, hash[key]]}
# assert_equal(result, complete_token_with_next(hash, prefix),
# 	     "Trouble matching #{hash}.inspect on #{prefix.inspect}")
#     end



