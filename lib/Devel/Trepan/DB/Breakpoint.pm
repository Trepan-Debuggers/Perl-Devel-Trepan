# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 
# largely rewritten from perl5db.
package DB;
use strict; use warnings; no warnings 'redefine';
use English;

use Class::Struct;

use vars qw($brkpt $package $lineno);

struct DBBreak => {
    type        => '$', # 'tbrkpt', 'brkpt' or 'action'
    condition   => '$', # Condition to evaluate or '1' fo unconditional
                        # if type is 'action' this is the action to run
    num         => '$', # breakpoint/action number 
    count       => '$', # Number of time breakpoint/action hit
    enabled     => '$', # True if breakpoint or action is enabled
    negate      => '$', # break/step if ... or until .. ?
};

BEGIN {
    $DB::brkpt   = undef; # current breakpoint
}


sub line_events {
  my $s = shift;
  my $fname = shift;
  my(%ret) = ();
  my $i;
  $fname = $DB::filename unless $fname;
  local(*DB::dbline) = "::_<$fname";
  for ($i = 1; $i <= $#DB::dbline; $i++) {
    $ret{$i} = $DB::dbline[$i] if defined $DB::dbline{$i};
  }
  return %ret;
}

# Set a breakpoint, temporary breakpoint, or action.
sub set_break {
    my ($s, $i, $cond, $num, $type) = @_;
    $type //= 'break';
    $i ||= $DB::lineno;
    $cond ||= '1';
    $i = _find_subline($i) if ($i =~ /\D/);
    $s->warning("Subroutine not found.\n") unless $i;
    if ($i) {
	if (!defined($DB::dbline[$i]) || $DB::dbline[$i] == 0) {
	    my $suffix = $type eq 'action' ? 'actionable' : 'breakable';
	    $s->warning("Line $i not $suffix.\n");
	} else {
	    my $brkpt = DBBreak->new(
		type      => $type,
		condition => $cond,
		num       => $num,
		count     => 0,
		enabled   => 1
		);
	    my $ary_ref = $DB::dbline{$i} //= [];
	    push @$ary_ref, $brkpt;
	    my $prefix = $type eq 'tbrkpt' ? 
		'Temporary breakpoint' : 'Breakpoint' ;
	    $s->output("$prefix set in ${DB::filename} at line $i\n");
	}
    }
}

# Set a temporary breakpoint
sub set_tbreak {
    my ($s, $i, $cond, $num) = @_;
    set_break($s, $i, $cond, $num, 'tbrkpt');
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
    my ($s, $i, $cond, $num) = @_;
    set_break($s, $i, $cond, $num, 'action');
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

1;
