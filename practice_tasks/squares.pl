# use strict;
# IS NOT READY !!!
my $n = 0;
while (($n < 2 ) || ($n > 3)){
	$n = <>;
}

sub uniq {
    my %seen;
    grep !$seen{$_}++, @_;
}

my @arr;
my $zeroes = 0;
my @signs;
for (my $i = 0; $i < $n**$n; $i++) {
	my $var = <>;
	my @sub_arr = split(/\s/, $var);
	push(@arr, @sub_arr);
	foreach my $x (@sub_arr) {
		if ( $x eq "0"){
			$zeroes++;
		}else{
			push(@signs, $x);
		}
	};		
}
print $zeroes . "\n";

@signs = uniq(@signs);
# foreach my $x (@signs) {
# 	# body...
# print $x . "\n";
# }

while($zeroes > 0){
	for (my $i = 0; $i < $n**$n; $i++) {
		for (my $k = 0; $k < $n**$n; $k++) {
			if ($arr[$i][$k] eq "0"){	
				my $is_there = 0;
				my $current_sign;
				foreach my $sign (@signs) {
					$current_sign = $sign;
					for (my $q = 0; $q < $n**$n; $q++) {
						if ($arr[$i][$q] eq $sign){
							$is_there = 1;
						}
						if($arr[$q][$k] eq $sign){
							$is_there = 1;
						}

					}
					break if($is_there == 0);
				}
				$arr[$i][$k] = $current_sign if ($is_there == 0);	
			}
		}
	}
}
