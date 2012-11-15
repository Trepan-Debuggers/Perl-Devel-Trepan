#!/usr/bin/env perl
use strict; use warnings;
use English qw( -no_match_vars );
use rlib '../lib';
use Devel::Trepan::Condition;
use Config;

use Test::More;
if ($OSNAME eq 'MSWin32') {
    plan skip_all => "Strawberry Perl doesn't handle exec and conditions" 
} else {
    plan;
}

note( "Testing Condition" );

note 'Test valid conditions';
for my $expr ('$a=2', "join(', ', \@ARGV)", 'join(", ", \@ARGV)') {
    is (is_valid_condition($expr), 1, "\"$expr\" is valid Perl");
}
note 'Test invalid conditions';
for my $expr ('1+', "join(', ', \@ARGV", 'join(", , \@ARGV)') {
    is (is_valid_condition($expr), '', "\"$expr\" is not valid Perl");
}
done_testing;
