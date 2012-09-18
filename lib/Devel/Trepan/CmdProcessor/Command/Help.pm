# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
# -*- coding: utf-8 -*-

use rlib '../../../..';

package Devel::Trepan::CmdProcessor::Command::Help;
use warnings; no warnings 'redefine';

use Devel::Trepan::Pod2Text qw(pod2string help2podstring);
use Devel::Trepan::Complete qw(complete_token);

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;
use strict;

use vars qw(@ISA);
unless (@ISA) {
    eval <<'EOE';
use constant ALIASES    => ('?', 'h');
use constant CATEGORY   => 'support';
use constant SHORT_HELP => 'Print commands or give help for command(s)';
use constant MIN_ARGS   => 0;  # Need at least this many
use constant MAX_ARGS   => undef; # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;
EOE
}

@ISA = @CMD_ISA; 
use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
our $HELP = <<'HELP';
=pod 

help [I<command> [I<subcommand>]|I<expression>]

Without argument, print the list of available debugger commands.

When an argument is given, it is first checked to see if it is command
name. C<help backtrace> gives help on the C<backtrace> debugger command.

If the environment variable I<$PAGER> is defined, the file is
piped through that command.  You will notice this only for long help
output.

Some commands like C<info>, C<set>, and C<show> can accept an
additional subcommand to give help just about that particular
subcommand. For example C<help info line> gives help about the
C<info line> command.
=cut
HELP

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

use File::Basename;
use File::Spec;
my $ROOT_DIR = dirname(__FILE__);
my $HELP_DIR = File::Spec->catfile($ROOT_DIR, 'Help');

sub command_names($)
{
    my ($self) = @_;
    my $proc = $self->{proc};
    my %cmd_hash = %{$proc->{commands}};
    my @commands = keys %cmd_hash;
    if ($proc->{terminated}) {
        my @filtered_commands=();
        for my $cmd (@commands) {
            push @filtered_commands, $cmd unless $cmd_hash{$cmd}->NEED_STACK;
        }
        return @filtered_commands;
    } else {
        return @commands;
    }
}

sub complete($$)
{
    my ($self, $prefix) = @_;
    my $proc = $self->{proc};
    my @candidates = (keys %{CATEGORIES()}, qw(* all), 
                      $self->command_names());
    my @matches = complete_token(\@candidates, $prefix);
    # my @aliases = 
    #   Devel::Trepan::Complete::complete_token_filtered($proc->{aliases}, 
    #                                                    $prefix, \@matches);
    # sort (@matches, @aliases);
    sort @matches;
}

sub complete_syntax($$) {
    my ($self, $prefix) = @_;
    my @candidates = @{$self->syntax_files()};
    my @matches = complete_token(\@candidates, $prefix);
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
        } elsif ('syntax' eq $cmd) {
            my @syntax_files = @{$self->syntax_files()};
            push @result, [$cmd, 
                           sub { my $prefix = shift; 
                                 $self->complete_syntax($prefix) } ];
        } else {
            push @result, [$cmd, ['*'] ];
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
    my @pods = glob(File::Spec->catfile($HELP_DIR, "/*.pod"));
    my @result = map({ $_ = basename($_, '.pod') }  @pods);
    $self->{syntax_files} = \@result;
    return \@result;
}

sub show_command_syntax($$)
{
    my ($self, $args) = @_;
    if (scalar @$args == 2) {
        $self->{syntax_summary_help} ||= {};
        $self->section("List of syntax help");
        for my $name (@{$self->syntax_files()}) {
            unless($self->{syntax_summary_help}{$name}) {
                my $filename = File::Spec->catfile($HELP_DIR, "${name}.pod");
                my @lines = $self->readlines($filename);
                $self->{syntax_summary_help}{$name} = $lines[0];
            }
            my $msg = sprintf("  %-8s -- %s", $name, 
                              $self->{syntax_summary_help}{$name});
            $self->msg($msg, {unlimited => 1});
        }
    } else {
        my @args = splice(@{$args}, 2);
        for my $name (@args) {
            $self->{syntax_help} ||= {};
            my $filename = File::Spec->catfile($HELP_DIR, "${name}.pod");
            if ( -r $filename) {
                my $proc = $self->{proc};
                my $text = pod2string($filename, 
                                      $proc->{settings}{highlight},
                                      $proc->{settings}{maxwidth});
                $self->msg($text);
            } else {
                $self->errmsg("No syntax help for ${name}");
            }
        }
    }
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
            $self->section('All currently valid command names:');
            my @cmds = sort($self->command_names());
            $self->msg($self->columnize_commands(\@cmds));
            if (scalar keys %{$proc->{aliases}}) {
                $self->msg('');
                show_aliases($self) 
            }
            # $self->show_macros   unless scalar @$self->{proc}->macros;
        } elsif ($cmd_name =~ /^aliases$/i) {
            show_aliases($self);
        # } elsif (cmd_name =~ /^macros$/i) {
        #     $self->show_macros;
        } elsif ($cmd_name =~ /^syntax$/i) {
            show_command_syntax($self, $args);
        } elsif ($cmd_name =~ /^all$/i) {
            for my $category (sort keys %{CATEGORIES()}) {
                show_category($self, $category, []);
                $self->msg('');
            }
        } elsif (CATEGORIES->{$cmd_name}) {
            splice(@$args,0,2);
            show_category($self, $cmd_name, $args);
        } elsif ($proc->{commands}{$cmd_name}
                 || $proc->{aliases}{$cmd_name}) {
            if ($proc->{commands}{$cmd_name}) {
                $real_name = $cmd_name;
            } else {
                $real_name = $proc->{aliases}{$cmd_name};
            }
            my $cmd_obj = $proc->{commands}{$real_name};
            my $help_text = 
                $cmd_obj->can('help') ? $cmd_obj->help($args) 
                : $cmd_obj->{help};
            if ($help_text) {
                $help_text = help2podstring($help_text,
                                            $proc->{settings}{highlight},
                                            $proc->{settings}{maxwidth});
                chomp $help_text; chomp $help_text;
                $self->msg($help_text) ;
                if (scalar @{$cmd_obj->{aliases}} && scalar @$args == 2) {
                    $self->section("\n  Aliases:");
		    $self->msg($self->columnize_commands($cmd_obj->{aliases}));
                }
             }
        # } elsif ($self->{proc}{macros}{$cmd_name}) {
        #     $self->msg("${cmd_name} is a macro which expands to:");
        #     $self->msg("  ${@proc.macros[cmd_name]}", {:unlimited => true});
        } else {
            my @command_names = $self->command_names();
            my @matches = sort grep(/^${cmd_name}/, @command_names );
            if (!scalar @matches) {
                $self->errmsg("No commands found matching /^${cmd_name}/. Try \"help\".")
            } else {
                $self->section("Command names matching /^${cmd_name}/:");
                $self->msg($self->columnize_commands(sort \@matches));
            }
        }
    } else {
        list_categories($self);
    }
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
    print join(', ', $help_cmd->complete("sy")), "\n";
    $help_cmd->list_categories();
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
    $help_cmd->run([$NAME, 'syntax', 'command']);
    print $sep;
    $proc->{terminated} = 1;
    $help_cmd->run([$NAME, '*']);
    print $sep;
#   $help_cmd->run %W(${$NAME} s.*)
#   print $sep;
#   $help_cmd->run %W(${$NAME} s<>)
#   print $sep;
}

1;
