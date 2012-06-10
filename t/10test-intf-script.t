#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::Trepan::Interface::Script" );

BEGIN {
use_ok( 'Devel::Trepan::Interface::Script' );
}

my $intf = Devel::Trepan::Interface::Script->new(__FILE__);
my $line = $intf->readline();
is($line, '#!/usr/bin/env perl');
done_testing();
