# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict; use warnings;
package Devel::Trepan::Condition;
use English;
use vars qw(@EXPORT @ISA);
@EXPORT    = qw( is_valid_condition );
@ISA = qw(Exporter);

sub is_valid_condition($) {
    my ($expr) = @_;
    my $cmd = sprintf("$EXECUTABLE_NAME -c -e '%s' 2>&1", $expr);
    my $output = `$cmd`;
    return $CHILD_ERROR == 0;
}

# Demo code
unless (caller) {
    for my $expr ('$a=2', '1+') {
	printf("$expr is %sa valid_condition\n", 
	       is_valid_condition($expr) ? '' : 'not ');
    }
}

1;
