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
#     my $intf = $self->{interfaces}[-1];
#     my $confirmed = $self->{settings}{confirm} ? 
#         $intf->confirm($msg, $default) : 1;
#     $confirmed;
# }

sub errmsg($$;$) {
    my($self, $message, $opts) = @_;
    $opts ||={};
    $self->{interfaces}[-1]->errmsg($message);
}

sub msg($$;$) {
    my($self, $message, $opts) = @_;
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

sub section($$;$) {
    my($self, $message, $opts) = @_;
    $opts ||= {};
    $message = $self->safe_rep($message) unless $self->{opts}{unlimited};
    $self->{interfaces}[-1]->msg($message);
}

if (caller) {
    require Devel::Trepan::BWProcessor;
    my $proc  = Devel::Trepan::BWProcessor->new;
    if (scalar(@ARGV) > 0 && $proc->{interfaces}[-1]->is_interactive) {
        my $response = $proc->confirm("Are you sure?", 1);
        printf "You typed: %s\n", $response ? "Y" : "N";
    }
}

1;
