package helpers;

sub connect_db {
    my $dbh;
    $dbh = DBI->connect(
        "dbi:Pg:dbname=myapp_db",
        "martin",
        "Parola",
        {
            AutoCommit=>0,
            RaiseError=>1,
            PrintError=>0
        }
    ) or die;
    return $dbh;
};

sub checkUserRights {
    my $rights = $_[0];
    my $admin = 1 if $rights & 4;
    my $write = 1 if $rights & 2;
    my $read = 1 if $rights & 1;
    return ($admin, $write, $read); 
};

sub findIDModel {
    my $dbh;
    my $table = $_[0];
    my $name_pattern = $_[1];
    $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id FROM $table WHERE name_en = '$name_pattern'");
    $sth->execute() ;
    if ($sth->rows() == 1){
        my @a = $sth->fetchrow_array;
        $sth->finish();
        $dbh->disconnect();
        return $a[0];
    }else{
        $sth->finish();
        $dbh->disconnect();
        return -1
    }
};

sub findID {
    my $dbh;
    my $table = $_[0];
    my $name_pattern = $_[1];
    $dbh = connect_db();
    my $sth = $dbh->prepare("SELECT id FROM $table WHERE name = '$name_pattern'");
    $sth->execute() ;
    if ($sth->rows() == 1){
        my @a = $sth->fetchrow_array;
        $sth->finish();
        $dbh->disconnect();
        return $a[0];
    }else{
        $sth->finish();
        $dbh->disconnect();
        return -1
    }
};

sub validateDate {
    my $str = $_[0];
    my $year = int(substr $str, 0, 4);
    my $month = int(substr $str, 5, 2);
    my $day = int(substr $str, 8, 2);
    return -1 if ($year < 2014 or $year > 2030);
    return -1 if ($month < 1 or $month > 12);
    return -1 if ($day < 1 or $day > 31);
    return 1
};

sub getFields {
    my @fields = $_[0];
    my (@output, @check);
    for (my $i = 0; $i < scalar @{$fields[0]}; $i++) {
        @check = split('_', $fields[0][$i]);
        push(@output, $fields[0][$i]) if !($check[-1] eq "id");
        @check = undef; 
    }
    return @output;
}

true;