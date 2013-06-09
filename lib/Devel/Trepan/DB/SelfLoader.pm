package SelfLoader;
use 5.008;
use strict;
use IO::Handle;
our $VERSION = "1.20";

# The following bit of eval-magic is necessary to make this work on
# perls < 5.009005.
use vars qw/$AttrList/;
BEGIN {
  if ($] > 5.009004) {
    eval <<'NEWERPERL';
use 5.009005; # due to new regexp features
# allow checking for valid ': attrlist' attachments
# see also AutoSplit
$AttrList = qr{
    \s* : \s*
    (?:
	# one attribute
	(?> # no backtrack
	    (?! \d) \w+
	    (?<nested> \( (?: [^()]++ | (?&nested)++ )*+ \) ) ?
	)
	(?: \s* : \s* | \s+ (?! :) )
    )*
}x;

NEWERPERL
  }
  else {
    eval <<'OLDERPERL';
# allow checking for valid ': attrlist' attachments
# (we use 'our' rather than 'my' here, due to the rather complex and buggy
# behaviour of lexicals with qr// and (??{$lex}) )
our $nested;
$nested = qr{ \( (?: (?> [^()]+ ) | (??{ $nested }) )* \) }x;
our $one_attr = qr{ (?> (?! \d) \w+ (?:$nested)? ) (?:\s*\:\s*|\s+(?!\:)) }x;
$AttrList = qr{ \s* : \s* (?: $one_attr )* }x;
OLDERPERL
  }
}
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(AUTOLOAD);
sub Version {$VERSION}
sub DEBUG () { 0 }

our %Cache;      # private cache for all SelfLoader's client packages

# in croak and carp, protect $@ from "require Carp;" RT #40216

sub croak { { local $@; require Carp; } goto &Carp::croak }
sub carp { { local $@; require Carp; } goto &Carp::carp }

AUTOLOAD {
    our $AUTOLOAD;
    print STDERR "SelfLoader::AUTOLOAD for $AUTOLOAD\n" if DEBUG;
    my $SL_code = $Cache{$AUTOLOAD};
    my $save = $@; # evals in both AUTOLOAD and _load_stubs can corrupt $@
    unless ($SL_code) {
        # Maybe this pack had stubs before __DATA__, and never initialized.
        # Or, this maybe an automatic DESTROY method call when none exists.
        $AUTOLOAD =~ m/^(.*)::/;
        SelfLoader->_load_stubs($1) unless exists $Cache{"${1}::<DATA"};
        $SL_code = $Cache{$AUTOLOAD};
        $SL_code = "sub $AUTOLOAD { }"
            if (!$SL_code and $AUTOLOAD =~ m/::DESTROY$/);
        croak "Undefined subroutine $AUTOLOAD" unless $SL_code;
    }
    print STDERR "SelfLoader::AUTOLOAD eval: $SL_code\n" if DEBUG;

    {
	no strict;
	eval $SL_code;
    }
    if ($@) {
        $@ =~ s/ at .*\n//;
        croak $@;
    }
    $@ = $save;
    defined(&$AUTOLOAD) || die "SelfLoader inconsistency error";
    goto &$AUTOLOAD
}

sub load_stubs { shift->_load_stubs((caller)[0]) }

