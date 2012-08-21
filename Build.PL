#!/usr/bin/env perl
#  Copyright (C) 2011, 2012 Rocky Bernstein <rocky@cpan.org>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Module::Build;
use Config;

my $builder = Module::Build->new( 
    module_name         => 'Devel::Trepan',
    add_to_cleanup      => [ 'Devel-Trepan-*', 'tmp*', '*.got'  ],
    create_makefile_pl  => 'passthrough',
    dist_abstract       => 
    'Modular Perl Debugger (akin to Ruby "Trepanning" Debuggers).',
    dist_author         => 'Rocky Bernstein <rocky@cpan.org>',
    dist_version_from   => 'lib/Devel/Trepan.pm',
    license             => 'gpl',
    needs_compiler      => 0,
    release_status      => 'stable', # or 'testing'
    # release_status      => 'testing',  # or 'stable'

    meta_merge => {
	resources => {
	    bugtracker  => 'https://github.com/rocky/Perl-Devel-Trepan/issues',
	    repository  => 'http://github.com/rocky/Perl-Devel-Trepan'
	}
    },    

    configure_requires  => { 
	'Module::Build' => '0.32',
			      
    },
    build_requires => {
        # 'String::Diff'        => 0,
    },
    test_requires => {
        'Test::More'                        => '0.81',
    },
    recommends => {
	'Term::ReadLine::Perl'              => 0,
	'Term::ReadKey'                     => 0,
	'Eval::WithLexicals'                => 0,
	'Data::Printer'                     => 0,
    },

    requires => {
	'perl'                              => '5.008008',
	'Array::Columnize'                  => '1.01',
 	'Data::Dumper'                      => 0,
	'Getopt::Long'                      => '2.36',
        'Digest::SHA'                       => 0,
        'PadWalker'                         => 0,
        'Syntax::Highlight::Perl::Improved' => 0,
        'rlib'                              => '0.02',
        'version'                           => 0,
    },
    sign                => ($ENV{PERL_MB_NOSIGN} ? 0 : 1),
    );

$builder->create_build_script();
