#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More 'no_plan';
note( "Testing TrepanPosition" );

BEGIN {
use_ok( 'Devel::Trepan::Position' );
}

my $line = __LINE__;
my $pos1 = TrepanPosition->new(pkg=>__PACKAGE__, filename=>__FILE__, 
			       line => $line, event => 'brkpt');
my $pos2 = TrepanPosition->new(pkg=>__PACKAGE__,  filename=>__FILE__, 
			       line => $line, event => 'brkpt');
my $pos3 = TrepanPosition->new(pkg=>__PACKAGE__, filename=>__FILE__, 
			       line => __LINE__, event => 'brkpt');

note 'Test eq';
is (!!$pos1->eq($pos2), 1);
isnt ($pos1->eq($pos3), 1);
