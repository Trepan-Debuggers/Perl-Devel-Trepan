# Copyright (C) 2012 Rocky Bernstein <rocky@cpan.org>
# I/O related BW processor methods

use warnings;
no warnings 'redefine';
use strict;
use Exporter;


use rlib '../../..';
require Devel::Trepan::Util;
require Devel::Trepan::BWProcessor;
package Devel::Trepan::BWProcessor;

use vars qw(@EXPORT @ISA);
@ISA = qw(Exporter);

# sub confirm($$$)
# {
#     my ($self, $msg, $default) = @_;
#     my $intf = $self->{interface};
#     my $confirmed = $self->{settings}{confirm} ? 
#         $intf->confirm($msg, $default) : 1;
#     $confirmed;
# }

sub errmsg($$;$) 
{
    my($self, $message, $opts) = @_;
    $opts ||={};
    my $err_ary = $self->{response}{errmsg} ||= [];
    $self->{response}{name} = 'error' if $opts->{set_name};
    push @$err_ary, $message;
}

sub flush_msg($) 
{
    my($self) = @_;
    $self->{interface}->msg($self->{response});
}

sub msg($$;$) 
{
    my($self, $message, $opts) = @_;
    $opts ||={};
    my $msg_ary = $self->{response}{msg} ||= [];
    push @$msg_ary, $message;
}

sub msg_need_running($$;$) {
    my($self, $prefix, $opts) = @_;
    $self->errmsg("$prefix not available when terminated");
}

sub section($$;$) {
    my($self, $message, $opts) = @_;
    $opts ||= {};
    # $message = $self->safe_rep($message) unless $self->{opts}{unlimited};
    $self->{interface}->msg($message);
}

if (caller) {
    require Devel::Trepan::BWProcessor;
    my $proc  = Devel::Trepan::BWProcessor->new;
    if (scalar(@ARGV) > 0 && $proc->{interface}->is_interactive) {
        my $response = $proc->confirm("Are you sure?", 1);
        printf "You typed: %s\n", $response ? "Y" : "N";
    }
}

1;
