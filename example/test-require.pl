use File::Basename;
use File::Spec;
my $DIR = dirname(__FILE__);
my $require_file = File::Spec->catfile($DIR, "test-module.pm");
require $require_file;
my $x = Test::Module::five();
my $y = $x;


