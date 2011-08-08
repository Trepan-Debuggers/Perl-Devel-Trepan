#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Load" );

BEGIN {
use_ok( 'Devel::Trepan::CmdProcessor::Load' );
}

require Devel::Trepan::CmdProcessor;
my $cmdproc = Devel::Trepan::CmdProcessor->new;
my $count = scalar(keys %{$cmdproc->{commands}});
cmp_ok($count, '>', 0, 'commands populated');

# FIXME: After we get string array I/O working and hooked
# up ...
# $cmdproc->run_cmd('foo');  # Invalid - not an Array
# $cmdproc->run_cmd([]);     # Invalid - empty Array
# $cmdproc->run_cmd(['help', '*']);
done_testing();
