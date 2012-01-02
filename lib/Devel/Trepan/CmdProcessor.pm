# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org> 

use rlib '../..';

# A debugger command processor. This includes the debugger commands
# and ties together the debugger core and I/O interface.
package Devel::Trepan::CmdProcessor;

use English qw( -no_match_vars );
use Exporter;
use warnings; no warnings 'redefine';

use vars qw(@EXPORT @ISA $eval_result);

# Showing eval results can be done using either data dump package.
use if !defined @ISA, Data::Dumper; require Data::Dumper::Perltidy;

unless (defined @ISA) {
    require Devel::Trepan::CmdProcessor::Load;
    require Devel::Trepan::BrkptMgr;
    eval "require Devel::Trepan::DB::Display";
    require Devel::Trepan::Interface::User;
    require Devel::Trepan::CmdProcessor::Virtual;
    require Devel::Trepan::CmdProcessor::Default;
    require Devel::Trepan::CmdProcessor::Msg;
    require Devel::Trepan::CmdProcessor::Help;
    require Devel::Trepan::CmdProcessor::Hook;
    require Devel::Trepan::CmdProcessor::Frame;
    require Devel::Trepan::CmdProcessor::Location;
    require Devel::Trepan::CmdProcessor::Eval;
    require Devel::Trepan::CmdProcessor::Running;
    require Devel::Trepan::CmdProcessor::Validate;
}
use strict;

use Devel::Trepan::Util qw(hash_merge uniq_abbrev);

@ISA = qw(Exporter);

BEGIN {
    @DB::D = ();  # Place to save eval results;
}

sub new($;$$$) {
    my ($class, $interfaces, $dbgr, $settings) = @_;
    my $intf;
    if (defined $interfaces) {
	$intf = $interfaces->[0];
    } else {
	$intf = Devel::Trepan::Interface::User->new;
	$interfaces = [$intf];
    }
    my $self = Devel::Trepan::CmdProcessor::Virtual::new($class, $interfaces, $settings);
    $self->{actions}        = Devel::Trepan::BrkptMgr->new($dbgr);
    $self->{brkpts}         = Devel::Trepan::BrkptMgr->new($dbgr);
    $self->{displays}       = Devel::Trepan::DisplayMgr->new($dbgr);
    $self->{completions}    = [];
    $self->{dbgr}           = $dbgr;
    $self->{event}          = undef;
    $self->{cmd_queue}      = [];
    $self->{DB_running}     = $DB::running;
    $self->{DB_single}      = $DB::single;
    $self->{last_command}   = undef;
    $self->{leave_cmd_loop} = undef;
    $self->{settings}       = hash_merge($settings, DEFAULT_SETTINGS());

    # Initial watch point expr value used when a new watch point is set.
    # Set in 'watch' command, and reset here after we get the value back.
    $self->{set_wp}         = undef;

    $self->{step_count}     = 0;
    $self->load_cmds_initialize;
    $self->running_initialize;
    $self->hook_initialize;
    $self->{unconditional_prehooks}->insert_if_new(10, 
						   $self->{trace_hook}[0],
						   $self->{trace_hook}[1]
	) if $self->{settings}{traceprint};

    if ($intf->has_completion) {
	my $list_completion = sub {
	    my($text, $state) = @_;
	    $self->list_complete($text, $state);
	};
	my $completion = sub {
	    my ($text, $line, $start, $end) = @_;
	    $self->complete($text, $line, $start, $end);
	};
	$intf->set_completion($completion, $list_completion);
    }
    # $B::Data::Dumper::Deparse = 1;
    return $self;
}

sub compute_prompt($)
{
    my $self = shift;
    my $thread_str = '';
    # if (1 == Thread.list.size) {
    # 	$thread_str = '';
    # } elsif (Thread.current == Thread.main) {
    # 	$thread_str = '@main';
    # } else {
    # 	$thread_str = "@#{Thread.current.object_id}";
    # }
    sprintf("%s$self->{settings}{prompt}%s%s: ",
	    '(' x $DB::level, $thread_str, ')' x $DB::level);
}

sub DESTROY($)
{
    my $self = shift;
    # breakpoint_finalize
}

