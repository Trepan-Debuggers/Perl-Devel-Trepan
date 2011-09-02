#!/usr/bin/env perl
# 
#   Copyright (C) 2011 Rocky Bernstein <rockb@cpan.org>
#
#
=head1 NAME Linecache

DB::LineCache - package to read and cache lines of a Perl program. 

=head1 SYNOPSIS

The LineCache package allows one to get any line from any file,
caching lines of the file on first access to the file. Although the 
file may be any file, the common use is when the file is a Ruby
script since parsing of the file is done to figure out where the
statement boundaries are.

The routines here may be is useful when a small random sets of lines
are read from a single file, in particular in a debugger to show
source lines.

  use 'DB::LineCache'
  lines = LineCache::getlines('/tmp/myruby.rb')
  # The following lines have same effect as the above.
  $: << '/tmp'
  Dir.chdir('/tmp') {lines = LineCache::getlines('myruby.rb')

  line = LineCache::getline('/tmp/myruby.rb', 6)
  # Note lines[6] == line (if /tmp/myruby.rb has 6 lines)

  LineCache::clear_file_cache
  LineCache::update_cache   # Check for modifications of all cached files.
=cut

use Digest::SHA1;
use English;
## require 'set'

use version; $VERSION = '0.1.0';

# A package to read and cache lines of a Ruby program. 
package DB::LineCache;

use Cwd 'abs_path';
use File::Basename;
use File::Spec;
use File::stat;

## FIXME:: Make conditional
use Syntax::Highlight::Perl::Improved;
my $perl_formatter = new Syntax::Highlight::Perl::Improved;

## struct(stat => '$', lines => '%', path => '$', sha1 => '$');

# The file cache. The key is a name as would be given by Ruby for
# __FILE__. The value is a LineCacheInfo object.

my %file_cache;
my %script_cache;

# Maps a string filename (a String) to a key in %file_cache (a
# String).
#
# One important use of @@file2file_remap is mapping the a full path
# of a file into the name stored in @@file_cache or given by Ruby's
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

sub remove_script_temps() 
{
    for my $filename (values %script2file) {
	unlink($filename) if -f $filename;
    }
}

END { remove_script_temps };

  
# Clear the file cache entirely.
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

# Remove syntax-formatted lines in the cache. Use this
# when you change the CodeRay syntax or Token formatting
# and want to redo how files may have previously been 
# syntax marked.
sub clear_file_format_cache() 
{
    while ((my $fname, $cache_info)= each %file_cache) {
	while (my $format, $lines = each %cache_info) {
	    next if 'plain' eq $format;
	    my $ref = $file_cache{$fname};
	    my $href = $ref->{lines};
	    $href->{$format} = undef;
      }
    }
  }

# Remove syntax-formatted lines in the cache. Use this
# when you change the CodeRay syntax or Token formatting
# and want to redo how files may have previously been 
# syntax marked.
sub clear_file_format_cache() 
{
    while ((my $fname, $cache_info) = each %file_cache) {
	while ((my $format, $lines) = each %{$cache_info->lines}) {
	    next if 'plain' eq $format;
	    my $ref = $file_cache{$fname};
	    $ref->lines($format) = undef;
	}
    }
}

# Clear the script cache entirely.
sub clear_script_cache() {
    $script_cache = {};
}

# Return an array of cached file names
sub cached_files() {
    keys %file_cache;
}

# Discard cache entries that are out of date. If +filename+ is +undef+
# all entries in the file cache +@@file_cache+ are checked.
# If we don't have stat information about a file, which can happen
# if the file was read from $__SCRIPT_LINES but no corresponding file
# is found, it will be kept. Return a list of invalidated filenames.
# undef is returned if a filename was given but not found cached.
sub checkcache(;$$)
{
    my ($filename, $opts) = @_;
    $opts //= {};

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
	my $path = $file_cache{$filename}->{path};
	if (-f  $path) {
	    my $cache_info = $file_cache{$filename}->{stat};
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

# Cache script if it's not already cached.
sub cache_script($;$) 
{
    my ($script, $opts) = @_;
    $opts //= {};
    update_script_cache($script, $opts) unless 
	(exists $script_cache{$script});
    $script;
}

# Cache file name or script object if it's not already cached.
# Return the expanded filename for it in the cache if a filename,
# or the script, or undef if we can't find the file.
sub cache($;$)
{
    my ($file_or_script, $reload_on_change) = @_;
    cache_file($file_or_script, $reload_on_change)
}

# Cache filename if it's not already cached.
# Return the expanded filename for it in the cache
# or undef if we can't find the file.
sub cache_file($;$$) 
{
    my ($filename, $reload_on_change, $opts) = @_;
    $opts //={};
    if (exists $file_cache{$filename}) {
	checkcache($filename) if $reload_on_change;
    } else {
	$opts->{$use_perl_d_file} //= 1;
	update_cache($filename, $opts);
    }
    if (exists $file_cache{$filename}) {
	$file_cache{$filename}{path};
    } else {
	return undef;
    }
}

# Return true if file_or_script is cached.
sub is_cached($)
{ 
    my $file_or_script = shift;
    exists $file_cache{unmap_file($file_or_script)};
}

sub is_cached_script($)
{
    my $filename = shift;
    my $name = unmap_file($filename);
    scalar @{"_<$name"};
}
      
sub is_empty($)
{
    my $filename = shift;
    $filename=unmap_file($filename);
    my $ref = $file_cache{$filename};
    $ref->lines(plain);
}

# Get line +line_number+ from file named +filename+. Return undef if
# there was a problem. If a file named filename is not found, the
# function will look for it in the $: array.
# 
# Examples:
# 
#  lines = LineCache::getline('/tmp/myfile.rb')
#  # Same as above
#  $: << '/tmp'
#  lines = LineCache.getlines('myfile.rb')
#
sub getline($$;$)
{
    my ($file_or_script, $line_number, $opts) = @_;
    $opts //= {};
    my $reload_on_change = $opts->{reload_on_change};
    my $filename = unmap_file($file_or_script);
    $filename, $line_number = unmap_file_line($filename, $line_number);
    my $lines = getlines($filename, $opts);
    if (@$lines && $line_number > 0 && $line_number <= scalar @$lines) {
	my $line = $lines->[$line_number];
	chomp $line;
        return $line;
    } else {
        return undef;
    }
}

# Read lines of +filename+ and cache the results. However +filename+ was
# previously cached use the results from the cache. Return undef
# if we can't get lines
sub getlines($;$)
{
    my ($filename, $opts) = @_;
    $opts //= {use_perl_d_file => 1};
    ($reload_on_change, $use_perl_d_file) = 
        ($opts->{reload_on_change}, $opts->{use_perl_d_file});
    checkcache($filename) if $reload_on_change;
    my $format = $opts->{output} || 'plain';
    if (exists $file_cache{$filename}) {
	my %lines = %{$file_cache{$filename}->{lines}};
	if ($opts->{output} && ! exists $lines{$format}) {
	    my $lines_aref = $lines{plain};
	    my @lines = @$lines_aref;
	    # my $raw_text = join("\n", @lines);
	    my $raw_text = join('', @lines);
	    my $formatted_text = highlight_string($raw_text);
	    ## print $formatted_text;
	    $lines{$format} = split(/\n/, $formatted_text);
	}
	return $lines{$format};
    } else {
	$opts->{use_perl_d_file} = 1;
	update_cache($filename, $opts);
	if (exists $file_cache{$filename}) {
	    my $entry = $file_cache{$filename};
	    my %lines = %{$entry->{lines}};
	    return $lines{$format};
	} else {
	    return undef;
	}
    }
}

sub highlight_string($)
{
    my ($string) = shift;
    $perl_formatter->format_string($string);
  }

 # Return full filename path for filename
sub path($)
{
    my $filename = shift;
    $filename = unmap_file($filename);
    return undef unless exists $file_cache{$filename};
    $file_cache{$filename}->path();
}

sub remap_file($$)
{ 
    my ($from_file, $to_file) = @_;
    $file2file_remap{$from_file} = $to_file;
    cache_file($to_file);
}

sub remap_file_lines($$$$)
{
    my ($from_file, $to_file, $range_ref, $start) = @_;
    @range = @$range_ref;
    $to_file = $from_file unless $to_file;
    my $ary_ref = ${$file2file_remap_lines[$to_file]} //= [];
    # FIXME: need to check for overwriting ranges: whether
    # they intersect or one encompasses another.
    push @$ary_ref, [$from_file, @range, $start];
}
  
#   # Return SHA1 of filename.
#   sub sha1(filename)
#     filename = unmap_file(filename);
#     return undef unless @@file_cache.member?(filename);
#     return $file_cache{filename}->sha1.hexdigest if 
#       $file_cache{filename}->sha1;
#     sha1 = Digest::SHA1.new;
#     $file_cache{filename}->lines{plain}.each do |line|
#       sha1 << line + "\n";
#     }
#     $file_cache{filename}->sha1 = sha1;
#     sha1.hexdigest;
#   }
      
# Return the number of lines in filename
sub size($)
{
    my $file_or_script = shift;
    cache($file_or_script);
    $file_or_script = unmap_file($file_or_script);
    return undef unless exists $file_cache{$file_or_script};
    my $lines = $file_cache{$file_or_script}->{lines};
    scalar @{$lines->{plain}};
}

# Return File.stat in the cache for filename.
sub stat($)
{ 
    my $filename = shift;
    return undef unless exists $file_cache{$filename};
    $file_cache{$filename}->{stat};
}

#   # Return an Array of breakpoints in filename.
#   # The list will contain an entry for each distinct line event call
#   # so it is possible (and possibly useful) for a line number appear more
#   # than once.
#   sub trace_line_numbers(filename, reload_on_change=false)
#     fullname = cache(filename, reload_on_change);
#     return undef unless fullname;
#     e = $file_cache{filename};
#     unless e.line_numbers
#       e.line_numbers = 
#         TraceLineNumbers.lnums_for_str_array(e.lines[:plain]);
#       e.line_numbers = false unless e.line_numbers;
#     }
#     e.line_numbers;
#   }
    
sub unmap_file($)
{ 
    my $file = shift;
    $file2file_remap{$file} ? $file2file_remap{$file} : $file
  }

sub unmap_file_line($$)
{
    my ($file, $line) = @_;
    if (exists $file2file_remap_lines{$file}) {
	for my $triplet (@$file2file_remap_lines{$file}) {
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

#   # UPDATE a cache entry.  If something is wrong, return undef. Return
#   # 1 if the cache was updated and false if not. 
#   sub update_script_cache(script, opts)
#     # return false unless script_is_eval?(script)
#     # string = opts[:string] || script.eval_source
#     lines = {:plain => string.split(/\n/)}
#     lines[opts[:output]] = highlight_string(string, opts[:output]) if
#       opts[:output]
#     @@script_cache[script] = 
#       LineCacheInfo.new(undef, undef, lines, undef, opts[:sha1], 
#                         opts[:compiled_method])
#     return 1
#   }

# Update a cache entry.  If something's
# wrong, return undef. Return 1 if the cache was updated and false
# if not.  If use_perl_d_file is 1, use that as the source for the
# lines of the file
sub update_cache($;$) 
{
    my ($filename, $opts) = @_;
    $opts //={};
    my $use_perl_d_file = $opts->{use_perl_d_file} //= 1;

    return undef unless $filename;

    delete $file_cache{$filename};

    my $path = abs_path($filename);
    
    if ($use_perl_d_file) {
	my @list = ($filename);
	push @list, $file2file_remap{$path} if exists $file2file_remap{$path};
	for my $name (@list) {
	    my $stat;
	    if (scalar @{"main::_<$name"}) {
		$stat = File::stat::stat($path);
	    }
	    my $raw_lines = \@{"main::_<$name"};
	    %lines = {};
	    $lines{plain} = $raw_lines;
	    $lines{$opts->{output}} =
		split("\n", 
		      highlight_string(join('', @$raw_lines))) if $opts->{output};
	    my $entry = {
		stat  => $stat,
		lines => \%lines,
		path  => $path
	    };
	    $file_cache{$filename}  = $entry;
	    $file2file_remap{$path} = $filename;
          return 1
        }
    }
      
    if ( -f $path ) {
	$stat = File::stat::stat($path);
    } elsif (basename($filename) eq $filename) {
	# try looking through the search path.
	$stat = undef;
	for my $dirname (@INC) {
	    $path = File::Spec::catfile->($dirname, $filename);
	    if ( -f $path) {
		$stat = File::stat::stat($path);
		last;
	    }
	}
	return 0 unless $stat
    }
    open(FH, '<', $path);
    seek FH, 0, 0;
    my @lines = <FH>;
    $raw_string = join("\n", @lines);
    %lines = {plain => \@lines};
    close FH;
    $lines[$opts->{output}] = 
        split(/\n/, highlight_string($raw_string)) 
	if $opts->{output};
    my $stat = File::stat::stat($path);
    my $entry = {
		stat  => $stat,
		lines => \%lines,
		path  => $path
	    };
    $file_cache{$filename} = $entry;
    $file2file_remap{$path} = $filename;
    return 1;
}

# example usage
unless (caller) {
    BEGIN {
	use English;
	$PERLDB |= 0x400;
    };  # Turn on saving @{_<$filename};
    my $file=__FILE__;
    my $fullfile = abs_path($file);
    print scalar(@{"main::_<$file"}), "\n";
    
    my $lines = DB::LineCache::getlines(__FILE__);
    printf "%s has %d lines\n",  __FILE__,  scalar @$lines;
    my $full_file = abs_path(__FILE__);
    my $lines = DB::LineCache::getlines(__FILE__);
    printf "%s still has %d lines\n",  __FILE__,  scalar @$lines;
    my $lines = DB::LineCache::getlines(__FILE__);
    printf "%s also has %d lines\n",  $full_file,  scalar @$lines;
    my $line_number = __LINE__;
    my $line = DB::LineCache::getline(__FILE__, $line_number);
    printf "The %d line is:\n%s\n", $line_number, $line ;
    DB::LineCache::remap_file('another_name', __FILE__);
    print DB::LineCache::getline('another_name', __LINE__), "\n";
    
    printf "Files cached: %s\n", join(', ', DB::LineCache::cached_files);
    DB::LineCache::update_cache(__FILE__);
    ## DB::LineCache::checkcache(__FILE__);
    printf "I said %s has %d lines!\n", __FILE__, DB::LineCache::size(__FILE__);
    # print "#{__FILE__} trace line numbers:\n" + 

    my $stat = DB::LineCache::stat(__FILE__);
    printf("stat info size: %d, ctime %s, mode %o\n", 
	   $stat->size, $stat->ctime, $stat->mode);

    ## use Enbugger; Enbugger->stop;
    my $lines = DB::LineCache::getlines(__FILE__, {output=>'term'});
    print $lines, "\n";

    #   "#{DB::LineCache::trace_line_numbers(__FILE__).to_a.sort.inspect}"
    sub yes_no($) 
	       { 
		   my $var = shift;  return $var ? "" : "not "; 
	       };
    # print("#{__FILE__} is %scached." % 
    #      yes_no(LineCache::cached?(__FILE__)))
    # print "Full path: #{DB::LineCache::path(__FILE__)}"
    # LineCache::checkcache # Check all files in the cache
    # LineCache::clear_file_cache 
    # print("#{__FILE__} is now %scached." % 
    #      yes_no(LineCache::cached?(__FILE__)))
    # digest = SCRIPT_LINES__.select{|k,v| k =~ /digest.rb$/}
    # print digest.first[0] if digest
    # line = LineCache::getline(__FILE__, 7)
    # print "The 7th line is\n#{line}" 
    # LineCache::remap_file_lines(__FILE__, 'test2', (10..20), 6)
    # print LineCache::getline('test2', 10)
    # print "Remapped 10th line of test2 is\n#{line}" 
}

1;
