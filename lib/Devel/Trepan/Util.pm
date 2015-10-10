# -*- coding: utf-8 -*-
# Copyright (C) 2011, 2012, 2014 Rocky Bernstein <rocky@cpan.org>

package Devel::Trepan::Util;
use strict; use warnings; use English qw( -no_match_vars );

use vars qw(@EXPORT @ISA @YN);
@EXPORT    = qw( hash_merge safe_repr uniq_abbrev extract_expression
                 parse_eval_suffix parse_eval_sigil
                 YES NO YES_OR_NO @YN bool2YN);
@ISA = qw(Exporter);

use constant YES => qw(y yes oui si yep ja);
@YN = YES;
use constant NO => qw(n no non nope nein);
push(@YN, NO);

sub YN($)
{
    my $response = shift;
    !!grep(/^${response}$/i, @YN);
}

# Return 'Yes' for True and 'No' for False, and ?? for anything else
sub bool2YN($)
{
    my $bool = shift;
    $bool ? 'Yes' : 'No';
}

# Hash merge like Ruby has.
sub hash_merge($$) {
    my ($config, $default_opts) = @_;
    while (my ($field, $default_value) = each %$default_opts) {
        $config->{$field} = $default_value unless defined $config->{$field};
    };
    $config;
}

sub safe_repr($$;$)
{
    my ($str, $max, $elipsis) = @_;
    $elipsis = '... ' unless defined $elipsis;
    my $strlen = length($str);
    return '' unless $strlen;
    $str = '' unless $str or $str =~ /\d+/;
    if ($max > 0 && $strlen > $max && -1 == index($str, "\n")) {
        sprintf("%s%s%s", substr($str, 0, $max/2),
                $elipsis,  substr($str, $strlen+1-($max)/2));
    } else {
        $str;
    }
}

# name is String and list is an Array of String.
# If name is a unique leading prefix of one of the entries of list,
# then return that. Otherwise return name.
sub uniq_abbrev($$)
{
    my ($list, $name) = @_;
    my @candidates = ();
    for my $try_name (@$list) {
        push @candidates, $try_name if 0 == index($try_name, $name);
    }
    scalar @candidates == 1 ? $candidates[0] : $name;
}

