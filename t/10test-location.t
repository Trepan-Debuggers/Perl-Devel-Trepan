#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../lib';
use Test::More;

BEGIN {
use_ok( 'Devel::Trepan::CmdProcessor::Location' );
use_ok( 'Devel::Trepan::CmdProcessor' );
}

my $proc  = Devel::Trepan::CmdProcessor->new;

sub create_frame() {
    my ($pkg, $file, $line, $fn) = caller(0);
    return [
	{
	    file      => $file,
	    fn        => $fn,
	    line      => $line,
	    pkg       => $pkg,
	}];
}

my $frame_ary = create_frame();
$proc->frame_setup($frame_ary);
my $x = $proc->current_source_text({output=>'plain'});
is('my $frame_ary = create_frame();', $x);
done_testing();