# Check that we meed the criteria that cmd specifies it needs
sub ok_for_running ($$$$) {
    my ($self, $cmd, $name, $nargs) = @_;
    # TODO check execution_set against execution status.
    # Check we have frame is not null
    my $min_args = eval { $cmd->MIN_ARGS } || 0;
    if ($nargs < $min_args) {
	my $msg = 
	    sprintf("Command '%s' needs at least %d argument(s); " .
		    "got %d.", $name, $min_args, $nargs);
        $self->errmsg($msg);
	return;
    }
    my $max_args = eval { $cmd->MAX_ARGS } || undef;
    if (defined($max_args) && $nargs > $max_args) {
	my $mess = 
	    sprintf("Command '%s' needs at most %d argument(s); " .
		    "got %d.", $name, $max_args, $nargs);
        $self->errmsg($mess);
	return;
    }
    # if (cmd.class.const_get(:NEED_RUNNING) && !...)
    #   $self->errmsg "Command '%s' requires a running program." % name
    #   return;
    # }

    if ($cmd->{need_stack} && !defined $self->{frame}) {
        $self->errmsg("Command '$name' requires a running stack frame.");
        return;
    }

    return 1;
}

# Run one debugger command. 1 is returned if we want to quit.
sub process_command_and_quit($) 
{
    my $self = shift;
    my $intf_ary = $self->{interfaces};
    my $intf = $intf_ary->[-1];
    my $intf_size = scalar @{$intf_ary};
    return 1 if !defined $intf || $intf->is_input_eof && $intf_size == 1;
    while ($intf_size > 1 || !$intf->is_input_eof) {
	# begin
	$self->{current_command} = '';
	my @cmd_queue = @{$self->{cmd_queue}};
	if (scalar(@cmd_queue) == 0) {
	    # Leave trailing blanks on for the "complete" command
	    $self->{current_command} = $self->read_command() || '';
	    if ($intf->is_input_eof) {
		if ($intf_size > 1) {
		    pop @$intf_ary;
		    $intf_size = scalar @$intf_ary;
		    $intf = $intf_ary->[-1];
		    $self->{last_command} = '';
		    # $self->print_location;
		} else {
		    ## FIXME: think of something better.
		    $self->run_command("quit!");
		    return 1;
		}
	    }
	    chomp $self->{current_command};
	} else {
	    $self->{current_command} = shift @cmd_queue;
	    $self->{cmd_queue} = \@cmd_queue;
	}
	if ('' eq $self->{current_command}) {
	    next unless $self->{last_command} && $intf->is_interactive;
	    $self->{current_command} = $self->{last_command};
	}
	# Skip comment lines
	next if substr($self->{current_command}, 0, 1) eq '#';
	last;
	# rescue IOError, Errno::EPIPE => e
        # }
    }
    
    eval {
	$self->run_command($self->{current_command});
    };
    if ($EVAL_ERROR) {
	$self->errmsg("internal error: $EVAL_ERROR")
    } else {
	# Save it to the history.
	$intf->save_history($self->{last_command}) if 
	    $self->{last_command};
    }
}

my $last_eval_value = 0;

sub process_after_eval($) {
    my ($self) = @_;
    my $val_str;
    my $prefix="\$DB::D[$last_eval_value] =";
    
    # Perltidy::Dumper uses Tidy which looks at @ARGV for filenames.
    # Having a non-empty @ARGV will cause Tidy to croak.
    local @ARGV=();
    
    my $fn = ($self->{settings}{evaldisplay} eq 'tidy') 
	    ? \&Data::Dumper::Perltidy::Dumper
	    : \&Data::Dumper::Dumper;
    my $return_type = $DB::eval_opts->{return_type};
    $return_type = '' unless defined $return_type;
    if ('$' eq $return_type) {
	    if (defined $DB::eval_result) {
		$DB::D[$last_eval_value++] = $DB::eval_result;
		$val_str = $fn->($DB::eval_result);
		chomp $val_str;
	    } else {
		$DB::eval_result = '<undef>' ;
	    }
	    $self->msg("$prefix $DB::eval_result");
    } elsif ('@' eq $return_type) {
	    if (defined @DB::eval_result) {
		$val_str = $fn->(\@DB::eval_result);
		chomp $val_str;
		@{$DB::D[$last_eval_value++]} = @DB::eval_result;
	    } else {
		$val_str = '<undef>'
	    }
	    $self->msg("$prefix\n\@\{$val_str}");
    } elsif ('%' eq $return_type) {
	    if (%DB::eval_result) {
		$DB::D[$last_eval_value++] = \%DB::eval_result;
		$val_str = $fn->(%DB::eval_result);
		chomp $val_str;
	    } else {
		$val_str = '<undef>'
	    }
	    $self->msg("$prefix\n\%{$val_str}");
    }  else {
	    if (defined $DB::eval_result) {
		$DB::D[$last_eval_value++] = $fn->($DB::eval_result);
		$val_str = $fn->($DB::eval_result);
		chomp $val_str;
	    } else {
		$val_str = '<undef>'
	    }
	    $self->msg("$prefix ${val_str}");
    }
    
    if (defined($self->{set_wp})) {
	    $self->{set_wp}->old_value($DB::eval_result);
	    $self->{set_wp} = undef;
    }
    
    $DB::eval_opts = {
	    return_type => '',
    };
    $DB::eval_result = undef;
    @DB::eval_result = undef;
}

