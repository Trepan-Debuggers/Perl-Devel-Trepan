use Exporter;
use lib '../..';
require Devel::Trepan::Interface::User;
require Devel::Trepan::CmdProcessor::Virtual;
require Devel::Trepan::CmdProcessor::Default;
require Devel::Trepan::CmdProcessor::Msg;
require Devel::Trepan::CmdProcessor::Help;
require Devel::Trepan::CmdProcessor::Frame;
require Devel::Trepan::CmdProcessor::Location;
require Devel::Trepan::CmdProcessor::Load unless
    defined $Devel::Trepan::CmdProcessor::Load_seen;
require Devel::Trepan::CmdProcessor::Validate;
use strict;
use warnings;
no warnings 'redefine';

package Devel::Trepan::CmdProcessor;
use English;
use Devel::Trepan::Util qw(hash_merge);

use vars qw(@EXPORT @ISA $eval_result);
@ISA = qw(Exporter);

# sub sample_completion() {
#     my ($text, $line, $start, $end) = @_;
#     if (substr($line, 0, $start) =~ /^\s*$/) {
# 	return qw(a list of candidates);
# #	return $term->completion_matches($text,
# #					 $attribs->{'username_completion_function'});
#     } else {
# 	return ();
#     }
# }

sub new($;$$$) {
    my ($class, $interfaces, $dbgr, $settings) = @_;
    my $intf = Devel::Trepan::Interface::User->new;
    $interfaces ||= [$intf];
    my $self = Devel::Trepan::CmdProcessor::Virtual::new($class, $interfaces, $settings);
    $self->{dbgr}         = $dbgr;
    $self->{event}        = undef;
    $self->{cmd_queue}    = [];
    $self->{debug_nest}   = 1;
    $self->{last_command} = undef;
    $self->{leave_cmd_loop} = undef;
    $self->{settings} = hash_merge($settings, DEFAULT_SETTINGS());
    $self->load_cmds_initialize;
    if ($intf->has_completion) {
	my $completion = sub {
	    my ($text, $line, $start, $end) = @_;
	    $self->complete($text, $line, $start, $end);
	};
	$intf->set_completion($completion);
    }
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
	    '(' x $self->{debug_nest}, $thread_str, ')' x $self->{debug_nest});
}

sub finalize($)
{
    my $self = shift;
    # breakpoint_finalize
}

