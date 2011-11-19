#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::IO::TCPPack" );

BEGIN {
    use_ok( 'Devel::Trepan::IO::TCPPack' );
}

my $buf = "Hi there!";
my $msg;
($buf, $msg) = unpack_msg(pack_msg($buf));
is($msg, 'Hi there!');
is($buf, '');
done_testing();
