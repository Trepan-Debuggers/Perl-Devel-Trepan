#!/usr/bin/env perl 
# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
use vars qw($TREPAN_CMDPROC);
use rlib '..';

package Devel::Trepan;
use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use version; $VERSION = '0.1.9';
use Exporter;

use Devel::Trepan::Core;

use constant PROGRAM => 'trepan.pl';

sub show_version {
    PROGRAM . ", version $Devel::Trepan::VERSION";
}

if (__FILE__ eq $0 ) {
    print show_version(), "\n";
}

1;
