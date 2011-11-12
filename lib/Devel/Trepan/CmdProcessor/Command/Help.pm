# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Help;
use warnings; no warnings 'redefine';

use if !defined @ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA); @ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $MIN_ARGS = 0;
our $MAX_ARGS = 10000;
our $HELP = <<"HELP";
${NAME} [command [subcommand]|expression]

Without argument, print the list of available debugger commands.

When an argument is given, it is first checked to see if it is command
name. 'help where' gives help on the 'where' debugger command.

If the environment variable \$PAGER is defined, the file is
piped through that command.  You will notice this only for long help
output.

Some commands like 'info', 'set', and 'show' can accept an
additional subcommand to give help just about that particular
subcommand. For example 'help info line' gives help about the
info line command.
HELP

use constant ALIASES => ('?');

BEGIN {
    eval "use constant CATEGORIES => {
    'breakpoints' => 'Making the program stop at certain points',
    'data'        => 'Examining data',
    'files'       => 'Specifying and examining files',
    'running'     => 'Running the program', 
    'status'      => 'Status inquiries',
    'support'     => 'Support facilities',
    'stack'       => 'Examining the call stack',
    'syntax'      => 'Debugger command syntax'
    };" unless declared('CATEGORIES');
};

use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Print commands or give help for command(s)';
local $NEED_STACK    = 0;

use File::Basename;
use File::Spec;
my $ROOT_DIR = dirname(__FILE__);
my $HELP_DIR = File::Spec->catfile($ROOT_DIR, 'Help');

sub complete($$)
{
    my ($self, $prefix) = @_;
    my $proc = $self->{proc};
    my @candidates = (keys %{CATEGORIES()}, qw(* all), 
		      keys %{$proc->{commands}});
    my @matches = 
	Devel::Trepan::Complete::complete_token(\@candidates, $prefix);
    # my @aliases = 
    # 	Devel::Trepan::Complete::complete_token_filtered($proc->{aliases}, 
    # 							 $prefix, \@matches);
    # sort (@matches, @aliases);
    sort @matches;
}    

sub complete_token_with_next($$;$)
{
    my ($self, $prefix, $cmd_prefix) = @_;
    my $proc = $self->{proc};
    my @result = ();
    my @matches = $self->complete($prefix);
    foreach my $cmd (@matches) {
	my %commands = %{$proc->{commands}};
	if (exists $commands{$cmd}) {
	    push @result, [$cmd, $commands{$cmd}];
	    # if ('syntax' eq $cmd) {
	    # 	complete_method =  Syntax->new(syntax_files);
	    # } else {
	    # 	$proc->commands.member?(cmd) ? $proc->commands[cmd] : 0;
	    # }
	}
    }
    return @result;
}

# List the command categories and a short description of each.
sub list_categories($) {
    my $self = shift;
    $self->section('Help classes:');
    for my $cat (sort(keys %{CATEGORIES()})) {
	$self->msg(sprintf "%-13s -- %s", $cat, CATEGORIES->{$cat});
    }
    my $final_msg = '
Type "help" followed by a class name for a list of help items in that class.
Type "help aliases" for a list of current aliases.
Type "help macros" for a list of current macros.
Type "help *" for the list of all commands, macros and aliases.
Type "help all" for a brief description of all commands.
Type "help REGEXP" for the list of commands matching /^${REGEXP}/.
Type "help CLASS *" for the list of all commands in class CLASS.
Type "help" followed by a command name for full documentation.
';
    $self->msg($final_msg);
}

# This method runs the command
sub run($$) 
{
    my ($self, $args) = @_;
    my $proc = $self->{proc};
    my $cmd_name = $args->[1];
    if (scalar(@$args) > 1) {
	my $real_name;
	if ($cmd_name eq '*') {
	    $self->section('All command names:');
	    my @cmds = sort(keys(%{$proc->{commands}}));
	    $self->msg($self->columnize_commands(\@cmds));
	    $self->show_aliases if scalar keys %{$proc->{aliases}};
	    # $self->show_macros   unless scalar @$self->{proc}->macros;
	} elsif ($cmd_name =~ /^aliases$/i) {
	    $self->show_aliases();
	# } elsif (cmd_name =~ /^macros$/i) {
	#     $self->show_macros;
	} elsif ($cmd_name =~ /^syntax$/i) {
	    $self->show_command_syntax($args);
	} elsif ($cmd_name =~ /^all$/i) {
	    for my $category (sort keys %{CATEGORIES()}) {
		$self->show_category($category, []);
		$self->msg('');
	    }
        } elsif (CATEGORIES->{$cmd_name}) {
	    splice(@$args,0,2);
	    $self->show_category($cmd_name, $args);
	} elsif ($proc->{commands}{$cmd_name}
		 || $proc->{aliases}{$cmd_name}) {
	    if ($proc->{commands}{$cmd_name}) {
		$real_name = $cmd_name;
	    } else {
		$real_name = $proc->{aliases}{$cmd_name};
	    }
	    my $cmd_obj = $proc->{commands}{$real_name};
	    my $help_text = 
		$cmd_obj->can("help") ? $cmd_obj->help($args) 
		: $cmd_obj->{help};
	    if ($help_text) {
		$self->msg($help_text) ;
		if (scalar @{$cmd_obj->{aliases}} && scalar @$args == 2) {
		    my $aliases_str = join(', ', @{$cmd_obj->{aliases}});
		    $self->msg("Aliases: $aliases_str");
		}
	     }
        # } elsif ($self->{proc}{macros}{$cmd_name}) {
	#     $self->msg("${cmd_name} is a macro which expands to:");
	#     $self->msg("  ${@proc.macros[cmd_name]}", {:unlimited => true});
	} else {
	    my @matches = sort grep(/^${cmd_name}/, 
				    keys %{$self->{proc}{commands}} );
	    if (!scalar @matches) {
		$self->errmsg("No commands found matching /^${cmd_name}/. Try \"help\".")
	    } else {
		$self->section("Command names matching /^${cmd_name}/:");
		$self->msg($self->columnize_commands(sort \@matches));
            }
	}
    } else {
	$self->list_categories;
    }
}

