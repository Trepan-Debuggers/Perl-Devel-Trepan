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

sub complete_it($)
{
    my $str = shift;
    my @c = $cmdproc->complete($str, $str, 0, length($str));
    return @c;
}
my @c = complete_it("help una");
is(scalar @c, 1, 'help "una"');
is($c[0], 'unalias');

@c = complete_it("set base");
is(scalar @c, 1);
is($c[0], 'basename');

@c = complete_it("help set diff");
is(scalar @c, 1);
is($c[0], 'different');

@c = complete_it("set basename ");
is(scalar @c, 2);
@c = sort @c;
is($c[0], 'off');
is($c[1], 'on');

@c = complete_it("set basename of");
is(scalar @c, 1);
is($c[0], 'off');

@c = complete_it("set basename off");
is(scalar @c, 0);

@c = complete_it("set basename on ");
is(scalar @c, 0);

@c = complete_it("set ");
cmp_ok(scalar @c, '>', 2, 'set commands populated');

# FIXME: After we get string array I/O working and hooked
# up ...
# $cmdproc->run_cmd('foo');  # Invalid - not an Array
# $cmdproc->run_cmd([]);     # Invalid - empty Array
# $cmdproc->run_cmd(['help', '*']);
done_testing();
