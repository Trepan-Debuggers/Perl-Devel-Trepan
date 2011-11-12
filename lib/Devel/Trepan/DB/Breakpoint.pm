# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
# largely rewritten from perl5db.

use Class::Struct;
use strict;

struct DBBreak => {
    id          => '$', # breakpoint/action number 
    enabled     => '$', # True if breakpoint or action is enabled
    type        => '$', # 'tbrkpt', 'brkpt' or 'action'
    condition   => '$', # Condition to evaluate or '1' fo unconditional
                        # if type is 'action' this is the action to run
    hits        => '$', # Number of times the breakpoint/action hit
    negate      => '$', # break/step if ... or until .. ?
    filename    => '$',
    line_num    => '$'
};

package DBBreak;
use feature 'switch';
sub inspect($)
{
    my $self = shift;
    sprintf("id %d, file %s, line %s, type: %s, enabled: %d, negate %s, hits: %s, cond: %s",
	    $self->id, 
	    $self->filename, $self->line_num,
	    $self->type,
	    $self->enabled, 
	    $self->negate, 
	    $self->hits, $self->condition
	);
};

sub icon_char($)
{
    my $self = shift;
    given ($self->type) {
	when ('tbrkpt') { return 'T'; }
	when ('brkpt')  { return 'B'; }
	when ('action') { return 'A'; }
    }
}

package DB;
use vars qw($brkpt $package $lineno $max_bp $max_action);
use strict; use warnings; no warnings 'redefine';
use English qw( -no_match_vars );

BEGIN {
    $DB::brkpt   = undef; # current breakpoint
    $max_bp = $max_action = 0;
}


sub line_events {
  my $s = shift;
  my $fname = shift;
  my(%ret) = ();
  $fname = $DB::filename unless $fname;
  local(*DB::dbline) = "::_<$fname";
  for (my $i = 1; $i <= $#DB::dbline; $i++) {
    $ret{$i} = $DB::dbline[$i] if defined $DB::dbline{$i};
  }
  return %ret;
}

# Set a breakpoint, temporary breakpoint, or action.
sub set_break {
    my ($s, $filename, $fn_or_lineno, $cond, $id, $type, $enabled) = @_;
    $filename //= $DB::filename;
    $type //= 'brkpt';
    $enabled //= 1;
    $fn_or_lineno ||= $DB::lineno;
    $cond ||= '1';
    my $lineno = $fn_or_lineno;
    if ($fn_or_lineno =~ /\D/) {
	$lineno = _find_subline($fn_or_lineno) ;
	unless ($lineno) {
	    $s->warning("Subroutine $fn_or_lineno not found.\n");
	    return undef;
	}
    }
    if (!defined($DB::dbline[$lineno]) || $DB::dbline[$lineno] == 0) {
	my $suffix = $type eq 'action' ? 'actionable' : 'breakable';
	$s->warning("Line $lineno not $suffix.\n");
	return undef;
    }
    unless (defined $id) {
	if ($type eq 'action') {
	    $id = ++$max_action;
	} else {
	    $id = ++$max_bp;
	}
    }
    my $brkpt = DBBreak->new(
	type      => $type,
	condition => $cond,
	id        => $id,
	hits      => 0,
	enabled   => $enabled,
	filename  => $filename,
	line_num  => $lineno
	);
    my $ary_ref = $DB::dbline{$lineno} //= [];
    push @$ary_ref, $brkpt;
    return $brkpt
}

# Set a temporary breakpoint
sub set_tbreak {
    my ($s, $filename, $lineno, $cond, $id) = @_;
    return set_break($s, $filename, $lineno, $cond, $id, 'tbrkpt');
}

sub delete_bp($$) {
    my ($s, $bp) = @_;
    my $i = $bp->line_num;
    local *dbline   = $main::{ '_<' . $bp->filename };
    if (defined $DB::dbline{$i}) {
	my $brkpts = $DB::dbline{$i};
	my $count = 0;
	my $break_count = scalar @$brkpts;
	for (my $j=0; $j <= $break_count; $j++) {
	    $brkpt = $brkpts->[$j];
	    next unless defined $brkpt;
	    if ($brkpt eq $bp) {
		undef $brkpts->[$j];
		last;
	    }
	    $count++;
	}
	delete $DB::dbline{$i} if $count == 0;
    }
}

