# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
use strict; use warnings;
package Devel::Trepan::Condition;
use English qw( -no_match_vars );
use vars qw(@EXPORT @ISA);
@EXPORT    = qw( is_valid_condition );
@ISA = qw(Exporter);

sub is_valid_condition($) {
    my ($expr) = @_;
    my $pid = fork();
    if ($pid) {
	waitpid($pid, 0);
	return $CHILD_ERROR == 0;
    } else {
	close STDERR;
	exec($EXECUTABLE_NAME, '-c', '-e', $expr);
    }
}

# Demo code
unless (caller) {
    for my $expr ('$a=2', '1+', "join(', ', @ARGV)", 'join(", ", @ARGV)') {
	my $ok = is_valid_condition($expr);
	printf("$expr is %sa valid_condition\n", $ok ? '' : 'not ');
    }
}

1;
