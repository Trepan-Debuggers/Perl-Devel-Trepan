# Copyright (C) 2011-2012 Rocky Bernstein <rocky@cpan.org>
# I/O related command processor methods

use warnings;
no warnings 'redefine';
use strict;
use Exporter;


use rlib '../../..';
require Devel::Trepan::Util;
require Devel::Trepan::CmdProcessor;
package Devel::Trepan::CmdProcessor;

use vars qw(@EXPORT @ISA $HAVE_TERM_ANSIColor);
@ISA = qw(Exporter);

$HAVE_TERM_ANSIColor = eval "use Term::ANSIColor; 1";

# attr_accessor :ruby_highlighter

sub confirm($$$)
{
    my ($self, $msg, $default) = @_;
    my $intf = $self->{interfaces}[-1];
    my $confirmed = $self->{settings}{confirm} ? 
	$intf->confirm($msg, $default) : 1;
    $intf->remove_history unless $confirmed;
    $confirmed;
}

sub errmsg($$;$) {
    my($self, $message, $opts) = @_;
    $opts ||={};
    if (ref($message) eq 'ARRAY') {
	foreach my $mess (@$message) {
	    $self->errmsg($mess, $opts)
	}
	return;
    } else {
	$message = $self->safe_rep($message) unless $self->{opts}{unlimited};
    }
    if ($self->{settings}{highlight} && $HAVE_TERM_ANSIColor) {
	$message = color('underscore') . $message . color('reset');
    }
    $self->{interfaces}[-1]->errmsg($message);
}

sub msg($$;$) {
    my($self, $message, $opts) = @_;
    $message = $self->safe_rep($message) unless $opts->{unlimited};
    # $message = $self->perl_format($message) if $opts->{code};
    $self->{interfaces}[-1]->msg($message) if 
	defined $self->{interfaces}[-1];

  }

sub msg_need_running($$;$) {
    my($self, $prefix, $opts) = @_;
    $self->errmsg("$prefix not available when terminated");
}

sub msg_nocr($$;$) {
    my($self, $message, $opts) = @_;
    $message = $self->safe_rep($message) unless $self->{opts}{unlimited};
    # $message = $self->perl_format($message) if $self->{opts}{code};
    $self->{interfaces}[-1]->msg_nocr($message);

  }

sub read_command($) {
    my $self = shift;
    $self->{interfaces}[-1]->read_command($self->{prompt});
  }

  # sub perl_format($$) {
  #     my($self, $text);
  #     return $text unless $self->settings{highlight};
  #     unless @ruby_highlighter
  #       begin
  #         require 'coderay'
  #         require 'term/ansicolor'
  #         @ruby_highlighter = CodeRay::Duo[:ruby, :term]
  #       rescue LoadError
  #         return text
  #       }
  #     }
  #     return @ruby_highlighter.encode(text)
  # }

sub safe_rep($$) {
    my($self, $str) = @_;
    Devel::Trepan::Util::safe_repr($str, $self->{settings}{maxstring});
}

sub section($$;$) {
    my($self, $message, $opts) = @_;
    $opts ||= {};
    $message = $self->safe_rep($message) unless $self->{opts}{unlimited};
    if ($self->{settings}{highlight} && $HAVE_TERM_ANSIColor) {
	$message = color('bold') . $message . color('reset');
    }
    $self->{interfaces}[-1]->msg($message);
}

if (__FILE__ eq $0) {
    require Devel::Trepan::CmdProcessor;
    my $proc  = Devel::Trepan::CmdProcessor->new;
    if (scalar(@ARGV) > 0 && $proc->{interfaces}[-1]->is_interactive) {
	my $response = $proc->confirm("Are you sure?", 1);
	printf "You typed: %s\n", $response ? "Y" : "N";
    }
}

1;
