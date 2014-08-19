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

any ['post', 'get'] => '/' => sub {
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
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
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
		template 'exception';
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

any ['post', 'get'] => '/types' => sub {
	if (session 'logged_in') {
		my $dbh = connect_db();
		try {	
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
				'networks_url' => uri_for('/networks'),
				'logged' => 'true',
				'user' => $current_user
			};
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/types/:id' => sub {
	if (session 'logged_in'){
		my $dbh = connect_db();
		try {	
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
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};


any ['post', 'get'] => '/models' => sub {
	if (session 'logged_in') {
		my $dbh = connect_db();
		try {
			my $sth = $dbh->prepare("SELECT id, name FROM types") or die $dbh->errstr;
			$sth->execute() or die $sth->errstr;
			my $typesHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO models (name, type_id) values (?, ?)") or die $dbh->errstr;
				$sth->execute(params->{'model_name'}, findID('types', params->{'type_select'}));
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect '/models';
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
					'networks_url' => uri_for('/networks'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/models/:id' => sub {
	if (session 'logged_in'){
		my $dbh = connect_db();
		try {	
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
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/networks' => sub {
	if (session 'logged_in') {
		my $dbh = connect_db();
		try {
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO networks (name) values (?)") or die $dbh->errstr;	
				$sth->execute(params->{'network_name'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/networks';
			}else{
				my $sth = $dbh->prepare("SELECT id, name FROM networks") or die $dbh->errstr;
				$sth->execute() or die $sth->errstr;
				my $networksHash = $sth->fetchall_hashref('id');
				$sth->finish();
				$dbh->disconnect();
				template 'networks', {
					'networks' => $networksHash,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}catch{
			$dbh->disconnect();
			template 'exception';
		}; 
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/networks/:id' => sub {
		my $dbh = connect_db();
		try {	
			if (request->method() eq "POST"){
				my $id = params->{'id'};
				my $sth = $dbh->prepare("UPDATE networks SET name = ? WHERE id = $id") or die $dbh->errstr;	
				$sth->execute(params->{"new_network_name_$id"}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/networks';
			}else{
				my $sth = $dbh->prepare("DELETE FROM networks WHERE id = ?") or die $dbh->errstr;	
				$sth->execute(params->{'id'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/networks';
			}
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
};

true;
