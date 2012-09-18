# Pretty much cut and paste from Syntax::Highlight::Perl's viewperl
package Devel::Trepan::DB::Colors;
use Syntax::Highlight::Perl::Improved;

#
# Set up formatter to do ANSI colors.
#
#
# Could use Term::ANSIColor but it wasn't installed on my machine, and I "know" the
# colors anyway.  If this causes problems, replace with Term::ANSIColor data.
#
%ANSI_colors = (
    none      => "\e[0m",

    red       => "\e[0;31m",
    green     => "\e[0;32m",
    yellow    => "\e[0;33m",
    blue      => "\e[0;34m",
    magenta   => "\e[0;35m",
    cyan      => "\e[0;36m",
    white     => "\e[0;37m",

    gray      => "\e[1;30m",
    bred      => "\e[1;31m",
    bgreen    => "\e[1;32m",
    byellow   => "\e[1;33m",
    bblue     => "\e[1;34m",
    bmagenta  => "\e[1;35m",
    bcyan     => "\e[1;36m",
    bwhite    => "\e[1;37m",

    bgred     => "\e[41m",
    bggreen   => "\e[42m",
    bgyellow  => "\e[43m",
    bgblue    => "\e[44m",
    bgmagenta => "\e[45m",
    bgcyan    => "\e[46m",
    bgwhite   => "\e[47m",
);

sub setup()
{
    my $perl_formatter = new Syntax::Highlight::Perl::Improved;
    $perl_formatter->unstable(1);
    $perl_formatter->set_format(
        'Comment_Normal'   => [$ANSI_colors{'bblue'},    $ANSI_colors{'none'}],
        'Comment_POD'      => [$ANSI_colors{'bblue'},    $ANSI_colors{'none'}],
        'Directive'        => [$ANSI_colors{'magenta'},  $ANSI_colors{'none'}],
        'Label'            => [$ANSI_colors{'magenta'},  $ANSI_colors{'none'}],
        'Quote'            => [$ANSI_colors{'black'},    $ANSI_colors{'none'}],
        'String'           => [$ANSI_colors{'gray'},     $ANSI_colors{'none'}],
        'Subroutine'       => [$ANSI_colors{'blue'},     $ANSI_colors{'none'}],
        'Variable_Scalar'  => [$ANSI_colors{'bgreen'},   $ANSI_colors{'none'}],
        'Variable_Array'   => [$ANSI_colors{'magenta'},   $ANSI_colors{'none'}],
        'Variable_Hash'    => [$ANSI_colors{'bgreen'},   $ANSI_colors{'none'}],
        'Variable_Typeglob'=> [$ANSI_colors{'black'},    $ANSI_colors{'none'}],
        'Whitespace'       => ['',                       ''                  ],
        'Character'        => [$ANSI_colors{'bred'},     $ANSI_colors{'none'}],
        'Keyword'          => [$ANSI_colors{'bblue'},    $ANSI_colors{'none'}],
        'Builtin_Function' => [$ANSI_colors{'bwhite'},   $ANSI_colors{'none'}],
        'Builtin_Operator' => [$ANSI_colors{'black'},    $ANSI_colors{'none'}],
        'Operator'         => [$ANSI_colors{'black'},    $ANSI_colors{'none'}],
        'Bareword'         => [$ANSI_colors{'white'},    $ANSI_colors{'none'}],
        'Package'          => [$ANSI_colors{'green'},    $ANSI_colors{'none'}],
        'Number'           => [$ANSI_colors{'bmagenta'}, $ANSI_colors{'none'}],
        'Symbol'           => [$ANSI_colors{'gray'},     $ANSI_colors{'none'}],
        'CodeTerm'         => [$ANSI_colors{'gray'},     $ANSI_colors{'none'}],
        'DATA'             => [$ANSI_colors{'gray'},     $ANSI_colors{'none'}],
        
        'Line'             => [$ANSI_colors{'byellow'},  $ANSI_colors{'none'}],
        'File_Name'        => [$ANSI_colors{'red'} . $ANSI_colors{'bgwhite'}, 
                               $ANSI_colors{'none'}],
        );
    $perl_formatter;
}