sub show_aliases($)
{
    my $self = shift;
    $self->section('All alias names:');
    my @aliases = sort(keys(%{$self->{proc}{aliases}}));
    $self->msg($self->columnize_commands(\@aliases));
  }

# Show short help for all commands in `category'.
sub show_category($$$)
{
    my ($self, $category, $args) = @_;
    if (scalar @$args == 1 && $args->[0] eq '*') {
	$self->section("Commands in class $category:");
	my @commands = ();
	while (my ($key, $value) = each(%{$self->{proc}{commands}})) {
	    push(@commands, $key) if $value->Category eq $category;
	}
	$self->msg($self->columnize_commands([sort @commands]));
	return;
    }
    
    $self->section("Command class: ${category}");
    my %commands = %{$self->{proc}{commands}};
    for my $name (sort keys %commands) {
    	next if $category ne $commands{$name}->Category;
	my $short_help = defined $commands{$name}{short_help} ? 
	    $commands{$name}{short_help} : $commands{$name}->short_help;
    	my $msg = sprintf("%-13s -- %s", $name, $short_help);
	$self->msg($msg);
    }
}
  
sub syntax_files($)
{
    my $self = shift;
    return $self->{syntax_files} if $self->{syntax_files};
    my @result = map({ $_ = basename($_, '.txt') } 
		     glob(File::Spec->catfile($HELP_DIR, "/*.txt")));
    $self->{syntax_files} = @result;
    return @result;
}

sub readlines($$$) {
    my($self, $filename) = @_;
    unless (open(FH, $filename)) {
	$self->errmsg("Can't open $filename: $!");
	return ();
    }
    local $_;
    my @lines = ();
    while (<FH>) { chomp $_; push @lines, $_;  }
    close FH;
    return @lines;
}
  
sub show_command_syntax($$)
{
    my ($self, $args) = @_;
    if (scalar @$args == 2) {
	$self->{syntax_summary_help} ||= {};
	$self->section("List of syntax help");
	for my $name ($self->syntax_files()) {
	    unless($self->{syntax_summary_help}{$name}) {
		my $filename = File::Spec->catfile($HELP_DIR, "${name}.txt");
		my @lines = $self->readlines($filename);
		$self->{syntax_summary_help}{$name} = $lines[0];
	    }
	    my $msg = sprintf("  %-8s -- %s", $name, 
			      $self->{syntax_summary_help}{$name});
	    $self->msg($msg);
	}
    } else {
	my @args = splice(@{$args}, 2);
	for my $name (@args) {
	    $self->{syntax_help} ||= {};
	    unless ($self->{syntax_help}{name}) {
		my $filename = 
		    File::Spec->catfile($HELP_DIR, "${name}.txt");
		my @lines = $self->readlines($filename);
		shift @lines;
		$self->{syntax_help}{$name} = join("\n", @lines);
	    }
	    
	    if (exists $self->{syntax_help}{$name}) {
		$self->section("Debugger syntax for a ${name}:");
		$self->msg($self->{syntax_help}{$name});
	    } else {
		$self->errmsg("No syntax help for ${name}");
	    }
	}
    }
}

#   sub show_macros
#     section 'All macro names:'
#     msg columnize_commands(@proc.macros.keys.sort)
#   }

# }

# Demo it.
unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new;
    my $help_cmd = __PACKAGE__->new($proc);
    my $sep = '=' x 30 . "\n";
    print join(', ', $help_cmd->complete('br')), "\n";
    print join(', ', $help_cmd->complete('un')), "\n";
    $help_cmd->list_categories;
    print $sep;
    $help_cmd->run([$NAME, 'help']);
    print $sep;
    $help_cmd->run([$NAME, 'kill']);
    print $sep;
    $help_cmd->run([$NAME, '*']);
    print $sep;
    $help_cmd->run([$NAME]);
    print $sep;
    $help_cmd->run([$NAME, 'fdafsasfda']);
    print $sep;
    $help_cmd->run([$NAME, 'running', '*']);
    print $sep;
    $help_cmd->run([$NAME, 'syntax']);
    print $sep;
#   $help_cmd->run %W(${$NAME} s.*)
#   print $sep;
#   $help_cmd->run %W(${$NAME} s<>)
#   print $sep;
}

1;
