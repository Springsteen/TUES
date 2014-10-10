use strict;
use warnings;

use Data::Dumper;

my ($n, $m, $input, $flag, @splitted_input);
$flag = 0;

while (!$flag)
{
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

while ($counter < $m)
{
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

    if ($flag == 1) 
    { 
        print "im in";
        push(@information, [@splitted_input]);
        $counter++;
        print "counter => " . $counter . "\n";
    }
}

my %graph;
my @parent=();

sub add_edge 
{
    my ($n1, $n2, $weight) = @_;
    if (defined $graph{$n1}{$n2})
    {
        if($graph{$n1}{$n2} > $weight){
            $graph{$n1}{$n2} = $weight;
            $graph{$n2}{$n1} = $weight;
        }
    }
    else
    {
        $graph{$n1}{$n2} = $weight;
        $graph{$n2}{$n1} = $weight;
    }
}

sub show_edges 
{
    foreach my $n1 (keys %graph) 
    {
        foreach my $n2 (keys %{$graph{$n1}}) 
        {
            print "$n1 <-> $n2 -> $graph{$n1}{$n2}\n";
        }
    }
}

foreach my $subarr (@information) 
{
    add_edge(${$subarr}[0], ${$subarr}[1], ${$subarr}[2]);
}

show_edges();

# sub compere
# {
#     my ($node)= @_;
#     if($parent[$node] == $node)
#     {
#         return $node;
#     }
#     return $parent[$node] = compere($parent[$node]);
# }

# sub solve 
# {

# }

# solve();


