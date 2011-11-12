#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';

use Test::More;
note( "Testing Devel::CmdProcessor::Command::Kill" );

BEGIN {
    use_ok( 'Devel::Trepan::CmdProcessor::Command::Kill' );
}

require Devel::Trepan::CmdProcessor;
my $cmdproc = Devel::Trepan::CmdProcessor->new;
my $count = scalar(keys %{$cmdproc->{commands}});
my $cmd = Devel::Trepan::CmdProcessor::Command::Kill->new($cmdproc);

sub complete_it($)
{
    my $str = shift;
    my @c = $cmd->complete($str, $str, 0, length($str));
    return @c;
}

my @c = complete_it("uncond");
    is(scalar @c, 1);
    is($c[0], 'unconditionally');

if (exists $SIG{'HUP'}) {
    my @c = complete_it("hu");
    is(scalar @c, 1);
    is($c[0], 'hup');
}
done_testing();
