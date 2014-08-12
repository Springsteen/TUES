use Spreadsheet::ParseExcel;
use DBI;
use utf8;
no warnings 'utf8';

sub ParseDoc {
	$name = @_[0]; 
	$startRow = @_[1];
	my $oExcel = new Spreadsheet::ParseExcel;

	my $oBook = $oExcel->Parse($name);
	my($iR, $iC, $oWkS, $oWkC);
	for(my $iSheet=0; $iSheet < $oBook->{SheetCount} ; $iSheet++) {
		$oWkS = $oBook->{Worksheet}[$iSheet];
		# print "--------- SHEET:", $oWkS->{Name}, "\n";
		for(my $iR = $oWkS->{MinRow} ; 
				defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow} ; $iR++) {
			for(my $iC = $oWkS->{MinCol} ;
							defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol} ; $iC++) {
				$oWkC = $oWkS->{Cells}[$iR][$iC];
				if ( ($iC == 0) && ($iR > $startRow) ) {
					# print "Name => " . $oWkC->Value . "\n" if($oWkC);
					# push(@nameArray, $oWkC->Value);
					foreach my $i (@columnsNeeded) {
						push(@nameArray, $oWkS->{Cells}[$iR][$i]->Value);
					}
				}
			}
		}
	}
}

sub Initialize {
	`unzip Ekatte.zip`;
	`unzip Ekatte_xls.zip`;
	$dbHandler = DBI->connect(
		"dbi:Pg:dbname=$dbName",
		$psqlUser,
		$psqlPassword,
		{
			AutoCommit=>0,
			RaiseError=>1,
			PrintError=>1
		}
	);
}

sub Deinitialize {
	`rm *.xls *.txt Ekatte_xls.zip`;
} 

our $dbHandler;
our @nameArray;
our $dbName = 'testdb';
our $psqlUser = 'martin';
our $psqlPassword = 'Parola';
our @columnsNeeded;
my $regionDocName = 'Ek_reg2.xls';
my $areaDocName = 'Ek_obl.xls';
my $munDocName = 'Ek_obst.xls';
my $locationDocName = 'Ek_atte.xls';

my @table_names = ('region', 'area', 'municipality', 'location');

Initialize();

for (my $var = 0; $var < scalar @table_names; $var++) {
	my $table_name = $table_names[$var];
	my $statementHandler = $dbHandler->prepare(qq(SELECT * FROM $table_name));
	#print $table_names[$var] . "\n";
	$statementHandler->execute() or die $DBI::errstr;
	while(my @row = $statementHandler->fetchrow_array()) {
		my $statementHandler1 = $dbHandler->prepare(qq(UPDATE $table_name
	    	                   SET existence = FALSE
	    	                   WHERE name = '$row[0]'));
		$statementHandler1->execute() or die $DBI::errstr;
		$statementHandler1->finish();
	}
	$dbHandler->commit or die $DBI::errstr;
}



