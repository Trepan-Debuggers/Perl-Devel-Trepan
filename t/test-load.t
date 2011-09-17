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

my @c = $cmdproc->complete("help un", 'help un', 0, 6);
is(scalar @c, 1);
is($c[0], 'unalias');
@c = $cmdproc->complete("set base", 'set base', 0, 8);
is(scalar @c, 1);
is($c[0], 'basename');

# @c = $cmdproc->complete("set basename ", 'set basename ', 0, 14);
# printf "complete('set basename ') => %s\n", join(', ', @c);

# FIXME: After we get string array I/O working and hooked
# up ...
# $cmdproc->run_cmd('foo');  # Invalid - not an Array
# $cmdproc->run_cmd([]);     # Invalid - empty Array
# $cmdproc->run_cmd(['help', '*']);
done_testing();