# Find a subroutine. Return ($filename, $fn_name, $start_line);
# If not found, return (undef, undef, undef);
sub find_subline {
    my $fn_name = shift;
    $fn_name =~ s/\'/::/;
    $fn_name = "${DB::package}\:\:" . $fn_name if $fn_name !~ /::/;
    $fn_name = "main" . $fn_name if substr($fn_name,0,2) eq "::";
    my $filename = $DB::filename;
    if (exists $DB::sub{$fn_name}) {
	my($filename, $from, $to) = ($DB::sub{$fn_name} =~ /^(.*):(\d+)-(\d+)$/);
	if ($from) {
	    local *DB::dbline = "::_<$filename";
	    ++$from while $DB::dbline[$from] == 0 && $from < $to;
	    return ($filename, $fn_name, $from);
	}
    }
    return (undef, undef, undef);
}

# Find a subroutine line. 
# FIXME: reorganize things to really set a breakpoint at a subroutine.
# not just the line number we that we might find subroutine on.
sub _find_subline {
    my $name = shift;
    $name =~ s/\'/::/;
    $name = "${DB::package}\:\:" . $name if $name !~ /::/;
    $name = "main" . $name if substr($name,0,2) eq "::";
    if (exists $DB::sub{$name}) {
	my($fname, $from, $to) = ($DB::sub{$name} =~ /^(.*):(\d+)-(\d+)$/);
	if ($from) {
	    local *DB::dbline = "::_<$fname";
	    ++$from while $DB::dbline[$from] == 0 && $from < $to;
	    return $from;
	}
    }
    return undef;
}

sub clr_breaks {
    my $s = shift;
    my $i;
    if (@_) {
	while (@_) {
	    $i = shift;
	    $i = _find_subline($i) if ($i =~ /\D/);
	    $s->output("Subroutine not found.\n") unless $i;
	    if (defined $DB::dbline{$i}) {
		my $brkpts = $DB::dbline{$i};
		my $j = 0;
		for my $brkpt (@$brkpts) {
		    if ($brkpt->action ne 'brkpt') {
			$j++;
			next;
		    }
		    undef $brkpts->[$j];
		}
		delete $DB::dbline{$i} if $j == 0;
	    }
	}
    } else {
	for ($i = 1; $i <= $#DB::dbline ; $i++) {
	    if (defined $DB::dbline{$i}) {
		clr_breaks($s, $i);
	    }
	}
    }
}

# Set a an action
sub set_action {
    my ($s, $lineno, $filename, $action, $id) = @_;
    return set_break($s, $filename, $lineno, $action, $id, 'action');
}

# FIXME: combine with clear_breaks
sub clr_actions {
    my $s = shift;
    my $i;
    if (@_) {
	while (@_) {
	    $i = shift;
	    $i = _find_subline($i) if ($i =~ /\D/);
	    $s->output("Subroutine not found.\n") unless $i;
	    if (defined $DB::dbline{$i}) {
		my $brkpts = $DB::dbline{$i};
		my $j = 0;
		for my $brkpt (@$brkpts) {
		    if ($brkpt->action ne 'action') {
			$j++;
			next;
		    }
		    undef $brkpts->[$j];
		}
		delete $DB::dbline{$i} if $j == 0;
	    }
	}
    } else {
	for ($i = 1; $i <= $#DB::dbline ; $i++) {
	    if (defined $DB::dbline{$i}) {
		clr_breaks($s, $i);
	    }
	}
    }
}

# Demo it.
unless (caller) {
    my $brkpt = DBBreak->new(
	filename => __FILE__, line_num => __LINE__,
	type=>'action', condition=>'1', id=>1, hits => 0, enbled => 1,
	negate => 0
	);
    print $brkpt->inspect, "\n";
}

1;
