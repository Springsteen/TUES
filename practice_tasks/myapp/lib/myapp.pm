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
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
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
				'net_devices_url' => uri_for('/network_devices'),
				'computers_url' => uri_for('/computers'),
				'parts_url' => uri_for('/parts'),
				'search_url' => uri_for('/search'),
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
			die if $sth->rows() < 1;
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
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
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
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
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
	if (session 'logged_in'){
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
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/network_devices' => sub {
	if (session 'logged_in') {
		my $dbh = connect_db();
		try {
			my $sth = $dbh->prepare("SELECT id, name FROM networks") or die $dbh->errstr;
			$sth->execute() or die $sth->errstr;
			die if $sth->rows() < 1;
			my $networksHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO network_devices (name, network_id) values (?, ?)") or die $dbh->errstr;
				$sth->execute(params->{'net_device_name'}, findID('networks', params->{'network_select'}));
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect '/network_devices';
			}else{
				$sth = $dbh->prepare("SELECT network_devices.id, 
											network_devices.name AS d_name, 
											networks.name AS n_name 
									FROM network_devices, networks 
									WHERE network_devices.network_id = networks.id");
				$sth->execute();
				my $netDevicesHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'net_devices.tt', {
					'net_devices' => $netDevicesHash,
					'networks' => $networksHash,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
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

any ['get', 'post'] => '/network_devices/:id' => sub {
	if (session 'logged_in'){	
		my $dbh = connect_db();
		try {	
			if (request->method() eq "POST"){
				my $id = params->{'id'};
				my $sth = $dbh->prepare("UPDATE network_devices SET name = ? WHERE id = $id") or die $dbh->errstr;	
				$sth->execute(params->{"new_net_device_name_$id"}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/network_devices';
			}else{
				my $sth = $dbh->prepare("DELETE FROM network_devices WHERE id = ?") or die $dbh->errstr;	
				$sth->execute(params->{'id'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/network_devices';
			}
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/computers' => sub {
	if (session 'logged_in') {
		my $dbh = connect_db();
		try {
			my $sth = $dbh->prepare("SELECT id, name FROM networks") or die $dbh->errstr;
			$sth->execute() or die $sth->errstr;
			die if $sth->rows() < 1;
			my $networksHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO computers (name, network_id) values (?, ?)") or die $dbh->errstr;
				$sth->execute(params->{'computer_name'}, findID('networks', params->{'network_select'}));
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect '/computers';
			}else{
				$sth = $dbh->prepare("SELECT computers.id, 
											computers.name AS c_name, 
											networks.name AS n_name 
									FROM computers, networks 
									WHERE computers.network_id = networks.id");
				$sth->execute();
				my $computersHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'computers.tt', {
					'computers' => $computersHash,
					'networks' => $networksHash,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
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

any ['get', 'post'] => '/computers/:id' => sub {
	if (session 'logged_in'){	
		my $dbh = connect_db();
		try {	
			if (request->method() eq "POST"){
				my $id = params->{'id'};
				my $sth = $dbh->prepare("UPDATE computers SET name = ? WHERE id = $id") or die $dbh->errstr;	
				$sth->execute(params->{"new_computer_name_$id"}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/computers';
			}else{
				my $sth = $dbh->prepare("DELETE FROM computers WHERE id = ?") or die $dbh->errstr;	
				$sth->execute(params->{'id'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/computers';
			}
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/parts' => sub {
	if (session 'logged_in'){
		my $dbh = connect_db();
		try {
			my $sth = $dbh->prepare("SELECT id, name FROM models") or die $dbh->errstr;
			$sth->execute() or die $sth->errstr;
			die if $sth->rows() < 1;
			my $modelsHash = $sth->fetchall_hashref('id');
			$sth->finish();
			$sth = $dbh->prepare("SELECT id, name FROM computers") or die $dbh->errstr;
			$sth->execute or die $sth->errstr;
			die if $sth->rows() < 1;
			my $computersHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				$sth = $dbh->prepare("INSERT INTO parts (name, model_id, computer_id, waranty) 
										values (?, ?, ?, ?)") or die $dbh->errstr;
				$sth->execute(params->{'part_name'}, 
							findID('models', params->{'model_select'}), 
							findID('computers', params->{'computer_select'}),
							params->{'part_waranty'});
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect(); 
				redirect '/parts';
			}else{
				$sth = $dbh->prepare("SELECT parts.id, parts.waranty, 
									parts.name AS p_name, 
									models.name AS m_name, 
									computers.name AS c_name 
									FROM parts, models, computers 
									WHERE computers.id = parts.computer_id 
									AND models.id = parts.model_id") or die $dbh->errstr;
				$sth->execute() or die $sth->errstr;
				my $partsHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'parts.tt', {
					'parts' => $partsHash,
					'models' => $modelsHash,
					'computers' => $computersHash,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				}			
			}
		}catch{	
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/parts/:id' => sub {
	if (session 'logged_in'){	
		my $dbh = connect_db();
		try {	
			if (request->method() eq "POST"){
				my $id = params->{'id'};
				my $sth = $dbh->prepare("UPDATE parts SET name = ?, waranty = ? WHERE id = $id") or die $dbh->errstr;	
				$sth->execute(params->{"new_part_name_$id"}, params->{"new_part_waranty_$id"}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/parts';
			}else{
				my $sth = $dbh->prepare("DELETE FROM parts WHERE id = ?") or die $dbh->errstr;	
				$sth->execute(params->{'id'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/parts';
			}
		}catch{
			$dbh->disconnect();
			template 'exception';
		};
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/search' => sub {
	# if (session 'logged_in') {
		my $dbh = connect_db();
		try {
			if (request->method() eq "POST"){
				my $db = params->{'select_db'} ;
				my $sth = $dbh->prepare("SELECT * FROM  $db
										WHERE name ~ ?") or die $dbh->errstr;
				$sth->execute("^".params->{'search_pattern'}) or die $sth->errstr;
				die if $sth->rows() < 1;
				my $searchHash = $sth->fetchall_arrayref();
				$sth = $dbh->column_info('','',$db,'');
				my $columnNames = $sth->fetchall_arrayref();
				$dbh->disconnect();
				template 'search.tt', {
					'query' => $searchHash,
					'column_names' => $columnNames,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				}
			}else{
				template 'search.tt', {
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				}
			}
		}catch{
			print STDERR "\n\n" . $_ . "\n\n";
			$dbh->disconnect();
			template 'exception';
		};
	# }else{
	# 	redirect '/';
	# }
};

true;