sub _load_stubs {
    # $endlines is used by Devel::SelfStubber to capture lines after __END__
    my($self, $callpack, $endlines) = @_;
    no strict "refs";
    my $fh = \*{"${callpack}::DATA"};
    use strict;
    my $currpack = $callpack;
    my($line, $name, @lines, @stubs, $prototype);

    print STDERR "SelfLoader::load_stubs($callpack)\n" if DEBUG;
    croak("$callpack doesn't contain an __DATA__ token")
        unless defined fileno($fh);
    # Protect: fork() shares the file pointer between the parent and the kid
    if(sysseek($fh, tell($fh), 0)) {
      open my $nfh, '<&', $fh or croak "reopen: $!";# dup() the fd
      close $fh or die "close: $!";                 # autocloses, but be paranoid
      open $fh, '<&', $nfh or croak "reopen2: $!";  # dup() the fd "back"
      close $nfh or die "close after reopen: $!";   # autocloses, but be paranoid
      $fh->untaint;
    }
    $Cache{"${currpack}::<DATA"} = 1;   # indicate package is cached

    local($/) = "\n";
    while(defined($line = <$fh>) and $line !~ m/^__END__/) {
	if ($line =~ m/^\s*sub\s+([\w:]+)\s*((?:\([\\\$\@\%\&\*\;]*\))?(?:$AttrList)?)/) {
            push(@stubs,
		 $self->_add_to_cache($name, $currpack, \@lines, $prototype));
            $prototype = $2;
            @lines = ($line);
            if (index($1,'::') == -1) {         # simple sub name
                $name = "${currpack}::$1";
            } else {                            # sub name with package
                $name = $1;
                $name =~ m/^(.*)::/;
                if (defined(&{"${1}::AUTOLOAD"})) {
                    \&{"${1}::AUTOLOAD"} == \&SelfLoader::AUTOLOAD ||
                        die 'SelfLoader Error: attempt to specify Selfloading',
                            " sub $name in non-selfloading module $1";
                } else {
                    $self->export($1,'AUTOLOAD');
                }
            }
        } elsif ($line =~ m/^package\s+([\w:]+)/) { # A package declared
            push(@stubs,
		 $self->_add_to_cache($name, $currpack, \@lines, $prototype));
            $self->_package_defined($line);
            $name = '';
            @lines = ();
            $currpack = $1;
            $Cache{"${currpack}::<DATA"} = 1;   # indicate package is cached
            if (defined(&{"${1}::AUTOLOAD"})) {
                \&{"${1}::AUTOLOAD"} == \&SelfLoader::AUTOLOAD ||
                    die 'SelfLoader Error: attempt to specify Selfloading',
                        " package $currpack which already has AUTOLOAD";
            } else {
                $self->export($currpack,'AUTOLOAD');
            }
        } else {
            push(@lines,$line);
        }
    }
    if (defined($line) && $line =~ /^__END__/) { # __END__
        unless ($line =~ /^__END__\s*DATA/) {
            if ($endlines) {
                # Devel::SelfStubber would like us to capture the lines after
                # __END__ so it can write out the entire file
                @$endlines = <$fh>;
            }
            close($fh);
        }
    }
    push(@stubs,
	 $self->_add_to_cache($name, $currpack, \@lines, $prototype));
    no strict;
    eval join('', @stubs) if @stubs;
}


sub _add_to_cache {
    my($self, $funcname, $pack, $lines, $prototype) = @_;
    return () unless $funcname;
    carp("Redefining sub $funcname") if exists $Cache{$funcname};
    my $header = qq(\n\#line 1 "sub $funcname"\npackage $pack; );
    $Cache{$funcname} = join('', $header, @$lines);
    print STDERR "SelfLoader cached $funcname: $Cache{$funcname}" if DEBUG;
    # return stub to be eval'd
    defined($prototype) ? "sub $funcname $prototype;" : "sub $funcname;"
}

sub _package_defined {}

1;



__END__
=head1 DESCRIPTION

This is a debuggable replacement for the core module C<SelfLoader>.
See L<SelfLoader> for full details.

=head1 COPYRIGHT AND LICENSE

This package has been part of the perl core since the first release
of perl5. It has been released separately to CPAN so older installations
can benefit from bug fixes.

This package has the same copyright and license as the perl core:

             Copyright (C) 1993, 1994, 1995, 1996, 1997, 1998, 1999,
        2000, 2001, 2002, 2003, 2004, 2005, 2006 by Larry Wall and others

			    All rights reserved.

    This program is free software; you can redistribute it and/or modify
    it under the terms of either:

	a) the GNU General Public License as published by the Free
	Software Foundation; either version 1, or (at your option) any
	later version, or

	b) the "Artistic License" which comes with this Kit.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either
    the GNU General Public License or the Artistic License for more details.

    You should have received a copy of the Artistic License with this
    Kit, in the file named "Artistic".  If not, I'll be glad to provide one.

    You should also have received a copy of the GNU General Public License
    along with this program in the file named "Copying". If not, write to the
    Free Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston,
    MA 02110-1301, USA or visit their web page on the internet at
    http://www.gnu.org/copyleft/gpl.html.

    For those of you that choose to use the GNU General Public License,
    my interpretation of the GNU General Public License is that no Perl
    script falls under the terms of the GPL unless you explicitly put
    said script under the terms of the GPL yourself.  Furthermore, any
    object code linked with perl does not automatically fall under the
    terms of the GPL, provided such object code only adds definitions
    of subroutines and variables, and does not otherwise impair the
    resulting interpreter from executing any standard Perl script.  I
    consider linking in C subroutines in this manner to be the moral
    equivalent of defining subroutines in the Perl language itself.  You
    may sell such an object file as proprietary provided that you provide
    or offer to provide the Perl source, as specified by the GNU General
    Public License.  (This is merely an alternate way of specifying input
    to the program.)  You may also sell a binary produced by the dumping of
    a running Perl script that belongs to you, provided that you provide or
    offer to provide the Perl source as specified by the GPL.  (The
    fact that a Perl interpreter and your code are in the same binary file
    is, in this case, a form of mere aggregation.)  This is my interpretation
    of the GPL.  If you still have concerns or difficulties understanding
    my intent, feel free to contact me.  Of course, the Artistic License
    spells all this out for your protection, so you may prefer to use that.

=cut
