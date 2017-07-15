use File::Basename;
use File::Spec;
my $dirname = dirname(__FILE__);
require File::Spec->catfile($dirname, 'four.pm');
sub five() 
{
    require Enbugger; Enbugger->load_debugger('trepan');
    Enbugger->stop;
    four() + 1
}
print "five is", five(), "\n";
