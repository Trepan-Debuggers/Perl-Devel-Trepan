#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More 'no_plan';
note( "Testing Condition" );

BEGIN {
use_ok( 'Devel::Trepan::Condition' );
}

note 'Test eq';
is (is_valid_condition('$a=1'), 1);
is (is_valid_condition('1+'), '');
