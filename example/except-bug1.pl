sub foo($)
{
    my ($a) = @_;
    1/0;
}

local $b = 5;
my $c = 10;
foo(5)
