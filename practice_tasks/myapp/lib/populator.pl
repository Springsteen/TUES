use strict;
use warnings;

use DBI;
use Data::Dumper;
use Try::Tiny;


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

sub populateTable($$$$){
    my $dbh = $_[0] if defined $_[0];
    my $table_name = $_[1] if defined $_[1];
    my $keyword_en = $_[2] if defined $_[2];
    my $keyword_bg = $_[3] if defined $_[3];

    my $sth;
    foreach my $index (1..200000) {
        print $index . " " . ($keyword_en . $index) . " " . ($keyword_bg . $index) . "\n"; 
        $sth = $dbh->prepare("INSERT INTO $table_name (name_en, name_bg) values (?, ?)");
        $sth->execute(($keyword_en . $index),($keyword_bg . $index));
        $sth->finish();
    }

    $dbh->commit;
};

try{
    my $dbh = connect_db();
    
    # print Dumper($dbh);

    # populateTable($dbh, "types", "DDR", "ДДР");
    # populateTable($dbh, "networks", "net", "мрежа");
    # populateTable($dbh, "models", "model", "модел");
    # populateTable($dbh, "network_devices", "device", "устройство");
    # populateTable($dbh, "computers", "computer", "компютър");

    $dbh->disconnect();
}catch{

    print "An error occured\n";
    print "More info\n";
    print "=========================\n";
    print $_;
    print "=========================\n";

};