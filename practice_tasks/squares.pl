use strict;
use warnings;

my $MAX_NUMBER = <>;

while((int($MAX_NUMBER) < 2) && (int($MAX_NUMBER) > 3)){
  $MAX_NUMBER = <>;
}
$MAX_NUMBER *= $MAX_NUMBER;
my @RANGE = (1 .. $MAX_NUMBER);
my $MAX_ATTEMPS = 100;

my @GRID;
my @DECIDED;
my @arr;
for (my $i = 0; $i < $MAX_NUMBER; $i++) {
  my $var = <>;
  my @sub_arr = split(/\s/, $var);
    for (my $z = 0; $z < $MAX_NUMBER; $z++) {
      if ($sub_arr[$z] ne "0"){
        $GRID[$i][$z] = {int($sub_arr[$z]) => 1};
      }
    }
}

for (my $i = 0; $i < $MAX_NUMBER; $i++) {
  for (my $j = 0; $j < $MAX_NUMBER; $j++) {
    if (exists($GRID[$i][$j])) {
      push(@DECIDED, "$i,$j");
    }else {
      my %possibilities = map { $_ => 1 } @RANGE;
      $GRID[$i][$j] = \%possibilities;
    }
  }
}

print "Original grid:\n";
print_grid();
print "\n";

my $attempt = 0;
my @decided_last_attempt = @DECIDED;
while (scalar @DECIDED < $MAX_NUMBER**2 && scalar @decided_last_attempt > 0
  && $attempt < $MAX_ATTEMPS) {
  $attempt++;
  my @decided_this_attempt;
  foreach my $position (@decided_last_attempt) {
    my ($i, $j) = split(',', $position, 2);
    push(@decided_this_attempt, forbid($i, $j));
  }
  print "Attempt $attempt:\n";
  print_grid();
  print "\n";
  push(@DECIDED, @decided_this_attempt);
  @decided_last_attempt = @decided_this_attempt;
}

sub forbid {
  my ($i, $j) = @_;
  my $possibilities = $GRID[$i][$j];
  my @decided_positions;

  unless (scalar keys %{$possibilities} == 1) {
    print "/!\\ Attempting to forbid undecided value using position ($i,$j)\n";
    print "/!\\ Remaining possibilities: ".join(' ', sort keys %{$possibilities})."\n";
  return;
  }
  my $value = _position_value($i, $j);
  for (my $jj = 0; $jj < $MAX_NUMBER; $jj++) {
    my $p = $GRID[$i][$jj];
    unless ($jj == $j || scalar keys %{$p} == 1) {
      delete $p->{$value};
      if (scalar keys %{$p} == 1) {
        push(@decided_positions, "$i,$jj");
      }
    }
  }

  for (my $ii = 0; $ii < $MAX_NUMBER; $ii++) {
    my $p = $GRID[$ii][$j];
    unless ($ii == $i || scalar keys %{$p} == 1) {
      delete $p->{$value};
      if (scalar keys %{$p} == 1) {
        push(@decided_positions, "$ii,$j");
      }
    }
  }
  
  my $min_i = sqrt($MAX_NUMBER) * int($i / sqrt($MAX_NUMBER));
  my $max_i = $min_i + sqrt($MAX_NUMBER);
  my $min_j = sqrt($MAX_NUMBER) * int($j / sqrt($MAX_NUMBER));
  my $max_j = $min_j + sqrt($MAX_NUMBER);
  for (my $ii = $min_i; $ii < $max_i; $ii++) {
    for (my $jj = $min_j; $jj < $max_j; $jj++) {
      my $p = $GRID[$ii][$jj];
      unless (($ii == $i && $jj == $j) || scalar keys %{$p} == 1) {
        delete $p->{$value};
        if (scalar keys %{$p} == 1) {
          push(@decided_positions, "$ii,$jj");
        }
      }
    }
  }
  return @decided_positions;
}

sub print_grid {
  for (my $i = 0; $i < $MAX_NUMBER; $i++) {
    print "\n" if ($i != 0 && $i % sqrt($MAX_NUMBER) == 0);
    for (my $j = 0; $j < $MAX_NUMBER; $j++) {
      print "\t" if ($j != 0 && $j % sqrt($MAX_NUMBER) == 0);
      my $possibilities = $GRID[$i][$j];
      if (scalar keys %{$possibilities} == 1) {
        print _position_value($i, $j);
      }
      else {
        print "-";
      }
      print "\t";
    }
    print "\n";
  }
}

sub _position_value {
  my ($i, $j) = @_;
  my $possibilities = $GRID[$i][$j];

  unless (scalar keys %{$possibilities} == 1) {
    print "/!\\ Attempting to read undecided value using position ($i,$j)\n";
    print "/!\\ Remaining possibilities: ".join(' ', sort keys %{$possibilities})."\n";
    return;
  }
  my $k = (keys %{$possibilities})[0];
  return $k;
}
