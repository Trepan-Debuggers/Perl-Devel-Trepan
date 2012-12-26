# -*- coding: utf-8 -*-
use strict; use warnings;
use Exporter;

use vars qw(@EXPORT @ISA); @ISA = ('Exporter'); 
@EXPORT = qw(create_frame);

use rlib '../../..';
use Devel::Trepan::CmdProcessor;
use Devel::Trepan::Interface::User;
use Devel::Trepan::Core;

package Devel::Trepan::CmdProcessor::Mock;
sub setup() {
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], 'fixme');
    $proc;
}

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


if (__FILE__ eq $0) {
    my $proc=Devel::Trepan::CmdProcessor::Mock::setup;
    print $proc, "\n";
}

1;
