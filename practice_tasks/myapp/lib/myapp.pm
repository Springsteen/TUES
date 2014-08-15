package myapp;
use Dancer ':syntax';
use DBI;
use Data::Dumper;

our $VERSION = '0.1';

sub connect_db {
	my $dbh = DBI->connect(
		"dbi:Pg:dbname=myapp_db",
		"martin",
		"Parola",
		{
			AutoCommit=>0,
			RaiseError=>1,
			PrintError=>1
		}
	);
	return $dbh;
};

any ['get', 'post'] => '/' => sub {
	if (request->method() eq "POST"){
		my $check = 0;
		my $dbh = connect_db();
		my $sth = $dbh->prepare("SELECT id,name,password FROM accounts 
									WHERE name = ? AND password = ?") or die $dbh->errstr;
		$sth->execute(params->{'username'}, params->{'password'}) or die $sth->errstr;
		if ($sth->rows() > 0) {
			session 'logged_in' => true;
			$check = 1;
		}
	    $sth->finish();
	    $dbh->disconnect();
		template 'home', {
			'msg' => $check,
			'err' => "Wrong username or password"
		};	
	}else{
		template 'home', {
			'msg' => 0
		};
	}
};


true;
