#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More 'no_plan';
note( "Testing Condition" );

BEGIN {
use_ok( 'Devel::Trepan::Condition' );
}

note 'Test valid conditions';
for my $expr ('$a=2', "join(', ', \@ARGV)", 'join(", ", \@ARGV)') {
    is (is_valid_condition($expr), 1, "\"$expr\" is valid Perl");
}
note 'Test invalid conditions';
for my $expr ('1+', "join(', ', \@ARGV", 'join(", , \@ARGV)') {
    is (is_valid_condition($expr), '', "\"$expr\" is not valid Perl");
}