@columnsNeeded = (0, 1);
ParseDoc($regionDocName, 0);
for (my $e = 0; $e < scalar @nameArray; $e+=2) {
	my $statementHandler = $dbHandler->prepare("SELECT * FROM region
	                       WHERE name = ?");
	$statementHandler->execute($nameArray[$e+1]) or die $DBI::errstr;
	if ($statementHandler->rows()==0) {

		$statementHandler = $dbHandler->prepare("INSERT INTO region
	    	                   (name, region_name, existence)
	        	                values
	            	           (?, ?, ?)");
		$statementHandler->execute($nameArray[$e+1], $nameArray[$e], 'TRUE') or die $DBI::errstr;
		$statementHandler->finish();
	}else{
		$statementHandler = $dbHandler->prepare("UPDATE region
	    	                   SET region_name = ?, existence = ?
	        	               WHERE name = ?");
		$statementHandler->execute($nameArray[$e], 'TRUE', $nameArray[$e+1]) or die $DBI::errstr;
		$statementHandler->finish();
	}
}
$dbHandler->commit or die $DBI::errstr;
undef @nameArray, @columnsNeeded;

@columnsNeeded = (0, 2, 3);
ParseDoc($areaDocName, 0);
for (my $e = 0; $e < scalar @nameArray; $e+=3) {
	my $statementHandler = $dbHandler->prepare("SELECT * FROM area
	                       WHERE name = ?");
	$statementHandler->execute($nameArray[$e+1]) or die $DBI::errstr;
	if ($statementHandler->rows()==0) {
		$statementHandler = $dbHandler->prepare("INSERT INTO area
		                       (name, region, area_abbreviation, existence)
		                        values
		                       (?, ?, ?, ?)");
		$statementHandler->execute(@nameArray[$e+1], @nameArray[$e+2], @nameArray[$e], 'TRUE') or die $DBI::errstr;
		$statementHandler->finish();
	}else{
		$statementHandler = $dbHandler->prepare("UPDATE area
	    	                   SET region = ?, area_abbreviation = ?, existence = ?
	        	               WHERE name = ?");
		$statementHandler->execute($nameArray[$e+2], $nameArray[$e], 'TRUE', $nameArray[$e+1]) or die $DBI::errstr;
		$statementHandler->finish();
	}
}
$dbHandler->commit or die $DBI::errstr;
undef @nameArray, @columnsNeeded;

@columnsNeeded = (0, 2);
ParseDoc($munDocName, 0);
for (my $e = 0; $e < scalar @nameArray; $e+=2) {
	my $statementHandler = $dbHandler->prepare("SELECT * FROM municipality
	                       WHERE name = ?");
	$statementHandler->execute($nameArray[$e+1]) or die $DBI::errstr;
	if ($statementHandler->rows()==0) {
		$statementHandler = $dbHandler->prepare("INSERT INTO municipality
		                       (name, mun_abbreviation, existence)
		                        values
		                       (?, ?, ?)");
		$statementHandler->execute(@nameArray[$e+1], @nameArray[$e], 'TRUE') or die $DBI::errstr;
		$statementHandler->finish();
	}else{
		$statementHandler = $dbHandler->prepare("UPDATE municipality
	    	                   SET mun_abbreviation = ?, existence = ?
	        	               WHERE name = ?");
		$statementHandler->execute($nameArray[$e], 'TRUE', $nameArray[$e+1]) or die $DBI::errstr;
		$statementHandler->finish();	
	}
}
$dbHandler->commit or die $DBI::errstr;
undef @nameArray, @columnsNeeded;

@columnsNeeded = (2, 3, 4);
ParseDoc($locationDocName, 1);
for (my $e = 0; $e < scalar @nameArray; $e+=3) {
	print @nameArray[$e] . " " . @nameArray[$e+1] . " " . @nameArray[$e+2] . " \n"; 	
	my $statementHandler = $dbHandler->prepare("SELECT * FROM location
	                       WHERE name = '$nameArray[$e]' AND area = '$nameArray[$e+1]' AND municipality = '$nameArray[$e+2]' ");
	$statementHandler->execute() or die $DBI::errstr;
	if ($statementHandler->rows()==0) {
		my $statementHandler = $dbHandler->prepare("INSERT INTO location
		                       (name, area, municipality, existence)
		                        values
		                       (?, ?, ?, ?)");
		$statementHandler->execute(@nameArray[$e], @nameArray[$e+1], @nameArray[@e+2], 'TRUE') or die $DBI::errstr;
		$statementHandler->finish();
	}else{
		$statementHandler = $dbHandler->prepare("UPDATE location
	    	                   SET area = '$nameArray[$e+1]', municipality = '$nameArray[$e+2]', existence = TRUE
	        	               WHERE name = '$nameArray[$e]'");
		$statementHandler->execute() or die $DBI::errstr;
		$statementHandler->finish();	

	}
}
$dbHandler->commit or die $DBI::errstr;
undef @nameArray, @columnsNeeded;

Deinitialize();












