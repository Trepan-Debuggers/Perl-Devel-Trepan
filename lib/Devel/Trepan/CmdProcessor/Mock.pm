# -*- coding: utf-8 -*-
use strict;
use Exporter;
use warnings;

use lib '../../..';
use Devel::Trepan::CmdProcessor;
use Devel::Trepan::Interface::User;
use Devel::Trepan::Core;

package Devel::Trepan::CmdProcessor::Mock;
sub setup() {
    my $intf = Devel::Trepan::Interface::User->new;
    my $proc = Devel::Trepan::CmdProcessor->new([$intf], 'fixme');
    $proc;
}

if (__FILE__ eq $0) {
    my $proc=Devel::Trepan::CmdProcessor::Mock::setup;
    print $proc, "\n";
}

1;
