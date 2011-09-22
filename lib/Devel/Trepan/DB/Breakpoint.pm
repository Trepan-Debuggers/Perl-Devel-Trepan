# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
# largely rewritten from perl5db.


use Class::Struct;

struct DBBreak => {
    type        => '$', # 'tbrkpt', 'brkpt' or 'action'
    condition   => '$', # Condition to evaluate or '1' fo unconditional
                        # if type is 'action' this is the action to run
    num         => '$', # breakpoint/action number 
    count       => '$', # Number of time breakpoint/action hit
    enabled     => '$', # True if breakpoint or action is enabled
    negate      => '$', # break/step if ... or until .. ?
    filename    => '$',
    line_num    => '$'
};

package DBBreak;
sub inspect($)
{
    my $self = shift;
    sprintf("file %s, line %s, type: %s, num %d, enabled: %d, negate %d, count: %s, cond: %s",
	    $self->filename, $self->line_num,
	    $self->type, $self->num, $self->enabled, $self->negate, 
	    $self->count, $self->condition);
};

package DB;
use vars qw($brkpt $package $lineno $max_bp $max_action);
use strict; use warnings; no warnings 'redefine';
use English;

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
    my ($s, $filename, $lineno, $cond, $num, $type, $enabled) = @_;
    $filename //= $DB::filename;
    $type //= 'break';
    $enabled //= 1;
    $lineno ||= $DB::lineno;
    $cond ||= '1';
    $lineno = _find_subline($lineno) if ($lineno =~ /\D/);
    $s->warning("Subroutine not found.\n") unless $lineno;
    if ($lineno) {
	if (!defined($DB::dbline[$lineno]) || $DB::dbline[$lineno] == 0) {
	    my $suffix = $type eq 'action' ? 'actionable' : 'breakable';
	    $s->warning("Line $lineno not $suffix.\n");
	} else {
	    unless (defined $num) {
		if ($type eq 'action') {
		    $num = ++$max_action;
		} else {
		    $num = ++$max_bp;
		}
	    }
	    my $brkpt = DBBreak->new(
		type      => $type,
		condition => $cond,
		num       => $num,
		count     => 0,
		enabled   => $enabled,
		filename  => $filename,
		line_num  => $lineno
		);
	    my $ary_ref = $DB::dbline{$lineno} //= [];
	    push @$ary_ref, $brkpt;
	    my $prefix = $type eq 'tbrkpt' ? 
		'Temporary breakpoint' : 'Breakpoint' ;
	    $s->output("$prefix $num set in ${DB::filename} at line $lineno\n");
	    return $brkpt
	}
    }
    return undef;
}

# Set a temporary breakpoint
sub set_tbreak {
    my ($s, $filename, $lineno, $cond, $num) = @_;
    set_break($s, $filename, $lineno, $cond, $num, 'tbrkpt');
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
	    if ($brkpt eq $bp) {
		undef $brkpts->[$j];
		last;
	    }
	    $count++;
	}
	delete $DB::dbline{$i} if $count == 0;
    }
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
    my ($s, $lineno, $filename, $cond, $num) = @_;
    set_break($s, $lineno, $filename, $cond, $num, 'action');
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
	type=>'action', condition=>'1', num=>1, count => 0, enbled => 1,
	negate => 0
	);
    print $brkpt->inspect, "\n";
}

1;
