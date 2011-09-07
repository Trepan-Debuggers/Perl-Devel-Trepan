#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More 'no_plan';
note( "Testing Devel::Trepan::Interface::Script" );

BEGIN {
use_ok( 'Devel::Trepan::Interface::Script' );
}

my $intf = Devel::Trepan::Interface::Script->new(__FILE__);
my $line = $intf->readline();
is($line, '#!/usr/bin/env perl');
