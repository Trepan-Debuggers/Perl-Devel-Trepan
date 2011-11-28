# -*- coding: utf-8 -*-
# Copyright (C) 2011 Rocky Bernstein <rocky@cpan.org>
# Subsidiary routines used to "pack" and "unpack" TCP messages.
use strict; use warnings; no warnings 'redefine';

package Devel::Trepan::IO::TCPPack;
use POSIX qw(ceil log10);
use Exporter;
our (@ISA, @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(TCP_MAX_PACKET LOG_MAX_MSG pack_msg unpack_msg);

use constant TCP_MAX_PACKET => 8192;
use constant LOG_MAX_MSG => ceil(log10(TCP_MAX_PACKET));

sub pack_msg($)
{
    my $msg = shift;
    # A funny way of writing: '%04d'
    my $fmt = sprintf '%%0%dd' , LOG_MAX_MSG;
    return sprintf($fmt, length($msg)) . $msg;
}

sub unpack_msg($)
{
    my $buf = shift;
    my $strnum = substr($buf, 0, LOG_MAX_MSG);
    die "Protocol error" unless ($strnum =~ /^\d+$/);
    my $length  = int($strnum);
    my $data    = substr($buf, LOG_MAX_MSG, $length);
    $buf        = substr($buf, LOG_MAX_MSG + $length);
    return ($buf, $data);
}

# Demo
unless (caller) {
    my $buf = "Hi there!";
    my $msg;
    ($buf, $msg) = unpack_msg(pack_msg($buf));
    print "$msg\n";
}

1;
