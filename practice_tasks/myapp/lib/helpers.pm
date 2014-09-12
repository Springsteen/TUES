package helpers;
    use Encode qw(decode_utf8);

    sub ASSERT ($;$) {
        if ($_[0] == 0){
            debug $_[1] if (defined $_[1]);
            die; 
        }
    };

    sub makeDELETEQuery ($$$) {
        my ($dbh, $table, $id) = ($_[0], $_[1], $_[2]);
        my $sth = $dbh->prepare("DELETE FROM $table WHERE id = $id");
        $sth->execute();
        $sth->finish();
        $dbh->commit();
    };

    sub fetchTableColumnNames ($$;$) {
        my ($dbh, $table) = ($_[0], $_[1]);
        my $sth = $dbh->prepare("SELECT * FROM $table WHERE FALSE");
        $sth->execute();
        my $columnNames = $sth->{NAME};
        $sth->finish();
        shift($columnNames) if ((defined $_[2]) && ($_[2] == 1));
        return $columnNames;  
    };

    sub makeINSERTByGivenQuery ($$) {
        my ($dbh, $query) = ($_[0], $_[1]);
        my $sth = $dbh->prepare($query);
        $sth->execute();
        $sth->finish();
        $dbh->commit;
    };

    sub fetchHashSortedById($$){
        my ($dbh, $query) = ($_[0], $_[1]);
        my $sth = $dbh->prepare($query);
        $sth->execute();
        my $fetchedHash = $sth->fetchall_hashref('id');
        $sth->finish();
        return $fetchedHash;
    };

    sub countTableRows($$) {
        my $dbh = $_[0];
        my $table = $_[1];
        my $sth = $dbh->prepare("SELECT COUNT(*) FROM $table");
        $sth->execute();
        my @tableRows = $sth->fetchrow_array;
        $sth->finish();
        my $tableRowsCounted = int($tableRows[0]);
        return $tableRowsCounted;
    };

    sub buildSimpleSELECTQuery ($;$$$){
        my $table = $_[0];
        my ($columns, $limit, $offset) = ("*", 20, 0);
        $columns = $_[1] if (defined $_[1]);
        $limit = $_[2] if (defined $_[2]);
        $offset = $_[3] if (defined $_[3]);
        my $query = "SELECT ";
        if (ref($columns) eq "ARRAY"){
            foreach my $column (@$columns) {
                $query .= $column . ", ";
            }
            substr($query, -2) = "";
        }else{
            $query .= "*";
        }
        $query .= (" FROM " . $table . " LIMIT " . $limit . " OFFSET " . $offset);
        return $query;
    };

    sub associateColumnNamesWithTables ($$){
        my $columnNames = $_[0];
        my $table = $_[1];
        my $output = "";
        foreach my $column (@$columnNames) {
            $output .= ("$table." . $column . ", ");
        }
        substr ($output, -2) = "";
        return $output;
    };

    sub decodeDBHash ($$) {
        my $inputHash = $_[0];
        my $curr_lang = $_[1];
        foreach my $key ( sort (keys %$inputHash) ) {
            foreach my $subkey ( sort (keys ${$inputHash}{$key}) ) {
                if (substr($subkey, -2, 2) eq $curr_lang){
                ${$inputHash}{$key}{$subkey} = decode_utf8(${$inputHash}{$key}{$subkey});
                }
            }
        }
        return $inputHash;
    };

    sub checkUserRights ($) {
        my $rights = $_[0];
        my $admin = 1 if $rights & 4;
        my $write = 1 if $rights & 2;
        my $read = 1 if $rights & 1;
        return ($admin, $write, $read); 
    };

    sub validateDate ($) {
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
    };

1;