# This is the main entry point.
sub process_commands($$$;$)
{
    my ($self, $frame, $event, $arg) = @_;
    $event = 'unknown' unless defined($event);
    if ($event eq 'after_eval' or $event eq 'after_nest') {
	process_after_eval($self);
	if ($event eq 'after_nest') {
	    $self->msg("Leaving nested debug level $DB::level");
	    $self->{prompt} = compute_prompt($self);
	    $self->frame_setup();
	    $self->print_location;
	}
    } else {
	$self->{completions} = [];
	$self->{event} = $event;
	$self->frame_setup();

	if ($event eq 'watch') {
	    my $msg = sprintf("Watchpoint %s: `%s' changed", 
			      $arg->id, $arg->expr);
	    $self->section($msg);
	    my $old_value = defined($arg->old_value) ? $arg->old_value 
		: 'undef';
	    $msg = sprintf("old value\t%s", $old_value);
	    $self->msg($msg);
	    my $new_value = defined($arg->current_val) ? $arg->current_val
		: 'undef';
	    $msg = sprintf("new value\t%s", $new_value);
	    $self->msg($msg);
	    $arg->old_value($arg->current_val);
	}

	$self->{unconditional_prehooks}->run;
	if (index($self->{event}, 'brkpt') < 0) {
	    if ($self->is_stepping_skip()) {
		# || $self->{stack_size} <= $self->{hide_level};
		$self->{dbgr}->step;
		return;
	    }
	    if ($self->{settings}{traceprint}) {
		$self->{dbgr}->step;
		return;
	    }
	}
	
	$self->{prompt} = compute_prompt($self);
	$self->print_location unless $self->{settings}{traceprint};
	## $self->{eventbuf}->add_mark if $self->{settings}{tracebuffer};
	
	$self->{cmdloop_prehooks}->run;
    }
    $self->{leave_cmd_loop} = 0;
    while (!$self->{leave_cmd_loop}) {
	# begin
	$self->process_command_and_quit;
	# rescue systemexit
	#  @dbgr.stop
	#  raise
	#rescue exception => exc
	# if we are inside the script interface $self->errmsg may fail.
	# begin
	#  $self->errmsg("internal debugger error: #{exc.inspect}")
	# rescue ioerror
	#  $stderr.puts "internal debugger error: #{exc.inspect}"
	# }
	# exception_dump(exc, @settings[:debugexcept], $!.backtrace)
	# }
    }
    $self->{cmdloop_posthooks}->run;
    $DB::single = $self->{DB_single};
    $DB::running = $self->{DB_running};
}

