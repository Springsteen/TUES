use Spreadsheet::ParseExcel;
use DBI;
use utf8;
no warnings 'utf8';

sub ParseRegionDoc {
	$name = @_[0]; 
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
				if ( ($iC == 0) && ($iR != 0) ) {
					# print "Name => " . $oWkC->Value . "\n" if($oWkC);
					push(@nameArray, $oWkC->Value);
					push(@nameArray, $oWkS->{Cells}[$iR][$iC+1]->Value);
				}
			}
		}
	}
}

sub PrepareFilesForParsing {
	`unzip Ekatte.zip`;
	`unzip Ekatte_xls.zip`;
}

sub RemoveUnneededResources {
	`rm *.xls *.txt Ekatte_xls.zip`;
}

our @nameArray;
our $dbName = 'testdb';
our $psqlUser = 'martin';
our $psqlPassword = 'Parola';
my $dbHandler = DBI->connect("dbi:Pg:dbname=$dbName",
								$psqlUser,
								$psqlPassword,
								{AutoCommit=>0,
									RaiseError=>1,
									PrintError=>1
								}
							);
my $docName = 'Ek_reg2.xls';
PrepareFilesForParsing();
ParseRegionDoc($docName);
for (my $e = 0; $e < scalar @nameArray; $e+=2) {
	my $statementHandler = $dbHandler->prepare("INSERT INTO test_table
	                       (Name, Region)
	                        values
	                       (?, ?)");
	$statementHandler->execute(@nameArray[$e], @nameArray[$e+1]) or die $DBI::errstr;
	$statementHandler->finish();
}
$dbHandler->commit or die $DBI::errstr;
RemoveUnneededResources();












