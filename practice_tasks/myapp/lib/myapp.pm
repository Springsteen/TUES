package myapp;
use Dancer ':syntax';
use DBI;
use Data::Dumper;
use Try::Tiny;
use Math::Round;
use Digest::MD5 qw(md5 md5_hex md5_base64);	
use String::Random qw(random_string);
use Dancer::Plugin::Email;

our $VERSION = '0.1';

my $current_user = '';
my $user_is_admin = 0; 

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
	);
	return $dbh;
};

sub findID {
	my $dbh;
	my $table = $_[0];
	my $name_pattern = $_[1];
	$dbh = connect_db();
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

any ['post', 'get'] => '/' => sub {
	my $dbh;
	try {	
		$dbh = connect_db();
		if (request->method() eq "POST"){
			my $check = 0;
			my $sth = $dbh->prepare("SELECT id,name,password FROM accounts 
										WHERE name = ? AND password = ?") or die $dbh->errstr;
			$sth->execute(params->{'username'}, md5_base64(params->{"password"}, params->{"username"})) or die $sth->errstr;
			if ($sth->rows() > 0) {
				session 'logged_in' => true;
				$current_user = params->{'username'};
				$check = 1;
			}
		    $sth->finish();
		    if ($check == 0) { 
		    	$dbh->disconnect();
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
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
				};
			}else{
				$sth = $dbh->prepare("SELECT active, rights FROM accounts 
										WHERE name = ?") or die $dbh->errstr;
				$sth->execute(params->{'username'}) or die $sth->errstr;
				$check = $sth->fetchrow_hashref() or die $sth->errstr;
				$sth->finish();
				$dbh->disconnect();
				$user_is_admin = 1 if ($check->{'rights'} >= 4 && $check->{'rights'} <= 6); 
				if ($check->{"active"} == 0){
					redirect '/confirm_account';
				}else{
					redirect '/types';	
				}
			}
		}else{
			$dbh->disconnect() or die $dbh->errstr;

			if (session 'logged_in') {
				redirect '/types';
			}else{
				template 'home', {
					'msg' => 0,
				};
			}
		}
	}catch{
		try {
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['post', 'get'] => '/user_panel' => sub {
	my $dbh;
	try {
		if (session 'logged_in'){
			$dbh = connect_db();
			my $sth = $dbh->prepare("SELECT * FROM accounts 
									WHERE name = ?") or die $dbh->errstr;
			$sth->execute($current_user) or die $sth->errstr;
			my $user = $sth->fetchrow_hashref() or die $sth->errstr;
			$sth->finish();
			my $active = "yes";
			$active = "no" if ($user->{"active"} == 0);
			if (request->method() eq "POST"){
				if ((md5_base64(params->{"old_pass"}, $current_user) eq $user->{"password"}) &&
					(params->{"new_pass_1"} eq params->{"new_pass_2"})){
					$sth = $dbh->prepare("UPDATE accounts SET
										password = ? WHERE name = ?") or die $dbh->errstr;
					$sth->execute(md5_base64(params->{"new_pass_1"}, $current_user), $current_user) or die $sth->errstr;
					$sth->finish();
					$dbh->commit or die $dbh->errstr;
					$dbh->disconnect();

					template 'user_panel', {
						'user' => $user->{"name"},
						'mail' => $user->{"mail"}, 
						'active' => $active,
						'msg' => "Your password was changed",
						'logout_url' => uri_for('/logout'),
						'logged' => 'true',
						'types_url' => uri_for('/types'),
						'models_url' => uri_for('/models'),
						'networks_url' => uri_for('/networks'),
						'net_devices_url' => uri_for('/network_devices'),
						'computers_url' => uri_for('/computers'),
						'parts_url' => uri_for('/parts'),
						'manuals_url' => uri_for('/manuals'),
						'search_url' => uri_for('/search'),
					};
				}
			}else{
				$dbh->disconnect();
				template 'user_panel', {
					'user' => $user->{"name"},
					'mail' => $user->{"mail"}, 
					'active' => $active,
					'logout_url' => uri_for('/logout'),
					'logged' => 'true',
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try {
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};	
};

any ['post', 'get'] => '/restore_password' => sub {
	my $dbh;
	try {
		if (session 'logged_in'){
			redirect '/';
		}else{
			$dbh = connect_db();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("SELECT name, active FROM accounts
									WHERE mail = ?") or die $dbh->errstr;
				$sth->execute(params->{"mail"}) or die $sth->errstr;
				die if $sth->rows <= 0;
				my $row = $sth->fetchrow_hashref() or die $sth->errstr;
				if ($row->{"active"} == 0) {
					$sth->finish();
					$dbh->disconnect();
					template 'restore_password', {
						err => 1
					};
				}else{
					my $hash = $sth->fetchrow_hashref() or die $sth->errstr;
					my $user = $hash->{"name"};
					$sth->finish();
					$sth = $dbh->prepare("UPDATE accounts 
										SET password = ? 
										WHERE mail = ? ") or die $dbh->errstr;
					my $new_pass = random_string("..........");
					$sth->execute(md5_base64($new_pass,$user), params->{"mail"}) or die $sth->errstr;
					$sth->finish();
					$dbh->commit or die $dbh->errstr;
					$dbh->disconnect();
					email {
						to => params->{"mail"},
						from => 'konkokodon@abv.bg',
						subject => 'new password',
						message => $new_pass
					};
					template 'restore_password', {
						'success' => 1 
					};
				}
			}else{
				$dbh->disconnect();
				template 'restore_password';
			}
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['post', 'get'] => '/register' => sub {
	my $dbh;
	try{
		if (session 'logged_in'){
			redirect '/';	
		}else{
			$dbh = connect_db();
			if (request->method() eq "POST"){
				my $check = (params->{"password_1"} eq params->{"password_2"});
				die if !$check;
				$check = 1;
				my $sth = $dbh->prepare("SELECT * FROM accounts WHERE
										name = ?") or die $dbh->errstr;
				$sth->execute(params->{"username"}) or die $sth->errstr;
				$check = 0 if $sth->rows() != 0;
				$sth->finish();
				if ($check) {
					my $confirm_code = random_string("..........");
					$sth = $dbh->prepare("INSERT INTO accounts (name, password, mail, confirm_code, active) 
										values (?, ?, ?, ?, ?)") or die $sth->errstr;
					$sth->execute(params->{"username"}, md5_base64(params->{"password_1"}, params->{"username"}), 
								params->{"mail"}, $confirm_code, "FALSE") or die $sth->errstr;
					$sth->finish();
					$dbh->commit or die $dbh->errstr;
					$dbh->disconnect();
					email {
				        to => params->{"mail"},
				        from => 'konkokodon@abv.bg',
				        subject => 'email confirmation code',
				        message => $confirm_code
				    };

					template 'home', {
						'success' => "You're account has been created"
					};
				}else{
					$dbh->disconnect();
					template 'register', {
						'err' => "There is another user with that name"
					};
				}
			}else{
				$dbh->disconnect();
				template 'register';
			}
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['post', 'get'] => '/confirm_account' => sub {
	my $dbh;
	try{
		if(session 'logged_in') {
			$dbh = connect_db();
			my $sth = $dbh->prepare("SELECT * FROM accounts WHERE
										name = ? AND active = FALSE") or die $dbh->errstr;
			$sth->execute($current_user) or die $sth->errstr;
			if ($sth->rows() < 1) {
				$sth->finish();
				$dbh->disconnect();
				redirect '/';
			}
			$sth->finish(); 
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("SELECT confirm_code FROM accounts WHERE
										name = ? AND active = FALSE") or die $dbh->errstr;
				$sth->execute($current_user) or die $sth->errstr;
				my $code = $sth->fetchrow_hashref() or die $sth->errstr;
				$sth->finish();
				if ($code->{"confirm_code"} eq params->{"code"}){
					my $sth = $dbh->prepare("UPDATE accounts SET active = TRUE
											WHERE name = '$current_user'") or die $dbh->errstr;
					$sth->execute() or die $sth->errstr;
					$sth->finish();
					$dbh->commit or die $dbh->errstr;
					$dbh->disconnect();
					redirect "/"
				}else{
					$dbh->disconnect();
					template 'confirm_account', {
						'err' => "Wrong confirmation code."
					};		
				}
			}else{
				$dbh->disconnect();
				template 'confirm_account', {
					'msg' => "You're e-mail address isn't activated. 
								You may use the application but some options
								won't be available until you confirm it."
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

get '/logout' => sub {
	if (session 'logged_in') {
		session->destroy();
		$current_user = "";
		$user_is_admin = 0;
		redirect '/';
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/types' => sub {
	my $dbh;
	try {	
		if (session 'logged_in') {
			$dbh = connect_db();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO types (name) values (?)") or die $dbh->errstr;	
				$sth->execute(params->{'type_name'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
			}
			my ($pages, $offset, $sth);
			if (!params->{'offset'}){
				$offset = 0;
			}else{
				$offset = int(params->{'offset'})-1;
			}
			$sth = $dbh->prepare("SELECT * FROM types");
			$sth->execute() or die $sth->errstr;
			$sth->finish(); 
			$pages =  int(($sth->rows()) / 10);
			$pages++ if ($sth->rows % 10) != 0;
			$sth = $dbh->prepare("SELECT id,name FROM types LIMIT 10 OFFSET ?") or die $dbh->errstr;
			$sth->execute(($offset)*10) or die $sth->errstr;
			my $typesHash = $sth->fetchall_hashref('id');
			$sth->finish();
			$dbh->disconnect();

			template 'types', {
				'types' => $typesHash,
				'pages' => $pages,
				'curr_page' => $offset+1,
				'logout_url' => uri_for('/logout'),
				'types_url' => uri_for('/types'),
				'models_url' => uri_for('/models'),
				'networks_url' => uri_for('/networks'),
				'net_devices_url' => uri_for('/network_devices'),
				'computers_url' => uri_for('/computers'),
				'parts_url' => uri_for('/parts'),
				'search_url' => uri_for('/search'),
				'manuals_url' => uri_for('/manuals'),
				'logged' => 'true',
				'user' => $current_user
			};
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['post', 'get'] => '/types/:id' => sub {
	my $dbh;
	try {	
		if (session 'logged_in'){
			$dbh = connect_db();
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
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};


any ['post', 'get'] => '/models' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			my $sth = $dbh->prepare("SELECT id, name FROM types") or die $dbh->errstr;
			$sth->execute() or die $sth->errstr;
			die if $sth->rows() < 1;
			my $typesHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				$sth = $dbh->prepare("INSERT INTO models (name, type_id) values (?, ?)") or die $dbh->errstr;
				$sth->execute(params->{'model_name'}, findID('types', params->{'type_select'}));
				$dbh->commit;
				$sth->finish();
				$dbh->disconnect();
				redirect '/models';
			}else{
				my ($pages, $offset);
				if (!params->{'offset'}){
					$offset = 0;
				}else{
					$offset = int(params->{'offset'})-1;
				}
				$sth = $dbh->prepare("SELECT * FROM models");
				$sth->execute(); 
				$pages =  int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth = $dbh->prepare("SELECT models.id, models.name AS m_name, 
									types.name AS t_name 
									FROM models, types 
									WHERE models.type_id = types.id LIMIT 10 OFFSET ?");
				$sth->execute($offset*10);
				my $modelsHash = $sth->fetchall_hashref('id');
				$sth->finish();
				$dbh->disconnect();
				template 'models', {
					'types' => $typesHash,
					'models' => $modelsHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['post', 'get'] => '/models/:id' => sub {
	my $dbh;
	try {	
		if (session 'logged_in'){
			$dbh = connect_db();
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
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['post', 'get'] => '/networks' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			if (request->method() eq "POST"){
				my $sth = $dbh->prepare("INSERT INTO networks (name) values (?)") or die $dbh->errstr;	
				$sth->execute(params->{'network_name'}) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die	$dbh->errstr;
				$dbh->disconnect();
				redirect '/networks';
			}else{
				my ($pages, $offset, $sth);
				if (!params->{'offset'}){
					$offset = 0;
				}else{
					$offset = int(params->{'offset'})-1;
				}
				$sth = $dbh->prepare("SELECT * FROM networks");
				$sth->execute() or die $sth->errstr; 
				$pages = int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth->finish();
				$sth = $dbh->prepare("SELECT id, name FROM networks LIMIT 10 OFFSET ?") or die $dbh->errstr;
				$sth->execute($offset*10) or die $sth->errstr;
				my $networksHash = $sth->fetchall_hashref('id');
				$sth->finish();
				$dbh->disconnect();
				template 'networks', {
					'networks' => $networksHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();	
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	}; 
};

any ['get', 'post'] => '/networks/:id' => sub {
	my $dbh;
	try {	
		if (session 'logged_in'){
			$dbh = connect_db();
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
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/network_devices' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
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
				my ($pages, $offset);
				if (!params->{'offset'}){
					$offset = 0;
				}else{
					$offset = int(params->{'offset'})-1;
				}
				$sth = $dbh->prepare("SELECT * FROM network_devices");
				$sth->execute() or die $sth->errstr; 
				$pages = int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth->finish();
				$sth = $dbh->prepare("SELECT network_devices.id, 
											network_devices.name AS d_name, 
											networks.name AS n_name 
									FROM network_devices, networks 
									WHERE network_devices.network_id = networks.id
									LIMIT 10 OFFSET ?");
				$sth->execute($offset*10);
				my $netDevicesHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'net_devices.tt', {
					'net_devices' => $netDevicesHash,
					'networks' => $networksHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/network_devices/:id' => sub {
	my $dbh;
	try {	
		if (session 'logged_in'){	
			$dbh = connect_db();
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
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/computers' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
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
				my ($pages, $offset);
				if (!params->{'offset'}){
					$offset = 0;
				}else{
					$offset = int(params->{'offset'})-1;
				}
				$sth = $dbh->prepare("SELECT * FROM computers");
				$sth->execute() or die $sth->errstr; 
				$pages = int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth->finish();
				$sth = $dbh->prepare("SELECT computers.id, 
											computers.name AS c_name, 
											networks.name AS n_name 
									FROM computers, networks 
									WHERE computers.network_id = networks.id
									LIMIT 10 OFFSET ?");
				$sth->execute($offset*10);
				my $computersHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'computers.tt', {
					'computers' => $computersHash,
					'networks' => $networksHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{	
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/computers/:id' => sub {
	my $dbh;
	try {	
		if (session 'logged_in'){	
			$dbh = connect_db();
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
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;	
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/parts' => sub {
	my $dbh;
	try {
		if (session 'logged_in'){
			$dbh = connect_db();
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
				die if (validateDate(params->{'part_waranty'}) != 1);
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
				my ($pages, $offset);
				if (!params->{'offset'}){
					$offset = 0;
				}else{
					$offset = int(params->{'offset'})-1;
				}
				$sth = $dbh->prepare("SELECT * FROM parts");
				$sth->execute() or die $sth->errstr; 
				$pages = int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth->finish();
				$sth = $dbh->prepare("SELECT parts.id, parts.waranty, 
									parts.name AS p_name, 
									models.name AS m_name, 
									computers.name AS c_name 
									FROM parts, models, computers 
									WHERE computers.id = parts.computer_id 
									AND models.id = parts.model_id
									LIMIT 10 OFFSET ?") or die $dbh->errstr;
				$sth->execute($offset*10) or die $sth->errstr;
				my $partsHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'parts.tt', {
					'parts' => $partsHash,
					'models' => $modelsHash,
					'computers' => $computersHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};	
			}
		}else{
			redirect '/';
		}
	}catch{	
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/parts/:id' => sub {
	my $dbh;
	try {	
		if (session 'logged_in'){	
			$dbh = connect_db();
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
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{	
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/manuals' => sub {
	my $dbh;
	try {
		if (session 'logged_in'){
			$dbh = connect_db();
			if (request->method() eq "POST"){
				my $public_dir = "/" . config->{"public"} . "/uploads";
				my $filename = params->{"filename"};
				my $file = upload("filename");
  				$file->copy_to("$public_dir/$filename");
  				my $sth = $dbh->prepare("SELECT * FROM manuals WHERE name = ?") or die $dbh->errstr;
				$sth->execute($filename) or die $sth->errstr;
				die if $sth->rows() > 0;
				$sth->finish();
				$sth = $dbh->prepare("INSERT INTO manuals (name) values (?)") or die $dbh->errstr;
				$sth->execute($filename) or die $sth->errstr;
				$sth->finish();
				$dbh->commit;
				$dbh->disconnect();
  				redirect '/manuals';
			}else{
				my ($pages, $offset);
				if (!params->{'offset'}){
					$offset = 0;
				}else{
					$offset = int(params->{'offset'})-1;
				}
				my $sth = $dbh->prepare("SELECT * FROM manuals");
				$sth->execute() or die $sth->errstr; 
				$pages = int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth->finish();
				$sth = $dbh->prepare("SELECT * FROM manuals
									LIMIT 10 OFFSET ?") or die $dbh->errstr;
				$sth->execute($offset*10) or die $sth->errstr;
				my $manualsHash = $sth->fetchall_hashref('id');
				$dbh->disconnect();
				template 'manuals', {
					'manuals' => $manualsHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{	
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/manuals/:id' => sub {
	my $dbh;
	try {
		if (session 'logged_in'){
			my $id = params->{'id'};
			$dbh = connect_db();
			my $sth = $dbh->prepare("DELETE FROM manuals 
									WHERE id = ?") or die $dbh->errstr;
			$sth->execute($id) or die $sth->errstr;
			$dbh->commit or die $dbh->errstr;
			$sth->finish();
			$dbh->disconnect();
			redirect '/manuals';
		}else{
			redirect '/';
		}
	}catch{	
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/search' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			if (request->method() eq "POST"){
				my $db = params->{'select_db'};
				redirect '/search' if (params->{'search_pattern'} =~ /\s/) or (params->{'search_pattern'} eq "");
				my $sth = $dbh->prepare("SELECT * FROM  $db
										WHERE name ~ ?
										LIMIT 200 OFFSET 0") or die $dbh->errstr;
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
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}else{
				template 'search.tt', {
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/parts/edit/:id' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			my $id = params->{'id'};
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
				$sth = $dbh->prepare("UPDATE parts SET name = ?, waranty = ?,
									model_id = ?, computer_id = ? WHERE id = ?") or die $dbh->errstr;
				$sth->execute(params->{'part_name'}, 
							params->{'part_waranty'},
							findID('models', params->{'model_select'}), 
							findID('computers', params->{'computer_select'}),
							$id) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect "/parts/edit/$id";
			}else{
				$sth = $dbh->prepare("SELECT parts.id, parts.waranty, 
									parts.name AS p_name, 
									models.name AS m_name, 
									computers.name AS c_name 
									FROM parts, models, computers 
									WHERE computers.id = parts.computer_id 
									AND models.id = parts.model_id
									AND parts.id = ?") or die $dbh->errstr;
				$sth->execute($id) or die $sth->errstr;
				my $part = $sth->fetchall_arrayref();
				template 'edit_part.tt', {
					'computers' => $computersHash,
					'models' => $modelsHash,
					'part' => $part,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/computers/edit/:id' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			my $id = params->{'id'};
			my $sth = $dbh->prepare("SELECT id, name FROM networks") or die $dbh->errstr;
			$sth->execute or die $sth->errstr;
			die if $sth->rows() < 1;
			my $networksHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				$sth = $dbh->prepare("UPDATE computers SET name = ?, network_id = ? WHERE id = ?") or die $dbh->errstr;
				$sth->execute(params->{'computer_name'}, 
							findID('networks', params->{'network_select'}),
							$id) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect "/computers/edit/$id";
			}else{
				$sth = $dbh->prepare("SELECT computers.id, 
									computers.name AS c_name, 
									networks.name AS n_name 
									FROM computers, networks 
									WHERE computers.network_id = networks.id
									AND computers.id = ?") or die $dbh->errstr;
				$sth->execute($id) or die $sth->errstr;
				my $computer = $sth->fetchall_arrayref();
				template 'edit_computer.tt', {
					'networks' => $networksHash,
					'computer' => $computer,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;	
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/network_devices/edit/:id' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			my $id = params->{'id'};
			my $sth = $dbh->prepare("SELECT id, name FROM networks") or die $dbh->errstr;
			$sth->execute or die $sth->errstr;
			die if $sth->rows() < 1;
			my $networksHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				$sth = $dbh->prepare("UPDATE network_devices SET name = ?, network_id = ? WHERE id = ?") or die $dbh->errstr;
				$sth->execute(params->{'network_device_name'}, 
							findID('networks', params->{'network_select'}),
							$id) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect "/network_devices/edit/$id";
			}else{
				$sth = $dbh->prepare("SELECT network_devices.id, 
									network_devices.name AS d_name, 
									networks.name AS n_name 
									FROM network_devices, networks 
									WHERE network_devices.network_id = networks.id
									AND network_devices.id = ?") or die $dbh->errstr;
				$sth->execute($id) or die $sth->errstr;
				my $device = $sth->fetchall_arrayref();
				template 'edit_network_device.tt', {
					'networks' => $networksHash,
					'device' => $device,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/models/edit/:id' => sub {
	my $dbh;
	try {
		if (session 'logged_in') {
			$dbh = connect_db();
			my $id = params->{'id'};
			my $sth = $dbh->prepare("SELECT id, name FROM types") or die $dbh->errstr;
			$sth->execute or die $sth->errstr;
			die if $sth->rows() < 1;
			my $typesHash = $sth->fetchall_hashref('id');
			$sth->finish();
			if (request->method() eq "POST"){
				$sth = $dbh->prepare("UPDATE models SET name = ?, type_id = ? WHERE id = ?") or die $dbh->errstr;
				$sth->execute(params->{'model_name'}, 
							findID('types', params->{'type_select'}),
							$id) or die $sth->errstr;
				$sth->finish();
				$dbh->commit or die $dbh->errstr;
				$dbh->disconnect();
				redirect "/models/edit/$id";
			}else{
				$sth = $dbh->prepare("SELECT models.id, models.name AS m_name, 
									types.name AS t_name 
									FROM models, types
									WHERE models.type_id = types.id
									AND models.id = ?") or die $dbh->errstr;
				$sth->execute($id) or die $sth->errstr;
				my $model = $sth->fetchall_arrayref();
				template 'edit_model.tt', {
					'types' => $typesHash,
					'model' => $model,
					'logout_url' => uri_for('/logout'),
					'types_url' => uri_for('/types'),
					'models_url' => uri_for('/models'),
					'networks_url' => uri_for('/networks'),
					'net_devices_url' => uri_for('/network_devices'),
					'computers_url' => uri_for('/computers'),
					'parts_url' => uri_for('/parts'),
					'manuals_url' => uri_for('/manuals'),
					'search_url' => uri_for('/search'),
					'logged' => 'true',
					'user' => $current_user
				};
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

any ['get', 'post'] => '/account_management' => sub {
	my $dbh;
	try{
		if(session 'logged_in'){
			$dbh = connect_db();
			if(request->method() eq "POST"){
				my $name = params->{"name"};
				my $sth = $dbh->prepare("UPDATE accounts SET rights = ? WHERE name = ?") or die $dbh->errstr;
				$sth->execute(int(params->{"new_account_rights_$name"}), $name) or die $sth->errstr;
				$dbh->commit or die $dbh->errstr;
				$sth->finish();
				$dbh->disconnect();
				redirect '/account_management';
			}else{
				if (!$user_is_admin){
					$dbh->disconnect();
					template "exception", {"admin_err" => "You aren't an admin!"}; 
				}else{
					my ($pages, $offset);
					if (!params->{'offset'}){
						$offset = 0;
					}else{
						$offset = int(params->{'offset'})-1;
					}
					my $sth = $dbh->prepare("SELECT * FROM accounts");
					$sth->execute() or die $sth->errstr; 
					$pages = int(($sth->rows()) / 10);
					$pages++ if ($sth->rows % 10) != 0;
					$sth->finish();
					$sth = $dbh->prepare("SELECT id, name, mail, rights FROM accounts
											LIMIT 10 OFFSET ?") or die $dbh->errstr;
					$sth->execute($offset*10) or die $sth->errstr;
					my $accountsHash = $sth->fetchall_hashref('id');
					$sth->finish();
					$dbh->disconnect();
					template 'account_management', {
						'accounts' => $accountsHash,
						'pages' => $pages,
						'curr_page' => $offset+1,
						'logout_url' => uri_for('/logout'),
						'types_url' => uri_for('/types'),
						'models_url' => uri_for('/models'),
						'networks_url' => uri_for('/networks'),
						'net_devices_url' => uri_for('/network_devices'),
						'computers_url' => uri_for('/computers'),
						'parts_url' => uri_for('/parts'),
						'manuals_url' => uri_for('/manuals'),
						'search_url' => uri_for('/search'),
						'logged' => 'true',
						'user' => $current_user
					};
				}
			}
		}else{
			redirect '/';
		}
	}catch{
		try{
			debug $_;
			$dbh->disconnect();
			template 'exception';
		}catch{
			debug $_;
			template 'exception';
		};
	};
};

true;