# run current_command, a string. @last_command is set after the
# command is run if it is a command.
sub run_command($$) 
{
    my ($self, $current_command) = @_;
    my $eval_command = undef;
    my $cmd_name = undef;
    if (substr($current_command, 0, 1) eq '!') {
	$eval_command = substr($current_command, 1);
    }
    my @cmd_queue = @{$self->{cmd_queue}};
    unless ($eval_command) {
        my @commands = split(';;', $current_command);
        if (scalar(@commands) > 1) {
	    $current_command = shift @commands;
	    $self->{cmd_queue} = \(@cmd_queue, @commands);
        }
    
        # Split on space trimming leading space. Note ' ' rather than say \s+
        # which splits on leading spaces among others.
        my @args = split(' ', $current_command);

        # Expand macros. FIXME: put in a procedure
        while (1) {
	    return if scalar(@args) == 0;
	    my $macro_cmd_name = $args[0];
	    last unless $self->{macros}{$macro_cmd_name};
	    pop @args;
	    my $macro_expanded = 
		$self->{macros}{$macro_cmd_name}[0]->(@args);
#	    $self->msg($macro_expanded) if $self->{settings}{debugmacro};
	    if (ref $macro_expanded eq 'ARRAY' #  && 
#		current_command.all? {|val| val.is_a?(String)}
		) {
		my @new_commands = @{$macro_expanded};
		push @cmd_queue, @new_commands;
		$current_command = shift @cmd_queue;
		@args = split(' ', $current_command);
	    } else {
		$current_command = $macro_expanded;
		@args = split(/\s+/, $current_command);
	    # } else {
	    # 	$self->errmsg("macro ${macro_cmd_name} should return a list " .
	    # 		      "of strings " .
	    # 		      # or a String
	    # 		      ". Got ${current_command.inspect}");
	    # 	return;
	    }
        }

	my %commands = %{$self->{commands}};
        $cmd_name = $self->{cmd_name} = $args[0];
        my $run_cmd_name = $cmd_name;

	my %aliases = %{$self->{aliases}};
	$run_cmd_name = $aliases{$cmd_name} if exists $aliases{$cmd_name};

        $run_cmd_name = uniq_abbrev([keys %commands], $run_cmd_name) if
	    !$commands{$run_cmd_name} && $self->{settings}{abbrev};
          
	if ($commands{$run_cmd_name}) {
	    my $cmd = $commands{$run_cmd_name};
	    if ($self->ok_for_running($cmd, $run_cmd_name, scalar(@args)-1)) {
		# Get part of string after command name
		my $cmd_argstr = substr($current_command, length($cmd_name));
		$self->{cmd_argstr} = $cmd_argstr;
		$cmd->run(\@args);
		$self->{last_command} = $current_command;
	    }
	    return;
        }
    }

    # Eval anything that's not a command or has been
    # requested to be eval'd
    if ($self->{settings}{autoeval} || $eval_command) {
	my $opts = {nest => 0, return_type => '$'};
	if ($current_command =~ /^\s*([%\$\@])/) {
	    $opts->{return_type} = $1;
	}

	# FIXME: 2 below is a magic fixup constant, also found in
	# DB::finish.  Remove it.
	if (0 == $self->{frame_index}) {
	    $self->eval($current_command, $opts, 2);
	} else {
	    my $return_type = $DB::eval_opts->{return_type} = 
		$opts->{return_type};
	    if ('$' eq $opts->{return_type}) {
		$DB::eval_result = $self->eval($current_command, $opts, 2);
	    } elsif ('@' eq $opts->{return_type}) {
		@DB::eval_result = $self->eval($current_command, $opts, 2);
	    } elsif ('%' eq $opts->{return_type}) {
		%DB::eval_result = $self->eval($current_command, $opts, 2);
	    } else {
		$DB::eval_result = $self->eval($current_command, $opts, 2);
	    }
	    process_after_eval($self);
	}
	return;
    }
    $self->undefined_command($cmd_name);
    return;
}

# Error message when a command doesn't exist
sub undefined_command($$) {
    my ($self, $cmd_name) = @_;
    my $msg = sprintf 'Undefined command: "%s". Try "help".', $cmd_name;
    eval { $self->errmsg($msg); };
    print STDERR $msg  if $EVAL_ERROR;
}

unless (caller) {
    my $proc  = Devel::Trepan::CmdProcessor->new;
    print $proc->{class}, "\n";
    print join(', ', @{$proc->{interfaces}}), "\n";
    $proc->msg("Hi, there!");
    $proc->errmsg(['Two', 'lines']);
    $proc->errmsg("Something wrong?");
    for my $fn (qw(errmsg msg section)) { 
	$proc->$fn('testing');
    }
    $DB::level = 1;
    my $prompt = $proc->{prompt} = compute_prompt($proc);
    eval <<'EOE';
    sub foo() {
	my @call_values = caller(0);
	return @call_values;
    }
EOE
    print "prompt setting: $prompt\n";
    $DB::level = 2;
    $prompt = $proc->{prompt} = compute_prompt($proc);
    print "prompt setting 2: $prompt\n";
    my @call_values = foo();
    ## $proc->frame_setup(\@call_values, 0);
    my $sep = '=' x 40 . "\n";
    $proc->undefined_command("foo");
    print $sep;
    $proc->run_command("help *");
    print $sep;
    $proc->run_command("help help;; kill 100");
    # Note kill 100 is in queue - not run yet.
    if (scalar(@ARGV) > 0 && $proc->{interfaces}[-1]->is_interactive) {
	$proc->process_command_and_quit; # Handle's queued command
	$proc->process_command_and_quit;
	print $sep;
	$proc->process_commands([@call_values], 0, 'debugger-call');
    }
}

1;
