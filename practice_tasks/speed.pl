use strict;
use warnings;

use Data::Dumper;

my ($n, $m, $input, $flag, @splitted_input);
$flag = 0;

while (!$flag){
    $flag = 1;
    $input = <>;
    @splitted_input = split(" ",$input);
    $n = int($splitted_input[0]);
    $m = int($splitted_input[1]);

    print "n => " . $n . ", m => " . $m . "\n";

    $flag = 0 if (($n < 2) || ($n > 1000));
    $flag = 0 if (($m < 1) || ($m > 10000));
}

my ($f, $t, $s, $counter, @information);

$flag = 0;
$counter = 0;

while ($counter < $m){
    $flag = 1;
    $input = <>;
    @splitted_input = split(" ",$input);
    $f = int($splitted_input[0]);
    $t = int($splitted_input[1]);
    $s = int($splitted_input[2]);

    print "f => " . $f . ", t => " . $t . ", s => " . $s . "\n";

    $flag = 0 if (($f < 1) || ($f > $n));
    $flag = 0 if (($t < 1) || ($t > $n));
    $flag = 0 if (($s < 1) || ($s > 30000));

    if ($flag == 1) { 
        print "im in";
        push(@information, @splitted_input);
        $counter++;
        print "counter => " . $counter . "\n";
    }
}

foreach my $subarr (@information) {
    print STDERR Dumper($subarr);
}
