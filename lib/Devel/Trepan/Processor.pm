# -*- coding: utf-8 -*-
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org> 

use rlib '../..';

# A debugger command processor. This includes the debugger commands
# and ties together the debugger core and I/O interface.
package Devel::Trepan::Processor;

use vars qw(@EXPORT @ISA);
@EXPORT    = qw( adjust_frame );

use English qw( -no_match_vars );
use Exporter;
use warnings; no warnings 'redefine';

eval "require Devel::Trepan::DB::Display";
use Devel::Trepan::Processor::Virtual;
use Devel::Trepan::CmdProcessor::Frame;
use strict;

1;
