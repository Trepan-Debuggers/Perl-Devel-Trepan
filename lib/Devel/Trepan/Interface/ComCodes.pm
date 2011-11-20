# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rockyb@rubyforge.net>
use warnings; use strict;

# Communication status codes
package Devel::Trepan::Interface::ComCodes;

our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(PRINT COMMAND CONFIRM_TRUE CONFIRM_FALSE CONFIRM_REPLY QUIT PROMPT RESTART);

# Most of these go from debugged process to front-end
# client interface. COMMAND goes the other way.

use constant PRINT         => '.';
use constant COMMAND       => 'C';
use constant CONFIRM_TRUE  => 'Y';
use constant CONFIRM_FALSE => 'N';
use constant CONFIRM_REPLY => '?';
use constant QUIT          => 'q';
use constant PROMPT        => 'p';
use constant RESTART       => 'r';

1;
