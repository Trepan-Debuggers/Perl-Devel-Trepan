# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
use warnings;  
# FIXME: Can't use strict;
use rlib '../..';
use Devel::Trepan::DB;
use Devel::Trepan::DB::LineCache;  # for remap_e_string_to_file();
use Devel::Trepan::CmdProcessor;
use Devel::Trepan::SigHandler;
use Devel::Trepan::WatchMgr;
use Devel::Trepan::IO::Output;
use Devel::Trepan::Interface::Script;
use Devel::Trepan::Interface::Server;
use Devel::Trepan::Util;

package Devel::Trepan::Core;
use vars qw(@ISA $dbgr);
@ISA = qw(DB);

sub add_startup_files($$;$) {
    my ($cmdproc, $startup_file, $nowarn) = @_;
    my $errmsg = Devel::Trepan::Util::invalid_filename($startup_file);
    if ($errmsg) {
        print STDERR "${errmsg}.\n" unless $nowarn;
    }  else {
        push @{$cmdproc->{cmd_queue}}, "source $startup_file";
    }
}

sub new {
    my $class = shift;
    my %ORIG_SIG = %SIG; # Makes a copy of %SIG;
    my $self = {
        watch  => Devel::Trepan::WatchMgr->new(), # List of watch expressions
        orig_sig => \%ORIG_SIG,
        caught_signal => 0,
        exec_strs     => [],
        need_e_remap  => 0
    };
    bless $self, $class;
    $self->awaken();
    $self->skippkg('Devel::Trepan::Core');
    $self->register();
    $self->ready();
    return $self;
}

# Called when debugger is ready for reading commands. Main
# entry point.
sub idle($$$) 
{
    my ($self, $event, $args) = @_;
    my $proc = $self->{proc};
    $event = 'terminated' if $DB::package eq 'Devel::Trepan::Terminated';
    if ($self->{need_e_remap} && $DB::filename eq '-e') {
        DB::LineCache::remap_dbline_to_file();
        $self->{need_e_remap} = 0;
    }

    $proc->process_commands($DB::caller, $event, $args);
    $self->{caught_signal} = 0;
}

# Called on catching a signal that SigHandler says
# we should enter the debugger for. That it there is 'stop'
# set on that signal.
sub signal_handler($$$)
{
    my ($self, $signame) = @_;
    $DB::running = 0;
    $DB::step    = 0;
    $DB::caller = [caller(1)];
    ($DB::package, $DB::filename, $DB::lineno, $DB::subroutine, $DB::hasargs,
     $DB::wantarray, $DB::evaltext, $DB::is_require, $DB::hints, $DB::bitmask,
     $DB::hinthash
    ) = @{$DB::caller};
    my $proc = $self->{proc};
    $self->{caught_signal} = 1;
    $DB::signal = 2;
}

sub output($) 
{
    my ($self, $msg) = @_;
    my $proc = $self->{proc};
    chomp($msg);
    $proc->msg($msg);
}

sub warning($) 
{
    my ($self, $msg) = @_;
    my $proc = $self->{proc};
    chomp($msg);
    $proc->errmsg($msg);
}

sub awaken($;$) {
    my ($self, $opts) = @_;
    no warnings 'once';
    # Process options
    if (!defined($opts) && $ENV{'TREPANPL_OPTS'}) {
        $opts = eval "$ENV{'TREPANPL_OPTS'}";
    }

    my $exec_strs_ary = $opts->{exec_strs};
    if (defined $exec_strs_ary && scalar @{$exec_strs_ary}) {
        $self->{exec_strs} = $opts->{exec_strs};
        $self->{need_e_remap} = 1;
    }

    $0 = $opts->{dollar_0} if $opts->{dollar_0};

    $DB::fall_off_on_end = 1 if $opts->{fall_off_end} || $opts->{traceprint};

    $SIG{__DIE__}  = \&DB::catch if $opts->{post_mortem};

    my %cmdproc_opts = ();
    for my $field 
	(qw(basename cmddir highlight readline traceprint)) {
        # print "field $field $opts->{$field}\n";
        $cmdproc_opts{$field} = $opts->{$field};
    }
    my $cmdproc;

    my $batch_filename = $opts->{testing};
    $batch_filename = $opts->{batchfile} unless defined $batch_filename;
    if (defined $batch_filename) {
        my $result = Devel::Trepan::Util::invalid_filename($batch_filename);
        if (defined $result) {
            print STDERR "$result\n" 
        } else {
            my $output  = Devel::Trepan::IO::Output->new;
            my $script_opts = 
                $opts->{testing} ? {abort_on_error => 0} : {};
            my $script_intf = 
                Devel::Trepan::Interface::Script->new($batch_filename, 
                                                      $output, 
                                                      $script_opts);
            $cmdproc = Devel::Trepan::CmdProcessor->new([$script_intf], 
                                                        $self, 
                                                        \%cmdproc_opts);
            $self->{proc} = $cmdproc;
            $main::TREPAN_CMDPROC = $self->{proc};
        }
    } else {
        my $intf = undef;
        if (defined($dbgr) && exists($dbgr->{proc})) {
            $intf = $dbgr->{proc}{interfaces};
            $intf->[-1]{input}{term_readline} = $opts->{readline} if 
                exists($opts->{readline});
        }
        if ($opts->{server}) {
            my $server_opts = {
                host   => $opts->{host},
                port   => $opts->{port},
                logger => *STDOUT
            };
            $intf = [
                Devel::Trepan::Interface::Server->new(undef, undef,
                                                      $server_opts)
                ];
        }
        $cmdproc = Devel::Trepan::CmdProcessor->new($intf, $self, 
                                                    \%cmdproc_opts);
        $self->{proc} = $cmdproc;
        $main::TREPAN_CMDPROC = $self->{proc};
        $opts = {} unless defined $opts;

        for my $startup_file (@{$opts->{cmdfiles}}) {
            add_startup_files($cmdproc, $startup_file);
        }
        if (!$opts->{nx} && exists $opts->{initfile}) {
            add_startup_files($cmdproc, $opts->{initfile}, 1);
        }
    }
    $cmdproc->{skip_count} = -1 if $opts->{traceprint};
    $self->{sigmgr} = 
        Devel::Trepan::SigMgr->new(sub{ $DB::running = 0; $DB::single = 0;
                                        $self->signal_handler(@_) },
                                   sub {$cmdproc->msg(@_)},
                                   sub {$cmdproc->errmsg(@_)},
                                   sub {$cmdproc->section(@_)});
}

sub display_lists ($)
{
    my $self = shift;
    return $self->{proc}{displays}{list};
}

END { 
    $DB::ready = 0;
};

# FIXME: remove the next line and make this really OO.
$dbgr = __PACKAGE__->new();

1;
