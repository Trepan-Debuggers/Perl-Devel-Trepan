#!/usr/bin/env perl 
use feature ":5.10";  
use vars qw($TREPAN_CMDPROC);
use rlib '..';

package Devel::Trepan;
use strict;
use warnings;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION);
use version; $VERSION = '0.1.1';
use Exporter;

use Devel::Trepan::Core;

use constant PROGRAM => 'trepanpl';

sub show_version {
    PROGRAM . ", version $Devel::Trepan::VERSION";
}

if (__FILE__ eq $0 ) {
    print show_version(), "\n";
}

1;
