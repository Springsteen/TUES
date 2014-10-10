use strict;
use warnings;

use Data::Dumper;

my $N;

do
{
    $N = <STDIN>;
    $N = int($N);
}while(($N <= 1) || ($N >= 100));

my @input_words;
print "N =>" . $N . "\n";

for (my $counter = 0; $counter < $N; $counter++) 
{
    my $curr_word = <STDIN>;
    push(@input_words, $curr_word);
}

print Dumper(@input_words);

my @symbols = ('a'..'z');
my @curr_symbols;
# print Dumper(@symbols);

for (my $counter = 0; $counter < scalar @symbols; $counter++) 
{

    # print $symbols[$counter];    
    my $index = 0;
    while( $index < scalar @symbols) 
    {
        if(($index + $counter) > (scalar @symbols))
        {
            $curr_symbols[$index] = $symbols[($index + $counter) - (scalar @symbols)];
        }
        else
        {
            $curr_symbols[$index] = $symbols[$index + $counter];
        }
        $index++;
    }
    foreach (@curr_symbols) 
    {
        print;
    }
    print "\n";
}