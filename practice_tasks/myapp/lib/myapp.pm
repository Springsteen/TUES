package myapp;
use Dancer ':syntax';
use DBI;
use Data::Dumper;
use Try::Tiny;

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
			PrintError=>0
		}
	);
	return $dbh;
};

sub findID {
	my $table = $_[0];
	my $name_pattern = $_[1];
	my $dbh = connect_db();
	my $sth = $dbh->prepare("SELECT id FROM $table WHERE name = '$name_pattern'");
	$sth->execute() or die $sth->errstr;
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

any ['get', 'post'] => '/' => sub {
	my $dbh = connect_db();
	try {	
		if (request->method() eq "POST"){
			my $check = 0;
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
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models')
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
	}catch{
		$dbh->disconnect();
		template "exception";
	};
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
	my $dbh = connect_db();
	try {	
		if (session 'logged_in') {
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
				'types_url' => uri_for('/types'),
				'models_url' => uri_for('/models'),
				'logged' => 'true',
				'user' => $current_user
			};
		}else{
			redirect '/';
		}
	}catch{
		$dbh->disconnect();
		template "exception";
	};
};

any ['post', 'get'] => '/types/:id' => sub {
	my $dbh = connect_db();
	try {	
		if (session 'logged_in'){
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
		}else{
			redirect '/';
		}
	}catch{
		$dbh->disconnect();
		template "exception";
	};
};


any ['post', 'get'] => '/models' => sub {
	my $dbh = connect_db();
	try {
		if (session 'logged_in') {
			my $sth = $dbh->prepare("SELECT id, name FROM types") or die $dbh->errstr;
			$sth->execute() or die $sth->errstr;
			my $typesHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO models (name, type_id) values (?, ?)") or die $dbh->errstr;
				$sth->execute(params->{'model_name'}, findID('types', params->{'type_select'}));
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$sth = $dbh->prepare("SELECT models.id, models.name AS m_name, types.name AS t_name FROM models, types WHERE models.type_id = types.id");
				$sth->execute();
				my $modelsHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'models', {
					'types' => $typesHash,
					'models' => $modelsHash,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'logged' => 'true',
					'user' => $current_user
				};
			}else{
				$sth = $dbh->prepare("SELECT models.id, models.name AS m_name, types.name AS t_name FROM models, types WHERE models.type_id = types.id");
				$sth->execute();
				my $modelsHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'models', {
					'types' => $typesHash,
					'models' => $modelsHash,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		$dbh->disconnect();
		template "exception";
	};
};

any ['post', 'get'] => '/models/:id' => sub {
	my $dbh = connect_db();
	try {	
		if (session 'logged_in'){
			if (request->method() eq "POST"){
				my $id = params->{'id'};
				my $sth = $dbh->prepare("UPDATE models SET name = ? WHERE id = $id") or die $dbh->errstr;	
				$sth->execute(params->{"new_model_name_$id"}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/models';
			}else{
				my $sth = $dbh->prepare("DELETE FROM models WHERE id = ?") or die $dbh->errstr;	
				$sth->execute(params->{'id'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/models';
			}
		}else{
			redirect '/';
		}
	}catch{
		$dbh->disconnect();
		template "exception";
	};
};

true;
