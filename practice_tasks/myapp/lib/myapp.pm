package myapp;
use Dancer ':syntax';
use DBI;
use Data::Dumper;

our $VERSION = '0.1';

my $current_user = '';

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
			$current_user = params->{'username'};
			$check = 1;
		}
	    $sth->finish();
	    $dbh->disconnect();
	    if ($check == 0) { 
			template 'home', {
				'msg' => $check,
				'err' => "Wrong username or password",
				'logout_url' => uri_for('/logout'),
				'types_url' => uri_for('/types')
			};
		}else{
			redirect '/types';	
		}
	}else{
		if (session 'logged_in') {
			redirect '/types';
		}else{
			template 'home', {
				'msg' => 0,
			};
		}
	}
};

get '/logout' => sub {
	if (session 'logged_in') {
		session->destroy();
		redirect '/';
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/types' => sub {
	if (session 'logged_in') {
		my $dbh = connect_db();
		if (request->method() eq "POST"){
			my $sth = $dbh->prepare("INSERT INTO types (name) values (?)") or die $dbh->errstr;	
			$sth->execute(params->{'type_name'}) or die $sth->errstr;
			$sth->finish();
			$dbh->commit or die	$dbh->errstr;
		}
		my $sth = $dbh->prepare("SELECT id,name FROM types") or die $dbh->errstr;
		$sth->execute() or die $sth->errstr;
		my $typesHash = $sth->fetchall_hashref('id');
		$sth->finish();
		$dbh->disconnect();

		template 'types', {
			'types' => $typesHash,
			'logout_url' => uri_for('/logout'),
			'logged' => 'true',
			'user' => $current_user
		};
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/types/:id' => sub {
	my $dbh = connect_db();
	if (request->method() eq "POST"){
		my $id = params->{'id'};
		my $sth = $dbh->prepare("UPDATE types SET name = ? WHERE id = $id") or die $dbh->errstr;	
		$sth->execute(params->{"new_type_name_$id"}) or die $sth->errstr;
		$sth->finish();
		$dbh->commit or die	$dbh->errstr;
		$dbh->disconnect();
		redirect '/types';
	}else{
		my $sth = $dbh->prepare("DELETE FROM types WHERE id = ?") or die $dbh->errstr;	
		$sth->execute(params->{'id'}) or die $sth->errstr;
		$sth->finish();
		$dbh->commit or die	$dbh->errstr;
		$dbh->disconnect();
		redirect '/types';
	}
};

true;
