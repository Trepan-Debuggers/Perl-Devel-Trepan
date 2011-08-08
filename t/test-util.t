#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More tests => 4;
note( "Testing Devel::Trepan::Util" );

BEGIN {
use_ok( 'Devel::Trepan::Util' );
}

import Devel::Trepan::Util;
my $default_config = {a => 1, b => 'c', term_adjust=>0};
my $config = {};
hash_merge $config, $default_config;
is($config->{a}, $default_config->{a},
    "Should pick up default_config value");

$config = {
    term_adjust   => 1,
    bogus         => 'yep'
};
is($config->{term_adjust}, 1,
    "Should pick up supplied value over default");
is($config->{bogus}, 'yep',
    "Should pick up supplied value");
