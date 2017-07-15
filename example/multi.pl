my ($x, $y, $z) = (0, 1, 2);
if ($x) { $y--; if ($y) { $z += 1 } else { $z -= 1 }; } else { $z = 10 };
print "x: $x, y: $y, z: $z\n";