# extract the "expression" part of a line of source code.
# Specifically
#   if (expression) -> expression
#   elsif (expression) -> expression
#   else (expression) -> expression
#   until (expression) -> expression
#   while (expression) -> expression
#   return (expression) -> expression
#   my (...) = (expression) -> (...) = (expression)
#   my ... = expression -> expression
#   ditto for "our" and "local", e.g.
#   local (...) = (expression) -> (...) = (expression
#   local ... = expression -> expression
#   $... = expression -> expression
sub extract_expression($)
{
    my $text = shift;
    if ($text =~ /^\s*(?:if|elsif|unless)\s*\(/) {
        $text =~ s/^\s*(?:if|elsif|unless)\s*\(//;
        $text =~ s/\s*\)\s*\{?\s*$//;
    } elsif ($text =~ /^\s*(?:until|while)\s*\(/) {
        $text =~ s/^\s*(?:until|while)\s*\(//;
        $text =~ s/\s*\)\{?\s*$//;
    } elsif ($text =~ /^\s*return\s+/) {
        # EXPRESSION in: return EXPRESSION
        $text =~ s/^\s*return\s+//;
        $text =~ s/;\s*$//;
    } elsif ($text =~ /^\s*(?:my|our|local)\s*(.+(\((?:.+)\s*\)\s*=.*);.*$)/) {
        # my (...) = ...;
        # Note: This has to appear before the below assignment
        $text =~ s/^\s*(?:my|our|local)\s*(\((?:.+)\)\s*=.*)[^;]*;.*$/$1/;
    } elsif ($text =~ /^\s*(?:my|our|local)\s+(?:.+)\s*=\s*(.+);.*$/) {
        # my ... = ...;
        $text = $1;
    # } elsif ($text =~ /^\s*case\s+/) {
    #     # EXPRESSION in: case EXPESSION
    #     $text =~ s/^\s*case\s*//;
    # } elsif ($text =~ /^\s*sub\s*.*\(.+\)/) {
    #     $text =~ s/^\s*sub\s*.*\((.*)\)/\(\1\)/;
    } elsif ($text =~ /^\s*\$[A-Za-z_][A-Za-z0-9_\[\]]*\s*=[^=>]/) {
        # RHS of an assignment statement.
        $text =~ s/^\s*[A-Za-z_][A-Za-z0-9_\[\]]*\s*=//;
    }
    return $text;
}

sub invalid_filename($)
{
    my $filename = shift;
    return "Command file '$filename' doesn't exist"   unless -f $filename;
    return "Command file '$filename' is not readable" unless -r $filename;
    return undef;
}

# Return 'undef' arg $cmd_str is ok. If not return the message a Perl -c
# gives, dropping off the "-e had complation errors" message.
sub invalid_perl_syntax($;$)
{
    my ($cmd_str, $have_e_opt) = @_;
    my $cmd = sprintf("$EXECUTABLE_NAME -c %s",
		      $have_e_opt ? $cmd_str : "-e '$cmd_str'");
    my $output = `$cmd 2>&1`;
    my $rc = $? >>8;
    return undef if 0 == $rc;
    # Drop off: -e had compilation errors.
    my @errmsg = split(/\n/, $output);
    pop @errmsg;
    return join("\n", @errmsg);
}

sub parse_eval_suffix($)
{
    my $cmd = shift;
    my $suffix = substr($cmd, -1);
    return ( index('%@$;>', $suffix) != -1) ? $suffix : '';
}

sub parse_eval_sigil($)
{
    my $cmd = shift;
    return ($cmd =~ /^\s*([%\$\@>;])/) ? $1 : ';';
}

# This routine makes sure $pager is set up so that '|' can use it.
sub pager()
{
    # If PAGER is defined in the environment, use it.
    if (defined $ENV{PAGER}) {
	$ENV{PAGER};
    } elsif (eval { require Config } && defined $Config::Config{pager} ) {
	# if Config.pm defines it.
	$Config::Config{pager};
    } else {
      # fall back to 'more'.
	'more'
    }
}


# Demo code
unless (caller) {
    my $default_config = {a => 1, b => 'c'};
    require Data::Dumper;
    import Data::Dumper;
    my $config = {};
    hash_merge $config, $default_config;
    print Dumper($config), "\n";

    for my $file (__FILE__, 'bogus') {
        my $result = invalid_filename($file);
        if (defined($result)) {
            print "$result\n";
        } else {
            print "$file exists\n";
        }
    }

    $config = {
        term_adjust   => 1,
        bogus         => 'yep'
    };
    print Dumper($config), "\n";
    hash_merge $config, $default_config;
    print Dumper($config), "\n";

    my $string = 'The time has come to talk of many things.';
    print safe_repr($string, 50), "\n";
    print safe_repr($string, 17), "\n";
    print safe_repr($string, 17, ''), "\n";

    my @list = qw(disassemble disable distance up);
    uniq_abbrev(\@list, 'disas');
    print join(' ', @list), "\n";
    for my $name (qw(dis disas u upper foo)) {
        printf("uniq_abbrev of %s is %s\n", $name,
               uniq_abbrev(\@list, $name));
    }
    # ------------------------------------
    # extract_expression
    for my $stmt (
        'if (condition("if"))',
        'if (condition("if")) {',
        'if(condition("if")){',
        'until (until_termination)',
        'until (until_termination){',
        'return return_value',
        'return return_value;',
        'nothing to be done',
        'my ($a,$b) = (5,6);',
        ) {
        print extract_expression($stmt), "\n";
    }

    for my $cmd (qw(eval eval$ eval% eval@ evaluate% none)) {
        print "parse_eval_suffix($cmd) => '". parse_eval_suffix($cmd) . "'\n";
    }

    for my $resp (qw(yes no Y NO nein nien huh?)) {
        printf "YN($resp) => '%s'\n", YN($resp);
    }
    for my $resp (1, 0, '', 'Foo', undef) {
        my $resp_str = defined $resp ? $resp : 'undef';
        printf "bool2YN($resp_str) => '%s'\n", bool2YN($resp);
    }

    for my $expr ('1+', '{cmd=5}') {
        print invalid_perl_syntax($expr), "\n";
    }
    for my $expr ('-e "$x="', '-e "(1,2"') {
        print invalid_perl_syntax($expr, 1), "\n";
    }

    $ENV{PAGER} = 'do-first';
    print pager(), "\n";
    delete $ENV{PAGER};
    print pager(), "\n";
}

1;
