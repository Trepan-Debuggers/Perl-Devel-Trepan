#!/usr/bin/env perl
# 
#   Copyright (C) 2011, 2012 Rocky Bernstein <rockyb@cpan.org>
#
#
use Digest::SHA;

use version; $VERSION = '0.1.1';

package DB;

# FIXME: Figure out where to put this
# *pod
# 
# I<eval_ok($code)> => I<boolean>
#
# Evaluate I<$code> and return true if there's no error.
# *cut
sub eval_ok ($) 
{
    my $code = shift;
    no strict; no warnings;
    $DB::namespace_package = 'package main' unless $DB::namespace_package;
    my $wrapped = "$DB::namespace_package; sub { $code }";
    eval $wrapped;
    # print $@, "\n" if $@;
    return !$@;
}

package DB::LineCache;

=pod

=head1 NAME DB::LineCache

DB::LineCache - package to read and cache lines of a Perl program. 

=head1 SYNOPSIS

The LineCache package allows one to get any line from any file,
caching lines of the file on first access to the file. Although the 
file may be any file, the common use is when the file is a Perl
script since parsing of the file is done to figure out where the
statement boundaries are.

The routines here may be is useful when a small random sets of lines
are read from a single file, in particular in a debugger to show
source lines.

 use DB::LineCache;
 $lines = DB::LineCache::getlines('/tmp/myperl.pl')
 # The following lines have same effect as the above.
 unshift @INC, '/tmp';
 Dir.chdir('/tmp') {$lines = DB::LineCache::getlines('myperl.pl')

 $line = DB::LineCache::getline('/tmp/myperl.pl', 6)
 # Note lines[6] == line (if /tmp/myperl.pl has 6 lines)

 DB::LineCache::clear_file_cache
 DB::LineCache::update_cache   # Check for modifications of all cached files.

=cut

use English qw( -no_match_vars );
use vars qw(%file_cache %script_cache);

use strict; use warnings;
no warnings 'once';
no warnings 'redefine';

use Cwd 'abs_path';
use File::Basename;
use File::Spec;
use File::stat;

use rlib '../..';
## FIXME:: Make conditional
use Devel::Trepan::DB::Colors;
my $perl_formatter = Devel::Trepan::DB::Colors::setup();

## struct(stat => '$', lines => '%', path => '$', sha1 => '$');

# The file cache. The key is a name as would be given by Perl for
# __FILE__. The value is a LineCacheInfo object.


# Maps a string filename (a String) to a key in %file_cache (a
# String).
#
# One important use of %file2file_remap is mapping the a full path
# of a file into the name stored in %file_cache or given by Perl's
# __FILE__. Applications such as those that get input from users,
# may want canonicalize a file name before looking it up. This map
# gives a way to do that.
#
# Another related use is when a template system is used.  Here we'll
# probably want to remap not only the file name but also line
# ranges. Will probably use this for that, but I'm not sure.

my %file2file_remap;
my %file2file_remap_lines;
my %script2file;
my @tempfiles;

=pod

=head1 SUBROUTINES

I<Note:> in what follows we use I<$file_or_script> to refer to either
a filename which generally should be a Perl file, or a psuedo-file
name that is created in an I<eval()> string. Often, the filename does
not have to be fully qualified. In some cases I<@INC> will be used to
find the file.

=cut

sub remove_temps() 
{
    for my $filename (values %script2file) {
        unlink($filename) if -f $filename;
    }
    for my $filename (@tempfiles) {
        unlink($filename) if -f $filename;
    }
}

END { 
    $DB::ready = 0;
    remove_temps 
};

=pod

=head2 clear_file_cache

B<clear_file_cache()>

B<clear_file_cache(I<$filename>)>


Clear the file cache of I<$filename>. If I<$filename>
is not given, clear all files in the cache.

=cut

sub clear_file_cache(;$)
{
    if (scalar @_ == 1) {
        my $filename = shift;
        if ($file_cache{$filename}) {
            delete $file_cache{$filename};
        }
    } else {
        %file_cache = {};
        %file2file_remap = {};
        %file2file_remap_lines = {};
    }
}

=pod

=head2 clear_file_format_cache

B<clear_file_format_cache()>

Remove syntax-formatted lines in the cache. Use this when you change
the L<Syntax::Highlight::Perl> colors and want to redo how files may
have previously been syntax marked.

=cut

sub clear_file_format_cache() 
{
    while (my ($fname, $cache_info) = each %file_cache) {
        while (my($format, $lines) = each %{$cache_info->{lines_href}}) {
            next if 'plain' eq $format;
            my $ref = $file_cache{$fname};
            $ref->{lines_href}->{$format} = undef;
        }
    }
}

=pod

=head2 clear_script_cache

B<clear_script_cache()>

Clear the script cache entirely.

=cut

sub clear_script_cache() {
    %script_cache = {};
}

=pod

=head2 cached_files

B<cached_files()> => I<list of files>

Return an array of cached file names

=cut

sub cached_files() {
    keys %file_cache;
}

=pod

=head2 checkcache

B<checkcache()> => I<list-of-filenames>

B<checkcache(I<$filename> [, $opts])> => I<list-of-filenames>

Discard cache entries that are out of date. If I<$filename>is I<undef>,
all entries in the file cache are checked.

If we did not previously have I<stat()> information about a file, it
will be added. Return a list of invalidated filenames. I<undef> is
returned if a filename was given but not found cached.

=cut 

sub checkcache(;$$)
{
    my ($filename, $opts) = @_;
    $opts = {} unless defined $opts;

    my $use_perl_d_file = $opts->{use_perl_d_file};

    my @filenames;
    if (defined $filename) {
        @filenames = keys %file_cache;
    } elsif (exists $file_cache{$filename}) {
        @filenames = ($filename);
    } else {
        return undef;
    }

    my @result = ();
    for my $filename (@filenames) {
        next unless exists $file_cache{$filename};
        my $path = $file_cache{$filename}{path};
        if (-f  $path) {
            my $cache_info = $file_cache{$filename}{stat};
            my $stat = File::stat::stat($path);
            if ($cache_info) {
                if ($stat && 
                    ($cache_info->{size} != $stat->size or 
                     $cache_info->{mtime} != $stat->mtime)) {
                    push @result, $filename;
                    update_cache($filename, $opts);
                }
            }
        } else {
            push @result, $filename;
            update_cache($filename, $opts);
        }
    }
    return @result;
}

=pod

=head2 cache_script

B<cache_script(I<$script> [, I<$opts>]) > => I<script>

Cache psuedo eval-string for a pseudo eval-string if it's not already cached.

=cut 

sub cache_script($;$) 
{
    my ($script, $opts) = @_;
    $opts = {} unless defined $opts;
    update_script_cache($script, $opts) unless 
        (exists $script_cache{$script});
    $script;
}

=pod

=head2 cache

B<cache(I<$file_or_script> [, I<$reload_on_change>]) > => I<filename>

Cache file name or script object if it's not already cached.

Return the expanded filename for it in the cache if a filename,
or the script, or C<undef> if we can't find the file.

=cut 

sub cache($;$)
{
    my ($file_or_script, $reload_on_change) = @_;
    cache_file($file_or_script, $reload_on_change)
}

=pod

=head2 cache_file

B<cache(I<$file_or_script> [, I<$reload_on_change>, $opts]) > => I<filename>

Cache I<$filename_or_script> if it's not already cached.

Return the expanded filename for I<$file_or_script> if it is in the
cache or I<undef> if we can't find it.

=cut

sub cache_file($;$$) 
{
    my ($filename, $reload_on_change, $opts) = @_;
    $opts = {} unless defined $opts;
    if (exists $file_cache{$filename}) {
        checkcache($filename) if $reload_on_change;
    } else {
        $opts->{use_perl_d_file} = 1 unless defined $opts->{use_perl_d_file};
        update_cache($filename, $opts);
    }
    if (exists $file_cache{$filename}) {
        $file_cache{$filename}{path};
    } else {
        return undef;
    }
}

=pod

=head2 is_cached

B<cache(I<$file_or_script>)> => I<boolean>

Return true if I<$file_or_script> is cached.

=cut

sub is_cached($)
{ 
    my $file_or_script = shift;
    return undef unless defined $file_or_script;
    exists $file_cache{map_file($file_or_script)};
}

sub is_cached_script($)
{
    my $filename = shift;
    my $name = map_file($filename);
    scalar @{"_<$name"};
}
      
sub is_empty($)
{
    my $filename = shift;
    $filename=map_file($filename);
    my $ref = $file_cache{$filename};
    $ref->{lines_href}{plain};
}

sub file_list()
{
    sort((cached_files(), keys(%file2file_remap)));
}

=pod

=head2 getline

B<getline($file_or_script, $line_number [, $opts])> => I<string>

Get line I<$line_number> from I<$file_script>. Return I<undef> if
there was a problem. If a file named I<$file_or_script> is not found, the
function will look for it in the I<@INC> array.

=cut

sub getline($$;$)
{
    my ($file_or_script, $line_number, $opts) = @_;
    $opts = {} unless defined $opts;
    my $reload_on_change = $opts->{reload_on_change};
    my $filename = map_file($file_or_script);
    ($filename, $line_number) = map_file_line($filename, $line_number);
    my $lines = getlines($filename, $opts);
    # Adjust for 0-origin arrays vs 1 origin line numbers
    my $max_index = scalar(@$lines) - 1;
    my $index = $line_number - 1;
    if (defined $lines && @$lines && $index >= 0 && $index <= $max_index) {
        my $max_continue = $opts->{max_continue} || 1;
        my $line = $lines->[$index];
        return undef unless defined $line;
        if ($max_continue > 1) {
            my $plain_lines = getlines($filename, {output => 'plain'});
            # FIXME: should cache results
            my $sep = ($plain_lines eq $lines) ? '' : "\n";
            my $plain_line = $plain_lines->[$index];
            while (--$max_continue && !DB::eval_ok($plain_line)) {
                $line .= ($sep . $lines->[++$index]);
                $plain_line .= $plain_lines->[$index];
            }
        }
        chomp $line if defined $line;
        return $line;
    } else {
        return undef;
    }
}

=pod

=head2 getlines

B<getlines($filename, [$opts])> => I<string>

Read lines of I<$filename> and cache the results. However
if I<$filename> was previously cached use the results from the
cache. Return I<undef> if we can't get lines.

B<Examples:>

 $lines = LineCache::getline('/tmp/myfile.pl')
 # Same as above
 push @INC, '/tmp';
 $lines = LineCache.getlines('myfile.pl')

=cut

sub getlines($;$);
sub getlines($;$)
{
    my ($filename, $opts) = @_;
    $opts = {use_perl_d_file => 1} unless defined $opts;
    my ($reload_on_change, $use_perl_d_file) = 
        ($opts->{reload_on_change}, $opts->{use_perl_d_file});
    checkcache($filename) if $reload_on_change;
    my $format = $opts->{output} || 'plain';
    if (exists $file_cache{$filename}) {
        my $lines_href = $file_cache{$filename}{lines_href};
        my $lines_aref = $lines_href->{$format};
        if ($opts->{output} && !defined $lines_aref) {
            my @formatted_lines = ();
            my $lines_aref = $lines_href->{plain};
            for my $line (@$lines_aref) {
                push @formatted_lines, highlight_string($line);
                ## print $formatted_text;
            }
            $lines_href->{$format} = \@formatted_lines;
            return \@formatted_lines;
        } else {
            return $lines_aref;
        }
    } elsif (exists $script_cache{$filename}) {
        ### FIXME: combine with above...
        ###  print "+++IS IN SCRIPT CACHE\n";
        my $lines_href = $script_cache{$filename}{lines_href};
        my $lines_aref = $lines_href->{$format};
        if ($opts->{output} && !defined $lines_aref) {
            my @formatted_lines = ();
            my $lines_aref = $lines_href->{plain};
            for my $line (@$lines_aref) {
                push @formatted_lines, highlight_string($line);
                ## print $formatted_text;
            }
            $lines_href->{$format} = \@formatted_lines;
            return \@formatted_lines;
        } else {
            return $lines_aref;
        }
    } else {
        $opts->{use_perl_d_file} = 1;
        update_cache($filename, $opts);
        if (exists $file_cache{$filename}) {
            return getlines($filename, $opts);
        } else {
            return undef;
        }
    }
}

=pod

=head2 highlight_string

B<highlight_string($string)> => I<marked-up-string>

Add syntax-formatting characters via
L<Syntax::Highlight::Pel::Improved> to I<string> according to table
given in L<Devel::Trepan::DB::Colors>.

=cut

sub highlight_string($)
{
    my ($string) = shift;
    $string = $perl_formatter->format_string($string);
    chomp $string;
    $string;
  }

=pod

=head2 path

B<path($filename)> => I<string>

Return full filename path for I<$filename>.

=cut

sub path($)
{
    my $filename = shift;
    $filename = map_file($filename);
    return undef unless exists $file_cache{$filename};
    $file_cache{$filename}->path();
}

sub remap_file($$)
{ 
    my ($from_file, $to_file) = @_;
    $file2file_remap{$from_file} = $to_file;
    cache_file($to_file);
}

=pod

=head2 remap_dbline_to_file

I<remap_dbline_to_file()>

When we run C<trepan.pl -e> ... or C<perl -d:Trepan -e ...> we have
data in internal an "line" array I<@DB::dbline> but no external
file. Here, we will create a temporary file and store the data in
that.

=cut

sub remap_dbline_to_file()
{ 
    my ($fh, $tempfile) = tempfile('XXXX', SUFFIX=>'.pl',
                                   TMPDIR => 1);
    push @tempfiles, $tempfile;
    no strict;
    my @lines = @DB::dbline;
    shift @lines if $lines[0] eq "use Devel::Trepan;\n";
    my $string = join('', @lines);
    print $fh $string;
    $fh->close();
    remap_file('-e', $tempfile);
    return $tempfile
}

sub remap_file_lines($$$$)
{
    my ($from_file, $to_file, $range_ref, $start) = @_;
    my @range = @$range_ref;
    $to_file = $from_file unless $to_file;
    my $ary_ref = ${$file2file_remap_lines{$to_file}};
    $ary_ref = [] unless defined $ary_ref;
    # FIXME: need to check for overwriting ranges: whether
    # they intersect or one encompasses another.
    push @$ary_ref, [$from_file, @range, $start];
}

=pod

=head2 sha1

I<sha1($filename)> => I<string>

Return SHA1 for I<$filename>.

B<Example>:

In file "/tmp/foo.pl": 

  use Devel::Trepan::DB::LineCache;
  DB::LineCache::cache(__FILE__);
  printf "SHA1 of %s is:\n%s\n", __FILE__, DB::LineCache::sha1(__FILE__);

gives: 

  SHA1 of /tmp/foo.pl is:
  719b1aa8d559e64bd0de70b325beff79beac32f5

=cut 

sub DB::LineCache::sha1($)
{
    my $filename = shift;
    $filename = map_file($filename);
    return undef unless exists $file_cache{$filename};
    my $sha1 = $file_cache{$filename}{sha1};
    return $sha1->hexdigest if exists $file_cache{$filename}{sha1};
    $sha1 = Digest::SHA->new('sha1');
    my $line_ary = $file_cache{$filename}{lines_href}{plain};
    for my $line (@$line_ary) {
        next unless defined $line;
        $sha1->add($line);
    }
    $file_cache{$filename}{sha1} = $sha1;
    $sha1->hexdigest;
  }
      
=pod

=head2 size

I<size($filename_or_script)> => I<string>

Return the number of lines in I<$filename_or_script>.

B<Example>:

In file "/tmp/foo.pl": 

  use Devel::Trepan::DB::LineCache;
  DB::LineCache::cache(__FILE__);
  printf "%s has %d lines\n", __FILE__,  DB::LineCache::size(__FILE__);

gives: 

  /tmp/foo.pl has 3 lines

=cut 

sub size($)
{
    my $file_or_script = shift;
    $file_or_script = map_file($file_or_script);
    cache($file_or_script);
    return undef unless exists $file_cache{$file_or_script};
    my $lines_href = $file_cache{$file_or_script}{lines_href};
    return undef unless defined $lines_href;
    scalar @{$lines_href->{plain}};
}

=pod

=head2 stat

B<stat(I<$filename>)> => I<stat-info>

Return file I<stat()> info in the cache for I<$filename>.

B<Example>:

In file "/tmp/foo.pl": 

  use Devel::Trepan::DB::LineCache;
  DB::LineCache::cache(__FILE__);
  printf("stat() info for %s is:
  dev    ino      mode nlink  uid  gid rdev size atime      ctime ...
  %4d  %8d %7o %3d %4d %4d %4d %4d %d %d",
         __FILE__, 
         @{DB::LineCache::stat(__FILE__)});

gives: 

  stat() info for /tmp/foo.pl is:
  dev    ino      mode nlink  uid  gid rdev size atime      ctime ...
  2056   5242974  100664   1 1000 1000    0  266 1347890102 1347890101

=cut

sub DB::LineCache::stat($)
{ 
    my $filename = shift;
    return undef unless exists $file_cache{$filename};
    $file_cache{$filename}{stat};
}

=pod

=head2 trace_line_numbers

I<trace_line_numbers($filename [, $reload_on_change])> => I<list-of-numbers>

Return an array of breakpoints in $I<filename>.

=cut 

sub trace_line_numbers($;$)
{
    my ($filename, $reload_on_change) = @_;
    my $fullname = cache($filename, $reload_on_change);
    return undef unless $fullname;
    return sort {$a <=> $b} keys %{$file_cache{$filename}{trace_nums}};
  }
    
=pod

=head2 is_trace_line

B<is_trace_line($filename, $line_num [,$reload_on_change])> => I<boolean>

Return I<true> if I<$line_num> is a trace line number of I<$filename>.

=cut

sub is_trace_line($$;$)
{
    my ($filename, $line_num, $reload_on_change) = @_;
    my $fullname = cache($filename, $reload_on_change);
    return undef unless $fullname;
    return !!$file_cache{$filename}{trace_nums}{$line_num};
  }
    
sub map_file($)
{ 
    my $file = shift;
    return undef unless defined($file);
    $file2file_remap{$file} ? $file2file_remap{$file} : $file
  }

use File::Temp qw(tempfile);
sub map_script($$)
{
    my ($script, $string) = @_;
    if (exists $script2file{$script}) {
        $script2file{$script};
    } else  {
        # my $sha1 = Digest::SHA->new('sha1');
        # $sha1->add($string);
        my ($fh, $tempfile) = tempfile('XXXX', SUFFIX=>'.pl',
                                       TMPDIR => 1);
        print $fh $string;
        $fh->close();
        $script2file{$script} = $tempfile;
        # cache_file($tempfile);
        # $file_cache{$tempfile}{sha1} = $sha1;
        $tempfile;
    }
}

sub map_file_line($$)
{
    my ($file, $line) = @_;
    if (exists $file2file_remap_lines{$file}) {
        my $triplet_ref = $file2file_remap_lines{$file};
        for my $triplet (@$triplet_ref) {
            my ($from_file, $range_ref, $start) = @$triplet;
            my @range = @$range_ref;
            if ( $range[0]  >= $line && $range[-1] <= $line) {
                my $from_file = $from_file || $file;
                return [$from_file, $start+$line-$range[0]];
            }
        }
    }
    return ($file, $line);
}

=pod

=head2 filename_is_eval

B<filename_is_eval($filename)> => I<boolean>

Return I<true> if $filename matches one of the pseudo-filename strings
that get created for by I<eval()>. 

=cut

sub filename_is_eval($)
{
    my $filename = shift;
    return 0 unless defined $filename;
    return !!($filename =~ /^\(eval \d+\)|-e$/);
}

=pod

=head2 update_script_cache

B<update_script_cache($script, $opts)> => I<boolean>

Update a cache entry for an pseudo eval-string file name. If something
is wrong, return I<undef>. Return I<true> if the cache was updated and
I<false> if not.

=cut

sub update_script_cache($$)
{
    my ($script, $opts) = @_;
    return 0 unless filename_is_eval($script);
    my $string = $opts->{string};
    my $lines_href = {};
    if (defined($string)) {
        my @lines = split(/\n/, $string);
        $lines_href->{plain} = \@lines;
    } else {
        if ($script eq $DB::filename) {
            # Should be the same as the else case, 
            # but just in case...
            $lines_href->{plain} = \@DB::lines;
            $string = join("\n", @DB::lines);
        } else {
            no strict;
            $lines_href->{plain} = \@{"_<$script"};
            $string = join("\n", @{"_<$script"});
        }
    }
    $lines_href->{$opts->{output}} = highlight_string($string) if 
        $opts->{output};

    my $entry = {
        lines_href => $lines_href,
    };
    $script_cache{$script} = $entry;
    return 1;
  }

=pod

=head2 readlines

B<readlines($filename)> => I<list of strings>

Return a a list of strings for I<$filename>. If we can't read
I<$filename> retun I<undef>. Each line will have a "\n" at the end.

=cut 

sub readlines($)
{
    my $path = shift;
    if (-r $path) {
        open(FH, '<', $path);
        seek FH, 0, 0;
        my @lines = <FH>;
        close FH;
        return @lines;
    } else {
        return undef;
    }
}

=pod

=head2 update_cache

B<update_cache($filename, [, $opts]> 

Update a cache entry.  If something's wrong, return I<undef>. Return
I<true> if the cache was updated and I<false> if not.  If
$I<$opts-E<gt>{use_perl_d_file}> is I<true>, use that as the source for the
lines of the file.

=cut 

sub update_cache($;$) 
{
    my ($filename, $opts) = @_;
    my $read_file = 0;
    $opts = {} unless defined $opts;
    my $use_perl_d_file = $opts->{use_perl_d_file};
    $use_perl_d_file = 1 unless defined $use_perl_d_file;

    return undef unless $filename;

    delete $file_cache{$filename};

    my $is_eval = filename_is_eval($filename);
    my $path = $filename;
    unless ($is_eval) {
        $path = abs_path($filename) if -f $filename;
    }
    my $lines_href;
    my $trace_nums;
    my $stat;
    if ($use_perl_d_file) {
        my @list = ($filename);
        if ($is_eval) {
            cache_script($filename);
            ## FIXME: create a temporary file in script2file;
        }
        push @list, $file2file_remap{$path} if exists $file2file_remap{$path};
        for my $name (@list) {
            no strict; # Avoid string as ARRAY ref error message
            if (scalar @{"main::_<$name"}) {
                $stat = File::stat::stat($path);
            }
            my $raw_lines = \@{"main::_<$name"};

            # Perl sometimes doesn't seem to save all file data, such
            # as those intended for POD or possibly those after
            # __END__. But we want these, so we'll have to read the
            # file the old-fashioned way and check lines. Variable
            # $incomplete records if there was a mismatch.
            my $incomplete = 0;
            if (-r $path) {
                my @lines_check = readlines($path);
                my @lines = @$raw_lines;
                for (my $i=1; $i<=$#lines; $i++) {
                    if (defined $raw_lines->[$i]) {
                        $trace_nums->{$i} = 1 if ($raw_lines->[$i] != 0);
                        $incomplete = 1 if $raw_lines->[$i] ne $lines[$i];
                    } else {
                        $raw_lines->[$i] = $lines_check[$i-1] 
                    }
                }
            }
            use strict;
            $lines_href = {};
            $lines_href->{plain} = $raw_lines;
            if ($opts->{output} && defined($raw_lines)) {
                # Some lines in $raw_lines may be undefined
                no strict; no warnings;
                local $WARNING=0;
                my $highlight_lines = highlight_string(join('', @$raw_lines));
                my @highlight_lines = split(/\n/, $highlight_lines);
                $lines_href->{$opts->{output}} = \@highlight_lines;
                use strict; use warnings;
            }
            my $entry = {
                stat       => $stat,
                lines_href => $lines_href,
                path       => $path,
                incomplete => $incomplete,
                trace_nums => $trace_nums,
            };
            $read_file = 1;
        }
    }

    # File based reading is done here.
    if (-f $path ) {
        $stat = File::stat::stat($path) unless defined $stat;
    } elsif (!$read_file) {
        if (basename($filename) eq $filename) {
            # try looking through the search path.
            for my $dirname (@INC) {
                $path = File::Spec->catfile($dirname, $filename);
                if ( -f $path) {
                    $stat = File::stat::stat($path);
                    last;
                }
            }
        }
        return 0 unless defined $stat;
    }
    if ( -r $path ) { 
        my @lines = readlines($path);
        $lines_href = {plain => \@lines};
        if ($opts->{output}) {
            my $highlight_lines = highlight_string(join('', @lines));
            my @highlight_lines = split(/\n/, $highlight_lines);
            $lines_href->{$opts->{output}} = \@highlight_lines;
        }
    }
    my $entry = {
                stat       => $stat,
                lines_href => $lines_href,
                path       => $path,
                incomplete => 0,
                trace_nums => $trace_nums,
            };
    $file_cache{$filename} = $entry;
    no warnings;
    $file2file_remap{$path} = $filename;
    return 1;
}

# example usage
unless (caller) {
    BEGIN {
        use English qw( -no_match_vars );
        $PERLDB |= 0x400;
    };  # Turn on saving @{_<$filename};
    my $file=__FILE__;
    my $fullfile = abs_path($file);
    no strict;
    print scalar(@{"main::_<$file"}), "\n";
    use strict;

    my $script_name = '(eval 234)';
    update_script_cache($script_name, {string => "now\nis\nthe\ntime"});
    print join(', ', keys %DB::LineCache::script_cache), "\n";
    my $lines = $script_cache{$script_name}{lines_href}{plain};
    print join("\n", @{$lines}), "\n";
    $lines = getlines($script_name);
    printf "%s has %d lines\n",  $script_name,  scalar @$lines;
    printf("Line 1 of $script_name is:\n%s\n", 
          getline($script_name, 1));
    my $max_line = size($script_name);
    printf("%s has %d lines via size\n",  
           $script_name,  scalar @$lines);
    do __FILE__;
    my @line_nums = trace_line_numbers(__FILE__);

    ### FIXME: add more of this stuff into unit test.
    printf("Breakpoints for: %s:\n%s\n", 
           __FILE__, join(', ', @line_nums[0..30]));
    $lines = getlines(__FILE__);
    printf "%s has %d lines\n",  __FILE__,  scalar @$lines;
    my $full_file = abs_path(__FILE__);
    $lines = getlines(__FILE__);
    printf "%s still has %d lines\n",  __FILE__,  scalar @$lines;
    $lines = getlines(__FILE__);
    printf "%s also has %d lines\n",  $full_file,  scalar @$lines;
    my $line_number = __LINE__;
    my $line = getline(__FILE__, $line_number);
    printf "The %d line is:\n%s\n", $line_number, $line ;
    remap_file('another_name', __FILE__);
    print getline('another_name', __LINE__), "\n";
    printf "Files cached: %s\n", join(', ', cached_files);
    update_cache(__FILE__);
    printf "I said %s has %d lines!\n", __FILE__, size(__FILE__);
    printf "SHA1 of %s is:\n%s\n", __FILE__, sha1(__FILE__);
    
    my $stat = stat(__FILE__);
    printf("stat info size: %d, ctime %s, mode %o\n", 
           $stat->size, $stat->ctime, $stat->mode);

    my $lines_aref = getlines(__FILE__, {output=>'term'});
    print join("\n", @$lines_aref[0..5,50..55]), "\n" if defined $lines_aref;
    $DB::filename = '(eval 4)';
    my $filename = map_script($DB::filename, "\$x=1;\n\$y=2;\n\$z=3;\n");
    print "mapped eval is $filename\n";
    printf("%s is a trace line? %d\n", __FILE__, 
           is_trace_line(__FILE__, __LINE__-1));
    printf("%s is a trace line? %d\n", __FILE__, 
           is_trace_line(__FILE__, __LINE__));
    eval "printf \"filename_is_eval: %s, %d\n\", __FILE__, 
          filename_is_eval(__FILE__);";
    printf("filename_is_eval: %s, %d\n", __FILE__, filename_is_eval(__FILE__));
    printf("filename_is_eval: %s, %d\n", '-e', filename_is_eval('-e'));

    #$DB::filename = 'bogus';
    #eval {
    #   print '+++', is_cached_script(__FILE__), "\n";
    #};

    $lines_aref = getlines(__FILE__, {output=>'term'});
    # print("trace nums again: ", join(', ',
    #                            trace_line_numbers(__FILE__)),
    #       "\n");
    $line = getline(__FILE__, __LINE__,
                    {output=>'term',
                     max_continue => 6});
    print '-' x 30, "\n";
    print "$line\n";
    $line = getline(__FILE__, __LINE__,
                    {output=>'plain',
                     max_continue => 5});
    print '-' x 30, "\n";
    print "$line\n";
}

1;
