# -*- coding: utf-8 -*-
# Copyright (C) 2011-2014 Rocky Bernstein <rocky@cpan.org>
use Exporter;
use warnings;

use Carp ();
use File::Basename;

use rlib '../../..';
use if !defined Devel::Trepan::CmdProcessor, Devel::Trepan::CmdProcessor;
use strict;

package Devel::Trepan::CmdProcessor::Command;
no warnings 'redefine';
use Devel::Trepan::Util qw(hash_merge);

# Because we use Exporter we want to silence:
#   Use of inherited AUTOLOAD for non-method ... is deprecated
sub AUTOLOAD
{
    my $name = our $AUTOLOAD;
    $name =~ s/.*:://;  # lose package name
    my $target = "DynaLoader::$name";
    goto &$target;
}

sub DESTROY {}

use Array::Columnize;
sub declared ($) {
    use constant 1.01;              # don't omit this!
    my $name = shift;
    $name =~ s/^::/main::/;
    my $pkg = caller;
    my $full_name = $name =~ /::/ ? $name : "${pkg}::$name";
    $constant::declared{$full_name};
}

use vars qw(@CMD_VARS @EXPORT @ISA @CMD_ISA @ALIASES $HELP);
BEGIN {
    @CMD_VARS = qw($HELP $NAME $NEED_RUNNING $NEED_STACK @CMD_VARS);
}
use vars @CMD_VARS;
@ISA = qw(Exporter);

@CMD_ISA  = qw(Devel::Trepan::CmdProcessor::Command);
@EXPORT = qw(&set_name @CMD_ISA $NEED_RUNNING
             $NEED_STACK @CMD_VARS declared);


use constant NEED_STACK => 0; # We'll say that commands which need a stack
                              # to run have to declare that and those that
                              # don't don't have to mention it.
unless (@ISA) {
    eval <<'EOE';
use constant CATEGORY => 'Each command should set a category';
EOE
}

# use constant NEED_RUNNING = 0; # We'll say that commands which need a a currently
#                    # running program. It's possible we have a stack even though
#                    # the program isn't running, e.g. there was an exception.
#                    # and we've faked the stack. (If this is not so, we can
#                    # don't need this and can simple use $NEED_STACK.

$HELP       = 'Each command should set help text text';

sub set_name() {
    my ($pkg, $file, $line) = caller;
    lc(File::Basename::basename($file, '.pm'));
}

sub new($$) {
    my($class, $proc)  = @_;
    my $self = {
        proc     => $proc,
        class    => $class,
        dbgr     => $proc->{dbgr}
    };
    my $base_prefix="Devel::Trepan::CmdProcessor::Command::";
    for my $field (@CMD_VARS) {
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
    no warnings;
    my @ary = eval "${class}::ALIASES()";
    $self->{aliases} = @ary ? [@ary] : [];
    no strict 'refs';
    *{"${class}::Category"} = eval "sub { ${class}::CATEGORY() }";
    *{"${class}::name"} = eval "sub { \$${class}::NAME }";
    my $short_help = eval "${class}::SHORT_HELP()";
    $self->{short_help} = $short_help if $short_help;
    bless $self, $class;
    $self;
}

# List command names aligned in columns
sub columnize_commands($$$) {
    my ($self, $commands, $opts) = @_;
    my $width = $self->{settings}{maxwidth};
    $opts = {} unless $opts;
    $opts = hash_merge($opts,  {displaywidth => $width,
				colsep => '    ',
				ljust => 1,
				lineprefix => '  '});
    my $r = Array::Columnize::columnize($commands, $opts);
    chomp $r;
    return $r;
}

sub columnize_numbers($$) {
    my ($self, $commands) = @_;
    my $width = $self->settings->{maxwidth};
    my $r = Array::Columnize::columnize($commands,
                                        {displaywidth => $width,
                                         colsep => ', ',
                                         ljust => 0,
                                         lineprefix => '  '});
    chomp $r;
    return $r;
}

# FIXME: probably there is a way to do the delegation to proc methods
# without having type it all out.

sub confirm($$$) {
    my ($self, $message, $default) = @_;
    $self->{proc}->confirm($message, $default);
}

sub errmsg($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||= {};
    $self->{proc}->errmsg([$message], $opts);
}

# sub obj_const($$$) {
#     my ($self, $obj, $name) = @_;
#     $obj->class.const_get($name)
# }

# Convenience short-hand for $self->{proc}->msg
sub msg($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||= {};
    $self->{proc}->msg($message, $opts);
}

# Convenience short-hand for $self->{proc}->msg_nocr
sub msg_nocr($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||= {};
    $self->{proc}->msg_nocr($message, $opts);
}

# The method that implements the debugger command.
sub run {
    Carp::croak "RuntimeError: You need to define this method elsewhere";
}

sub section($$;$) {
    my ($self, $message, $opts) = @_;
    $opts ||={};
    $self->{proc}->section($message, $opts);
}

sub settings($) {
    my ($self) = @_;
    $self->{proc}{settings};
}

sub short_help($) {
    my ($self) = @_;
    return $self->{short_help} if defined $self->{short_help};
    my @ary = split("\n", $self->{help});
    $self->{short_help} = $ary[0];
}

unless (caller) {
    require Devel::Trepan::CmdProcessor::Mock;
    my $proc = Devel::Trepan::CmdProcessor::Mock::setup();
    my $cmd = Devel::Trepan::CmdProcessor::Command->new($proc);
    # print $cmd->short_help, "\n";
    # print $cmd, "\n";
    # print $cmd->Category, "\n";
    # print $cmd->{name}, "\n";
    # print $cmd->MIN_ARGS, "\n";
    # p cmd.complete('aa');
}

1;
