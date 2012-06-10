#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::WatchMgr" );

BEGIN {
use_ok( 'Devel::Trepan::WatchMgr' );
}

my $i = 0;
sub wp_status($$$) {
    $i = 0;
    my ($wp, $size, $max) = @_;
    is($wp->size, $size, "size step $i");
    is($wp->max, $max,  "max step $i");
    $i++;
}

my $watchpoints = Devel::Trepan::WatchMgr->new('bogus');

wp_status($watchpoints, 0, 0);
my $watchpoint1 = $watchpoints->add('1+2');
wp_status($watchpoints, 1, 1);
$watchpoints->add('3*4');
wp_status($watchpoints, 2, 2);

$watchpoints->delete_by_object($watchpoint1);
wp_status($watchpoints, 1, 2);

$watchpoints->add('3*4+5');
wp_status($watchpoints, 2, 3);

$watchpoints->delete(2);
wp_status($watchpoints, 1, 3);
done_testing();
