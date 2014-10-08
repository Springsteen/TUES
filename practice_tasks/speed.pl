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
        push(@information, [@splitted_input]);
        $counter++;
        print "counter => " . $counter . "\n";
    }
}

my %graph;

sub add_edge {
    my ($n1, $n2) = @_;
    $graph{$n1}{$n2} = 1;
    $graph{$n2}{$n1} = 1;
}

sub show_edges {
    foreach my $n1 (keys %graph) {
        foreach my $n2 (keys %{$graph{$n1}}) {
            print "$n1 <-> $n2\n";
        }
    }
}

# print "info length =>" . (scalar @information) . "\n";

# print "Dumped =>" . Dumper(@information) . "\n";
# print $information[4];

foreach my $subarr (@information) {
    add_edge(${$subarr}[0], ${$subarr}[1]);
}

show_edges();


