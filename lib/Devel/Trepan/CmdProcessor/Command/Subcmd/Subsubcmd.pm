# -*- coding: utf-8 -*-
# Copyright (C) 2011-2013 Rocky Bernstein <rocky@cpan.org>
# A base class for debugger subcommands.
#
use Exporter;
use warnings;
no warnings 'redefine';

use rlib '../../../../..';
use Devel::Trepan::CmdProcessor::Command::Subcmd::Core;

package Devel::Trepan::CmdProcessor::Command::Subsubcmd;
use Devel::Trepan::CmdProcessor::Validate;

BEGIN {
    @SUBCMD_VARS = qw($HELP $IN_LIST $RUN_CMD $MIN_ABBREV
                      $NAME $SHORT_HELP @SUBCMD_VARS
                      @SUBCMD_ISA);
}
use strict;

my $NotImplementedMessage =
    "This method must be overridden in a subsubclass";

use vars qw(@SUBCMD_VARS @EXPORT @ISA @SUBCMD_ISA);
use vars @SUBCMD_VARS;
@ISA = qw(Exporter);

@SUBCMD_ISA  = qw(Devel::Trepan::CmdProcessor::Command::Subsubcmd);
@EXPORT = @SUBCMD_VARS;

# attr_reader :name

$IN_LIST    = 1;  # Show item in help list of commands
$RUN_CMD    = 1;  # Run subcommand for those subcommands like "show"
                  # which append current settings to list output.
use constant MIN_ARGS => 0;
use constant MAX_ARGS => 0;
$MIN_ABBREV = 1;
use constant NEED_STACK => 0;
$NAME       = 'your_command_name';


# $cmd contains the command object that this
# command is invoked through.  A debugger field gives access to
# the stack frame and I/O.
sub new($$$)
{
    my ($class, $parent, $name) = @_;
    my $self = {parent => $parent};

    # Convenience class access. We don't expect that any of these
    # will change over the course of the program execution like
    # errmsg(), msg(), and msg_nocr() might. (See the note below
    # on these latter 3 methods.)
    #
    $self->{dbgr} = $parent->{dbgr};
    $self->{proc} = $parent->{proc};

    # FIXME: Inheritence of vars is not working the way I had hoped.
    # So this is a workaround.
    my $base_prefix="Devel::Trepan::CmdProcessor::Command::Subcmd::";
    for my $field (@SUBCMD_VARS) {
        my $sigil = substr($field, 0, 1);
        my $new_field = index('$@', $sigil) >= 0 ? substr($field, 1) : $field;
        if ($sigil eq '$') {
            $self->{lc $new_field} =
                eval "\$${class}::${new_field} || \$${base_prefix}${new_field}";
        } elsif ($sigil eq '@') {
            $self->{lc $new_field} = eval "[\@${class}::${new_field}]";
        } else {
            die "Woah - bad sigil: $sigil";
        }
    }
    # Done after above since $NAME is in @SUBCMD_VARS;
    $self->{name} = $name;
    $self->{short_help} ||= $self->{help};
    bless $self, $class;
    $self->set_name_prefix($class);
    $self;
}

# Convenience short-hand for @proc.confirm
sub confirm($$;$) {
    my ($self, $msg, $default) = @_;
    return($self->{proc}->confirm($msg, $default));
}

# Set a Boolean-valued debugger setting.
sub run_set_bool($$;$)
{
    my ($self, $args, $default) = @_;
    $default = 1 if scalar @_ < 3;
    my $onoff_arg = @$args < 4 ? 'on' : $args->[3];
    my $key = $self->{subcmd_setting_key};
    $self->{proc}{settings}{$key} = $self->{proc}->get_onoff($onoff_arg);
    $self->run_show_bool();
}

# set an Integer-valued debugger setting.
sub run_set_int($$$;$$)
{
    my ($self, $arg, $msg_on_error, $min_value, $max_value) = @_;
    my $proc = $self->{proc};
    if ($arg =~/^\s*$/) {
        $proc->errmsg('You need to supply a number.');
        return undef;
    }
    my $val = $proc->get_an_int($arg,
                                {max_value => $max_value,
                                 min_value => $min_value,
                                 msg_on_error => $msg_on_error
                                });
    if (defined ($val)) {
        my $subcmd_setting_key = $self->{subcmd_setting_key};
        $proc->{settings}{$subcmd_setting_key} = $val;
        $self->run_show_int();
    }
}

# Generic subcommand showing a boolean-valued debugger setting.
sub run_show_bool($;$)
{
    my ($self, $what) = @_;
    my $proc = $self->{proc};
    my $key = $self->{subcmd_setting_key};
    my $val = $self->show_onoff($proc->{settings}{$key});
    $what = $self->{cmd_str} unless $what;
    $proc->msg(sprintf "%s is %s.", $what, $val);
}