# Check that we meed the criteria that cmd specifies it needs
sub ok_for_running ($$$$) {
    my ($self, $cmd, $name, $nargs) = @_;
    # TODO check execution_set against execution status.
    # Check we have frame is not null
    my $min_args = exists $cmd->{min_args} ? $cmd->{min_args} : 0;
    if ($nargs < $min_args) {
	my $msg = 
	    sprintf("Command '%s' needs at least %d argument(s); " .
		    "got %d.", $name, $min_args, $nargs);
        $self->errmsg($msg);
	return;
    }
    my $max_args = exists $cmd->{mzx_args} ? $cmd->{max_args} : 10000;
    if ($max_args && $nargs > $max_args) {
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
		    $self->print_location;
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
    $self->run_command($self->{current_command});
    
    # Save it to the history.
    $intf->save_history($self->{last_command}) if 
	$self->{last_command};
}

# This is the main entry point.
sub process_commands($$$)
{
    my ($self, $frame, $is_eval, $event) = @_;
    if ($is_eval) {
	$DB::eval_result = '<undef>' unless defined $DB::eval_result;
	$self->msg("D => $DB::eval_result");
	$DB::eval_result = undef;
    } else {
	$self->frame_setup($frame);
	$self->{event} = $event;

	
	## $self->{unconditional_prehooks}->run;
	
	# if ('trace-var' eq @event ) {
	#     variable_name, value = @core.hook_arg;
	#     action = @traced_vars[variable_name];
	#     $self->msg "trace: #{variable_name} = #{value}";
	#     case action
	#     when nil
	#       $self->errmsg "no action recorded for variable. using 'stop'."
	#     when 'stop'
	#       msg "note: we are stopped *after* the above location."
	#     when 'nostop'
	#       print_location
	#       return;
	# 	else {
	# 	    $self->errmsg("internal error: unknown trace_var action ${action}");
	#     }
	#   }
	
	# my @last_pos;
	# if (breakpoint?) {
	#   @last_pos = (@frame_file, @frame_line,
	# 	  	    @stack_size, @current_thread, @event);
	# } else {
	#    return if stepping_skip? || @stack_size <= @hide_level;
	#}
	
	$self->{prompt} = $self->compute_prompt;
	
	$self->print_location unless $self->{settings}{traceprint};
	## $self->{eventbuf}->add_mark if $self->{settings}{tracebuffer};
	
	## $self->{cmdloop_prehooks}->run;
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
    ## $self->{cmdloop_posthooks}->run;
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

        # # Expand macros. FIXME: put in a procedure
        # while (1) {
	#     my $macro_cmd_name = $args[0];
	#     return if scalar(@args) == 0;
	#     last unless %$self->{macros}{$macro_cmd_name};
	#     $self->{current_command} = 
	# 	$self->{macros}{$macro_cmd_name}[0].call(*args[1..-1]);
	#     $self->msg($current_command) if $self->{settings}{debugmacro};
	#     if (current_command.is_a?(Array) && 
	# 	current_command.all? {|val| val.is_a?(String)}) {
	# 	@args = (first=current_command.shift).split;
	# 	@cmd_queue += current_command;
	# 	current_command = first;
	#     } elsif (current_command.is_a?(String)) {
	# 	@args = current_command.split;
	#     } else {
	# 	$self->errmsg("macro #{macro_cmd_name} should return an Array " .
	# 		      "of Strings or a String. Got #{current_command.inspect}");
	# 	return;
	#     }
        # }

	my %commands = %{$self->{commands}};
        $cmd_name = $self->{cmd_name} = $args[0];
        my $run_cmd_name = $cmd_name;

	my %aliases = %{$self->{aliases}};
	$run_cmd_name = $aliases{$cmd_name} if exists $aliases{$cmd_name};
        
        # $run_cmd_name = uniq_abbrev(keys %commands, $run_cmd_name) if
	#     !$command[$run_cmd_name] && $self->{settings}{abbrev};
          
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
	no warnings 'once';
	$DB::evalarg = $self->{dbgr}->evalcode($current_command);
	$self->{leave_cmd_loop} = 1;
	# $value = '<undef>' unless defined $value;
	# $self->msg("D => $value");
	return;
    }
    $self->undefined_command($cmd_name);
    return;
}

# Error message when a command doesn't exist
sub undefined_command($$) {
    my ($self, $cmd_name) = @_;
    my $msg = sprintf 'Undefined command: "%s". Try "help".', $cmd_name;
#      begin 
         $self->errmsg($msg);
#      rescue
#        print STDERR $msg;
#      }
}

if (__FILE__ eq $0) {
    my $proc  = Devel::Trepan::CmdProcessor->new;
    print $proc->{class}, "\n";
    print join(', ', @{$proc->{interfaces}}), "\n";
    $proc->msg("Hi, there!");
    $proc->errmsg(['Two', 'lines']);
    $proc->errmsg("Something wrong?");
    for my $fn (qw(errmsg msg section)) { 
	$proc->$fn('testing');
    }
    my $prompt = $proc->{prompt} = $proc->compute_prompt;
    sub foo() {
	my @call_values = caller(0);
	return @call_values;
    }
    print "prompt setting: $prompt\n";
    my @call_values = foo();
    $proc->frame_setup(\@call_values, 0);
    my $sep = '=' x 40 . "\n";
    $proc->undefined_command("foo");
    print $sep;
    $proc->run_command("help *");
    print $sep;
    $proc->run_command("help help;; kill 100");
    # Note kill 100 is in queue - not run yet.
    if (scalar(@ARGV) > 0 && $proc->{interfaces}->[-1]->is_interactive) {
	$proc->process_command_and_quit; # Handle's queued command
	$proc->process_command_and_quit;
	print $sep;
	$proc->process_commands([@call_values], 0, 'debugger-call');
    }
}

1;
