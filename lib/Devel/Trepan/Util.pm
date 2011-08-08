package Devel::Trepan::Util;
use vars qw(@EXPORT @EXPORT_OK @ISA);
@EXPORT    = qw( hash_merge safe_repr);
@ISA = qw(Exporter);

# Hash merge like Ruby has.
sub hash_merge(%%) {
    my ($config, $default_opts) = @_;
    while (($field, $default_value) = each %$default_opts) {
	$config->{$field} = $default_value unless defined $config->{$field};
    };
    $config;
}

sub safe_repr($$;$)
{
    my ($str, $max, $elipsis) = @_;
    $elipsis = '... ' unless defined $elipsis;
    my $strlen = length($str);
    if ($max > 0 && $strlen > $max && -1 == index($str, "\n")) {
	sprintf("%s%s%s", substr($str, 0, $max/2), 
		$elipsis,  substr($str, ($strlen-$max)/2));
    } else {
	$str;
    }
}

if (__FILE__ eq $0 ) {
    my $default_config = {a => 1, b => 'c'};
    require Data::Dumper;
    import Data::Dumper;
    my $config = {};
    hash_merge $config, $default_config;
    print Dumper($config), "\n";

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
    print safe_repr($string, 17, '');

}

1;