# Generic subcommand integer value display
sub run_show_int($;$)
{
    my ($self, $what) = @_;
    my $proc = $self->{proc};
    my $subcmd_setting_key = $self->{subcmd_setting_key};
    my $val = $proc->{settings}{$subcmd_setting_key};
    $what = $self->{cmd_str} unless ($what);
    $proc->msg(sprintf "%s is %d.", $what, $val);
}

# Generic subcommand value display. Pass in a hash which may
# which optionally contain:
#
#   :name - the String name of key in settings to use. If :value
#           (described below) is set, then setting :name does
#           nothing.
#
#   :what - the String name of what we are showing. If none is
#           given, then we use the part of the SHORT_HELP string.
#
#   :value - a String value associated with "what" above. If none
#            is given, then we pick up the value from settings.
#
sub run_show_val($;$)
{
    my ($self, $opts) = @_;
    $opts ||= {};
    my $what = exists $opts->{what}  ? $opts->{what}  : $self->{string_in_show};
    my $name = exists $opts->{name}  ? $opts->{name}  : $self->{name};
    my $val  = exists $opts->{value} ? $opts->{value} : $self->{settings}{$name};
    my $msg = sprintf("%s is %s.", $what, $val);
    $self->msg($msg);
}

# sub save_command_from_settings
#   ["${subcmd_prefix_string} ${settings[subcmd_setting_key]}"]
# }

sub subcmd_prefix_string($)
{
    my $self = shift;
    join(' ', $self->{prefix});
}

sub subcmd_setting_key($)
{
    my $self = shift;
    return $self->{subcmd_setting_key} if $self->{subcmd_setting_key};
    my @prefix = @{$self->{prefix}}; shift @prefix;
    $self->{subcmd_setting_key} = join('', @prefix);
}

# Return 'on' for true and 'off' for false, and ?? for anything else.
sub show_onoff($$)
{
    my ($self, $bool) = @_;
    if (!defined($bool)) {
        return 'unset';
    } elsif ($bool) {
        return 'on';
    } else {
        return 'off'
    }
}

sub set_name_prefix($$)
{
    my ($self, $class) = @_;
    my @prefix = split(/::/, $class);
    splice(@prefix, 0, 4); # Remove Devel::Trepan::CmdProcessor::Command
    @prefix = map {lc $_} @prefix;
    $self->{prefix}   = \@prefix;
    $self->{cmd_str} = join(' ', @prefix);
    $self->{subcmd_setting_key} = "$prefix[1]$prefix[2]";
}

sub string_in_show($)
{
    my ($self, $bool) = @_;
    my $skip_len = length('Show ');
    ucfirst substr($self->{short_help}, $skip_len);
}

sub summary_help($$)
{
    my ($self, $subcmd_name) = @_;
    my $msg = sprintf("%-12s: %s", $subcmd_name, $self->{short_help});
    $self->msg_nocr($msg);
}


package Devel::Trepan::CmdProcessor::Command::SetBoolSubsubcmd;
use vars qw(@ISA);
@ISA = qw(Exporter Devel::Trepan::CmdProcessor::Command::Subsubcmd);
#   completion %w(on off)

sub run($$) {
    my ($self, $args) = @_;
    $self->run_set_bool($args);
}

sub save_command($) {
    my ($self) = @_;
    my %settings = $self->{settings};
    my $val    = $settings{$self->subcmd_setting_key()} ? 'on' : 'off';
    [$self->subcmd_prefix_string . " ${val}"];
}

package Devel::Trepan::CmdProcessor::Command::ShowBoolSubsubcmd;
use vars qw(@ISA);
@ISA = qw(Exporter Devel::Trepan::CmdProcessor::Command::Subsubcmd);
sub run($)
{
    my ($self, $args) = @_;
    $self->run_show_bool($self->string_in_show());
}

package Devel::Trepan::CmdProcessor::Command::ShowIntSubsubcmd;
use vars qw(@ISA);
@ISA = qw(Exporter Devel::Trepan::CmdProcessor::Command::Subsubcmd);

sub run($) {
    my ($self, $args) = @_;
    my $doc = $self->{short_help};
    my $len = length($doc) - 5;
    $doc = ucfirst substr($doc, 5, $len);
    $self->run_show_int($doc);
}

unless (caller) {
    # Demo it.
    # require Devel::Trepan::CmdProcessor::Mock;
    # my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    # my %cmds = %{$proc->{commands}};
    # print join(', ', keys %cmds), "\n";
    # my $subcmd =
    #   Devel::Trepan::CmdProcessor::Command::Subcmd->new($cmds{'quit'});
    # print join(', ', keys %{$subcmd->{settings}}), "\n";
    # print $subcmd->show_onoff($subcmd->{settings}{autoeval}), "\n";
    # $subcmd->run_set_int($proc, 'Just a test');
}

1;
