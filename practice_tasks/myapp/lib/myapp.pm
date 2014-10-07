package myapp;
use Dancer ':syntax';
use Dancer::Plugin::Ajax;
use Dancer::Plugin::Email;
use Dancer::Plugin::I18N;

use DBI;
use Data::Dumper;
use Try::Tiny;

use Math::Round;
use Digest::MD5 qw(md5 md5_hex md5_base64);	
use String::Random qw(random_string);
use Scalar::Util::Numeric qw(isint);
use Encode qw(decode_utf8 decode encode_utf8);

use JSON;

use helpers;

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

sub findIDModel {
	my $dbh;
	my $table = $_[0];
	my $name_pattern = $_[1];
	my $curr_lang = session "user_current_lang";
	$dbh = connect_db();
	my $sth = $dbh->prepare("SELECT id FROM $table WHERE name_$curr_lang = '$name_pattern'");
	$sth->execute() ;
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

sub findID {
	my $dbh;
	my $table = $_[0];
	my $name_pattern = $_[1];
	$dbh = connect_db();
	my $sth = $dbh->prepare("SELECT id FROM $table WHERE name = '$name_pattern'");
	$sth->execute() ;
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

sub getColumnNamesInCurrentLanguage ($$) {
	my $dbh = $_[0];
	my $table = $_[1];
	my $curr_lang = session "user_current_lang";
	
	my $sth = $dbh->prepare("SELECT * FROM $table WHERE FALSE");
	$sth->execute();
	my $columnNames = $sth->{NAME};
	$sth->finish();
	my @output;
	foreach my $columnName (@$columnNames) {
		if (substr($columnName, -2, 2) eq $curr_lang) {
			push(@output, $columnName);
		}
	}
	return @output;
};

sub buildINSERTQuery ($$){
	my $columns = $_[0];
	my $table = $_[1];
	my $query = "INSERT INTO $table (";
	foreach my $column (@$columns) {
		$query .= ($column . ", ") if $column ne "id";
	}
	substr ($query, -2) = "";
	$query .= ") values ("; 
	chop($table); 
	foreach my $column (@$columns){
		if ($column ne "id") {
			if (isint(params->{$table. "_". "$column"})){
				$query .= ((params->{$table. "_". "$column"}) .", ");
			}else{
				$query .= ("'" . (params->{$table. "_". "$column"}) ."', ");
			}
		}
	}
	$query .= ")";
	substr ($query, -3, 2) = "";
	return $query;
};

hook on_route_exception => sub {
	helpers::printToLog($_);
	status 404;
	return halt template "exception";
};

get '/exception' => sub {
	template 'exception.tt';
};

any ['post', 'get'] => '/' => sub {
	my $dbh;
	if (request->method() eq "POST"){
		$dbh = connect_db();
		my $check = 0;
		my $sth = $dbh->prepare("SELECT id,name,password FROM accounts 
								WHERE name = ? AND password = ?") ;
		$sth->execute(params->{'username'}, md5_base64(params->{"password"}, params->{"username"}));
		helpers::ASSERT(($sth->rows == 1), ("Died on line: " . __LINE__ ));
		session 'logged_in' => true;
		session current_user => params->{'username'};
		$check = 1;
	    $sth->finish();
	    if (!$check) { 
	    	$dbh->disconnect();
			template 'home', {
				'msg' => $check,
				'err' => "Wrong username or password",
			};
		}else{
			$sth = $dbh->prepare("SELECT accounts.active, accounts.rights, 
								languages.abbreviation AS lang 
								FROM accounts, languages 
								WHERE accounts.name = ? 
								AND accounts.interface_language = languages.id") ;
			$sth->execute(params->{'username'});
			helpers::ASSERT(($sth->rows == 1), ("Died on line: " . __LINE__ ));
			$check = $sth->fetchrow_hashref() ;
			$sth->finish();
			$dbh->disconnect();
			my @rights = helpers::checkUserRights($check->{'rights'});
			session user_can_read => $rights[2];
			session user_can_write => $rights[1];
			session user_is_admin => $rights[0];
			session user_current_lang => $check->{'lang'};
			helpers::printToLog((session 'current_user') . " logged in at " . scalar localtime);
			redirect '/confirm_account' if ($check->{"active"} == 0);
			redirect '/types';	
		}
	}else{
		redirect '/user_panel' if (session 'logged_in');
		template 'home', {
			'msg' => 0,
		};
	}
};

any ['post', 'get'] => '/user_panel' => sub {
	my $dbh;
	if (session 'logged_in'){
		helpers::printToLog((session 'current_user') . " requested user_panel view at " . scalar localtime);
		$dbh = connect_db();
		my $sth = $dbh->prepare("SELECT * FROM accounts 
								WHERE name = ?") ;
		helpers::ASSERT((defined(session 'current_user')), ("Died on line: " . __LINE__ ));
		$sth->execute(session 'current_user') ;
		my $user = $sth->fetchrow_hashref() ;
		helpers::ASSERT(($sth->rows() == 1), ("Died on line: " . __LINE__ ));
		$sth->finish();
		my $active = "yes";
		$active = "no" if ($user->{"active"} == 0);
		my $langs = helpers::fetchHashSortedById($dbh, helpers::buildSimpleSELECTQuery('languages', "*", 100, 0));
		if (request->method() eq "POST"){
			if ((md5_base64(params->{"old_pass"}, session 'current_user') eq $user->{"password"}) &&
				(params->{"new_pass_1"} eq params->{"new_pass_2"})){
				my $query = "UPDATE accounts SET password = '" . 
							md5_base64(params->{"new_pass_1"}, session 'current_user') .
				   			"' WHERE name = '" .
				   			(session 'current_user') . "'";
				helpers::makeINSERTByGivenQuery($dbh, $query);
				helpers::printToLog((session 'current_user') . " changed his password at " . scalar localtime);
				$dbh->disconnect();
				template 'user_panel', {
					'langs' => $langs,
					'user' => $user->{"name"},
					'mail' => $user->{"mail"},
					'user_lang' => $user->{"interface_language"}, 
					'active' => $active,
					'msg' => "Your password was changed",
					'logged' => 'true',
				};
			}
		}else{
			$dbh->disconnect();
			my $curr_lang = session "user_current_lang";
			languages( [$curr_lang] );
			template 'user_panel', {
				'langs' => $langs,
				'user' => $user->{"name"},
				'mail' => $user->{"mail"},
				'user_lang' => $user->{"interface_language"},  
				'active' => $active,
				'logged' => 'true',
			};
		}
	}else{
		redirect '/';
	}	
};

any ['post', 'get'] => '/change_language' => sub {
	my $dbh;
	if (session 'logged_in'){
		if(request->method() eq "POST"){
			$dbh = connect_db();
			my $sth = $dbh->prepare("SELECT id, abbreviation FROM languages WHERE name_en = ?") ;
			$sth->execute(params->{"lang_select"}) ;
			helpers::ASSERT(($sth->rows == 1), ("Died on line: " . __LINE__ ));
			my $lang_data= $sth->fetchrow_hashref();
			$sth->finish();
			my $query = "UPDATE accounts SET interface_language = '" . $lang_data->{"id"} . "'";
			helpers::makeINSERTByGivenQuery($dbh, $query);
			session user_current_lang => $lang_data->{"abbreviation"};
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " changed his language at " . scalar localtime);
			redirect '/user_panel'
		}else{
			redirect '/user_panel'
		}
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/restore_password' => sub {
	my $dbh;
	if (session 'logged_in'){
		redirect '/';
	}else{
		if (request->method() eq "POST"){
			$dbh = connect_db();
			my $sth = $dbh->prepare("SELECT name, active FROM accounts
									WHERE mail = ?") ;
			$sth->execute(params->{"mail"}) ;
			helpers::ASSERT(($sth->rows == 1), ("Died on line: " . __LINE__ ));
			my $row = $sth->fetchrow_hashref();
			my $user = $row->{"name"};
			$sth->finish();
			if ($row->{"active"} == 0) {
				$dbh->disconnect();
				template 'restore_password', {
					err => 1
				};
			}else{
				my $new_pass = random_string("..........");
				my $query = "UPDATE accounts SET password = '" . md5_base64($new_pass,$user) .   
							"' WHERE mail = '" . params->{"mail"} . "'";
				helpers::makeINSERTByGivenQuery($dbh, $query);
				$dbh->disconnect();
				email {
					to => params->{"mail"},
					from => 'konkokodon@abv.bg',
					subject => 'new password',
					message => $new_pass
				};
				my $mail = params->{"mail"};
				helpers::printToLog(" password recovery code was sent at " . scalar localtime . " to $mail");
				template 'restore_password', {
					'success' => 1 
				};
			}
		}else{
			template 'restore_password';
		}
	}
};

any ['post', 'get'] => '/register' => sub {
	my $dbh;
	if (session 'logged_in'){
		redirect '/';	
	}else{
		if (request->method() eq "POST"){
			$dbh = connect_db();
			helpers::ASSERT((params->{"password_1"} eq params->{"password_2"}), ("Died on line: " . __LINE__ ));
			helpers::ASSERT((params->{"mail"} =~ /[-0-9a-zA-Z.+_]+@[-0-9a-zA-Z.+_]+\.[a-zA-Z]{2,4}/), ("Died on line: " . __LINE__ ));
			helpers::ASSERT((length(params->{"username"}) > 3), ("Died on line: " . __LINE__ ));
			helpers::ASSERT((length(params->{"password_1"}) > 3), ("Died on line: " . __LINE__ ));
			my $sth = $dbh->prepare("SELECT * FROM accounts WHERE
									name = ?");
			$sth->execute(params->{"username"});
			helpers::ASSERT(($sth->rows() == 0), ("Died on line: " . __LINE__ ));
			$sth->finish();	
			my $confirm_code = random_string("..........");
			$sth = $dbh->prepare("SELECT id FROM languages WHERE abbreviation = 'en'") ;
			$sth->execute();
			helpers::ASSERT(($sth->rows() == 1), ("Died on line: " . __LINE__ ));
			my @lang_id = $sth->fetchrow_arrayref();
			$sth->finish();
			$sth = $dbh->prepare("INSERT INTO accounts (name, password, mail, confirm_code, 
														active, interface_language) 
												values (?, ?, ?, ?, ?, ?)") ;
			$sth->execute(params->{"username"}, md5_base64(params->{"password_1"}, params->{"username"}), 
							params->{"mail"}, $confirm_code, "FALSE", int($lang_id[0][0])) ;
			$sth->finish();
			$dbh->commit ;
			$dbh->disconnect();
			email {
				to => params->{"mail"},
				from => 'konkokodon@abv.bg',
				subject => 'email confirmation code',
				message => $confirm_code
			};
			my $name = params->{"username"};
			helpers::printToLog(" account -> $name , has been created at" . scalar localtime);
			template 'home', {
				'success' => "You're account has been created"
			};
		}else{
			template 'register';
		}
	}
};

any ['post', 'get'] => '/confirm_account' => sub {
	my $dbh;
	if(session 'logged_in') {
		$dbh = connect_db();
		my $sth = $dbh->prepare("SELECT * FROM accounts WHERE
									name = ? AND active = FALSE") ;
		$sth->execute(session 'current_user') ;
		if ($sth->rows() != 1) {
			$sth->finish();
			$dbh->disconnect();
			redirect '/';
		}
		$sth->finish(); 
		if (request->method() eq "POST"){
			my $sth = $dbh->prepare("SELECT confirm_code FROM accounts WHERE
									name = ? AND active = FALSE") ;
			$sth->execute(session 'current_user');
			helpers::ASSERT(($sth->rows() == 1), ("Died on line: " . __LINE__ ));
			my $code = $sth->fetchrow_hashref();
			$sth->finish();
			if ($code->{"confirm_code"} eq params->{"code"}){
				my $query = "UPDATE accounts SET active = TRUE WHERE name = '" . (session 'current_user') . "'";
				helpers::makeINSERTByGivenQuery($dbh, $query);
				$dbh->disconnect();
				helpers::printToLog((session 'current_user') . " confirmed his account at " . scalar localtime);
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
};

get '/logout' => sub {
	helpers::printToLog((session 'current_user') . " logged out at" . scalar localtime);
	session->destroy() if (session 'logged_in');
	redirect '/';
};



any ['post', 'get'] => '/types' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested types view at " . scalar localtime);
		$dbh = connect_db();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			helpers::makeINSERTByGivenQuery($dbh, buildINSERTQuery(helpers::fetchTableColumnNames($dbh, 'types'), 'types'));	
			helpers::printToLog((session 'current_user') . " created type at" . scalar localtime);
		}
		my $offset = 0;
		$offset = int(params->{'offset'})-1 if params->{'offset'};
		my $rows = helpers::countTableRows($dbh, 'types');
		my $pages =  int($rows / 250);
		$pages++ if ($rows % 250) != 0;
		my @output = getColumnNamesInCurrentLanguage($dbh, 'types');
		push(@output, "id");
 		my $typesHash = helpers::fetchHashSortedById($dbh, helpers::buildSimpleSELECTQuery('types', \@output, 250, ($offset)*250));
		my $curr_lang = session "user_current_lang";
		$typesHash = helpers::decodeDBHash($typesHash, $curr_lang);
		my $tableInfo = helpers::fetchHashSortedById($dbh, 
											"SELECT id, column_name_$curr_lang, column_name
											FROM metadata WHERE table_name = 'types' ");
		$tableInfo = helpers::decodeDBHash($tableInfo, $curr_lang);
		$dbh->disconnect();
		languages( [$curr_lang] );
		template 'template', {
			'translated_column' => ("column_name_" . $curr_lang),
			'tableInfo' => $tableInfo,
			'fetchedEntries' => $typesHash,
			'currentType' => 'type',	
			'pages' => $pages,
			'curr_page' => $offset+1,
			'logged' => 'true',
			'user' => session 'current_user'
		};
	}else{
		redirect '/';
	}
};


any ['post', 'get'] => '/types/:id' => sub {
	my $dbh;	
	if (session 'logged_in'){
		if (session 'user_can_write'){
			$dbh = connect_db();
			helpers::makeDELETEQuery($dbh, 'types', params->{'id'});
			helpers::printToLog((session 'current_user') . " deleted type with id " . params->{'id'} . scalar localtime);
			redirect '/types';
		}else{
			redirect '/types';
		}
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/models' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested models view at " . scalar localtime);
		$dbh = connect_db();
		my $sth;
		my $curr_lang = session "user_current_lang";
		my $typesHash = helpers::fetchHashSortedById($dbh, helpers::buildSimpleSELECTQuery('types', ["id" ,"name_$curr_lang"], 100, 0)); 
		$typesHash = helpers::decodeDBHash($typesHash, $curr_lang);
		if ((request->method() eq "POST") && (session 'user_can_write')){
			params->{"model_type_id"} = findIDModel('types',params->{"model_type_id"});
			helpers::makeINSERTByGivenQuery($dbh, buildINSERTQuery(helpers::fetchTableColumnNames($dbh, 'models'), 'models'));
			$dbh->disconnect();		
			helpers::printToLog((session 'current_user') . " created model at" . scalar localtime);
			redirect '/models';
		}else{
			my $offset = 0;
			$offset = int(params->{'offset'})-1 if (params->{'offset'});
			my $rows = helpers::countTableRows($dbh, 'models');
			my $pages =  int($rows / 250);
			$pages++ if ($rows % 250) != 0;
			my $query = "SELECT models.id, models.name_$curr_lang, types.name_$curr_lang AS type_name_$curr_lang 
						FROM models LEFT JOIN types 
						ON models.type_id = types.id LIMIT 250 OFFSET " . ($offset*250);
			my $modelsHash = helpers::fetchHashSortedById($dbh, $query);
			$modelsHash = helpers::decodeDBHash($modelsHash, $curr_lang);
			$query = "SELECT * FROM metadata 
					WHERE table_name = 'models'
					UNION
					SELECT * FROM metadata 
					WHERE table_name = 'types' AND column_name = 'name_$curr_lang'";
			my $tableInfo = helpers::fetchHashSortedById($dbh, $query);
			$tableInfo = helpers::decodeDBHash($tableInfo, $curr_lang);
			$dbh->disconnect();
			languages( [$curr_lang] );
			template 'template', {
				'translated_column' => ("column_name_" . $curr_lang),
				'tableInfo' => $tableInfo,
				'currentType' => 'model',
				'currentTable' => 'models',
				'fetchedEntries' => $modelsHash,
				'pages' => $pages,
				'curr_page' => $offset+1,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/models/:id' => sub {
	my $dbh;
	if (session 'logged_in'){
		if (session 'user_can_write'){	
			$dbh = connect_db();
			helpers::makeDELETEQuery($dbh, 'models', params->{'id'});
			helpers::printToLog((session 'current_user') . " deleted model with id " . params->{'id'} . scalar localtime);
			redirect '/models';
		}else{
			redirect '/models';
		}
	}else{
		redirect '/';
	}
};

any ['post', 'get'] => '/networks' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested networks view at " . scalar localtime);
		$dbh = connect_db();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			helpers::makeINSERTByGivenQuery($dbh, buildINSERTQuery(helpers::fetchTableColumnNames($dbh, 'networks'), 'networks'));
			helpers::printToLog((session 'current_user') . " created network at" . scalar localtime);
		}
		my ($pages, $offset, $sth);
		$offset = 0;
		$offset = int(params->{'offset'})-1 if (params->{'offset'});
		my $rows = helpers::countTableRows($dbh, 'networks');
		$pages =  int($rows / 250);
		$pages++ if ($rows % 250) != 0;
		my @output = getColumnNamesInCurrentLanguage($dbh, 'networks');
		push(@output, "id");
 		my $networksHash = helpers::fetchHashSortedById($dbh, helpers::buildSimpleSELECTQuery('networks', \@output, 250, ($offset)*250));
		my $curr_lang = session "user_current_lang";
		$networksHash = helpers::decodeDBHash($networksHash, $curr_lang);
		my $tableInfo = helpers::fetchHashSortedById($dbh, 
											"SELECT id, column_name_$curr_lang, column_name
											FROM metadata WHERE table_name = 'networks' ");
		$tableInfo = helpers::decodeDBHash($tableInfo, $curr_lang);
		$dbh->disconnect();
		languages( [$curr_lang] );
		template 'template', {
			'translated_column' => ("column_name_" . $curr_lang),
			'currentType' => 'network',
			'tableInfo' => $tableInfo,
			'fetchedEntries' => $networksHash,
			'pages' => $pages,
			'curr_page' => $offset+1,
			'logged' => 'true',
			'user' => session 'current_user'
		};
	}else{
		redirect '/';
	} 
};

any ['get', 'post'] => '/networks/:id' => sub {
	my $dbh;	
	if (session 'logged_in'){
		if (session 'user_can_write'){
			$dbh = connect_db();
			helpers::makeDELETEQuery($dbh, 'networks', params->{'id'});
			helpers::printToLog((session 'current_user') . " deleted network with id " . params->{'id'} . scalar localtime);
			redirect '/networks';
		}else{
			redirect '/networks';
		}
	}else{
		redirect '/';
	}
};

ajax '/ajax_search' => sub {
	my $dbh = connect_db();
	my $curr_lang = session 'user_current_lang' || "en";
	my $pattern = $dbh->quote(params->{"input"});
	my $table = params->{"table"};
	my $currentFormType = params->{"current_type"};
	# print STDERR Dumper($currentFormType);
	my $networksHash = helpers::fetchHashSortedById($dbh, "SELECT id, name_$curr_lang FROM $table WHERE name_$curr_lang ~ $pattern LIMIT 50");
	chop($table);
	# print STDERR Dumper($table);
	$dbh->disconnect();
	$networksHash->{"select_tag_info"} = {"id" => $table . "select", "name" => $currentFormType . "_" . $table . "_id"};
	my $str = JSON->new->encode($networksHash);
	$str = decode_utf8($str);
	return $str;
};

any ['get', 'post'] => '/network_devices' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested network_devices view at " . scalar localtime);
		$dbh = connect_db();
		my $sth;
		my $curr_lang = session "user_current_lang";
		if ((request->method() eq "POST") && (session 'user_can_write')){
			params->{"network_device_network_id"} = findIDModel('networks',params->{"network_device_network_id"});
			helpers::makeINSERTByGivenQuery($dbh, buildINSERTQuery(helpers::fetchTableColumnNames($dbh, 'network_devices'), 'network_devices'));
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " created network_device at" . scalar localtime);
			redirect '/network_devices';
		}else{
			my $offset = 0;
			$offset = int(params->{'offset'})-1 if (params->{'offset'});
			my $rows = helpers::countTableRows($dbh, 'network_devices');
			my $pages =  int($rows / 250);
			$pages++ if ($rows % 250) != 0;
			my $query = "SELECT network_devices.id, network_devices.name_$curr_lang, networks.name_$curr_lang AS network_name_$curr_lang 
						FROM network_devices LEFT JOIN networks
						ON network_devices.network_id = networks.id LIMIT 250 OFFSET " . ($offset*250);
			my $netDevsHash = helpers::fetchHashSortedById($dbh, $query);
			$netDevsHash = helpers::decodeDBHash($netDevsHash, $curr_lang);
			$query = "SELECT * FROM metadata 
					WHERE table_name = 'network_devices'
					UNION
					SELECT * FROM metadata 
					WHERE table_name = 'networks' AND column_name = 'name_$curr_lang'";
			my $tableInfo = helpers::fetchHashSortedById($dbh, $query);
			$tableInfo = helpers::decodeDBHash($tableInfo, $curr_lang);
			$dbh->disconnect();
			languages( [$curr_lang] );			
			template 'template', {
				'translated_column' => ("column_name_" . $curr_lang),
				'tableInfo' => $tableInfo,
				'currentType' => 'network_device',
				'currentTable' => 'network_devices',
				'fetchedEntries' => $netDevsHash,
				'pages' => $pages,
				'curr_page' => $offset+1,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/network_devices/:id' => sub {
	my $dbh;	
	if (session 'logged_in'){	
		if (session 'user_can_write'){
			$dbh = connect_db();
			helpers::makeDELETEQuery($dbh, 'network_devices', params->{'id'});
			helpers::printToLog((session 'current_user') . " deleted network_device with id " . params->{'id'} . scalar localtime);
			redirect '/network_devices';
		}else{
			redirect '/network_devices';
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/computers' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested computers view at " . scalar localtime);
		$dbh = connect_db();
		my $sth;
		my $curr_lang = session "user_current_lang";
		if ((request->method() eq "POST") && (session 'user_can_write')){
			params->{"computer_network_id"} = findIDModel('networks',params->{"computer_network_id"});
			helpers::makeINSERTByGivenQuery($dbh, buildINSERTQuery(helpers::fetchTableColumnNames($dbh, 'computers'), 'computers'));
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " created computer at" . scalar localtime);
			redirect '/computers';
		}else{
			my $offset = 0;
			$offset = int(params->{'offset'})-1 if (params->{'offset'});
			my $rows = helpers::countTableRows($dbh, 'computers');
			my $pages =  int($rows / 250);
			$pages++ if ($rows % 250) != 0;
			my $query = "SELECT computers.id, computers.name_$curr_lang, networks.name_$curr_lang AS network_name_$curr_lang 
						FROM computers LEFT JOIN networks
						ON computers.network_id = networks.id LIMIT 250 OFFSET " . ($offset*250);
			my $computersHash = helpers::fetchHashSortedById($dbh, $query);
			$computersHash = helpers::decodeDBHash($computersHash, $curr_lang);
			$query = "SELECT * FROM metadata 
					WHERE table_name = 'computers'
					UNION
					SELECT * FROM metadata 
					WHERE table_name = 'networks' AND column_name = 'name_$curr_lang'";
			my $tableInfo = helpers::fetchHashSortedById($dbh, $query);
			$tableInfo = helpers::decodeDBHash($tableInfo, $curr_lang);
			$dbh->disconnect();
			languages( [$curr_lang] );
			template 'template', {
				'translated_column' => ("column_name_" . $curr_lang),
				'tableInfo' => $tableInfo,
				'currentType' => 'computer',
				'currentTable' => 'computers',
				'fetchedEntries' => $computersHash,
				'pages' => $pages,
				'curr_page' => $offset+1,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/computers/:id' => sub {
	my $dbh;	
	if (session 'logged_in'){	
		if (session 'user_can_write'){	
			$dbh = connect_db();
			helpers::makeDELETEQuery($dbh, 'computers', params->{'id'});
			helpers::printToLog((session 'current_user') . " deleted computer with id " . params->{'id'} . scalar localtime);
			redirect '/computers';
		}else{
			redirect '/computers';
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/parts' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested parts view at " . scalar localtime);
		$dbh = connect_db();
		my $sth;
		my $curr_lang = session "user_current_lang";
		if ((request->method() eq "POST") && (session 'user_can_write')){
			params->{"part_model_id"} = findIDModel('models',params->{"part_model_id"});
			params->{"part_computer_id"} = findIDModel('computers',params->{"part_computer_id"});
			helpers::makeINSERTByGivenQuery($dbh, buildINSERTQuery(helpers::fetchTableColumnNames($dbh, 'parts'), 'parts'));
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " created part at " . scalar localtime);
			redirect '/parts';
		}else{
			my $offset = 0;
			$offset = int(params->{'offset'})-1 if (params->{'offset'});
			my $rows = helpers::countTableRows($dbh, 'parts');
			my $pages =  int($rows / 10);
			$pages++ if ($rows % 10) != 0;
			my $query = "SELECT parts.id, parts.name_$curr_lang, models.name_$curr_lang AS model_name_$curr_lang,
						computers.name_$curr_lang AS computer_name_$curr_lang
						FROM computers, models, parts
						WHERE parts.computer_id = computers.id 
						AND parts.model_id = models.id
						LIMIT 10 OFFSET " . ($offset*10);
			my $partsHash = helpers::fetchHashSortedById($dbh, $query);
			$partsHash = helpers::decodeDBHash($partsHash, $curr_lang);
			$query = "SELECT * FROM metadata 
					WHERE table_name = 'parts'
					UNION
					SELECT * FROM metadata 
					WHERE table_name = 'models' AND column_name = 'name_$curr_lang'
					UNION
					SELECT * FROM metadata 
					WHERE table_name = 'computers' AND column_name = 'name_$curr_lang'";
			my $tableInfo = helpers::fetchHashSortedById($dbh, $query);
			$tableInfo = helpers::decodeDBHash($tableInfo, $curr_lang);
			$dbh->disconnect();
			languages( [$curr_lang] );
			template 'template', {
				'translated_column' => ("column_name_" . $curr_lang),
				'tableInfo' => $tableInfo,
				'currentType' => 'part',
				'currentTable' => 'parts',
				'fetchedEntries' => $partsHash,
				'pages' => $pages,
				'curr_page' => $offset+1,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/parts/:id' => sub {
	my $dbh;
	if (session 'logged_in'){	
		if (session 'user_can_write'){	
			$dbh = connect_db();
			helpers::makeDELETEQuery($dbh, 'parts', params->{'id'});
			helpers::printToLog((session 'current_user') . " deleted part with id " . params->{'id'} . scalar localtime);
			redirect '/parts';
		}else{
			redirect '/parts';
		}
	}else{
		redirect '/';
	}
};

get '/download/:id' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')){
		$dbh = connect_db();
		my $sth = $dbh->prepare("SELECT id, name FROM manuals WHERE id = ?");
		$sth->execute(params->{"id"});
		helpers::ASSERT($sth->rows() >= 0);
		if ($sth->rows() == 0) {
			$sth->finish();
			$dbh->disconnect();
			redirect "/manuals";
		}else{
			helpers::printToLog((session 'current_user') . " downloaded manual at " . scalar localtime);
			my $file_name = $sth->fetchrow_hashref();
			$file_name = $$file_name{"name"};
			$sth->finish();
			$dbh->disconnect();
			return send_file("/uploads/" . $file_name);
		}
	}
};

any ['get', 'post'] => '/manuals' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')){
		helpers::printToLog((session 'current_user') . " requested manuals view at " . scalar localtime);
		$dbh = connect_db();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			my $public_dir = "/" . config->{"public"} . "/uploads";
			my $filename = params->{"filename"};
			my $file = upload("filename");
  			$file->copy_to("$public_dir/$filename");
  			my $sth = $dbh->prepare("SELECT * FROM manuals WHERE name = ?") ;
			$sth->execute($filename) ;
			die if $sth->rows() > 0;
			$sth->finish();
			$sth = $dbh->prepare("INSERT INTO manuals (name) values (?)") ;
			$sth->execute($filename) ;
			$sth->finish();
			$dbh->commit;
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " created new manual " . scalar localtime);
  			redirect '/manuals';
		}else{
			my ($pages, $offset);
			if (!params->{'offset'}){
				$offset = 0;
			}else{
				$offset = int(params->{'offset'})-1;
			}
			my $sth = $dbh->prepare("SELECT * FROM manuals");
			$sth->execute() ; 
			$pages = int(($sth->rows()) / 10);
			$pages++ if ($sth->rows % 10) != 0;
			$sth->finish();
			$sth = $dbh->prepare("SELECT * FROM manuals
								LIMIT 10 OFFSET ?") ;
			$sth->execute($offset*10) ;
			my $manualsHash = $sth->fetchall_hashref('id');
			$dbh->disconnect();
			my $curr_lang = session 'user_current_lang';
			languages( [$curr_lang] );
			template 'manuals', {
				'manuals' => $manualsHash,
				'pages' => $pages,
				'curr_page' => $offset+1,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/manuals/:id' => sub {
	my $dbh;
	if (session 'logged_in'){
		if (session 'user_can_write'){
			my $id = params->{'id'};
			$dbh = connect_db();
			my $sth = $dbh->prepare("DELETE FROM manuals 
									WHERE id = ?") ;
			$sth->execute($id) ;
			$dbh->commit ;
			$sth->finish();
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " deleted manual with id " . $id . scalar localtime);
		}
		redirect '/manuals';
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/search' => sub {	
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		helpers::printToLog((session 'current_user') . " requested search view at " . scalar localtime);
		$dbh = connect_db();
		my $curr_lang = session 'user_current_lang';
		if (request->method() eq "POST"){
			my $db = params->{'select_db'};
			$db = $dbh->quote_identifier( $db );
			redirect '/search' if (params->{'search_pattern'} =~ /\s/) or (params->{'search_pattern'} eq "");
			my $pattern = $dbh->quote("^" . params->{'search_pattern'});
			my $stat = "SELECT id, name_$curr_lang FROM  $db 
						WHERE name_$curr_lang ~ $pattern OR name_en ~ $pattern 
						LIMIT 200 OFFSET 0";
			my $sth = $dbh->prepare($stat);
			$sth->execute() ;
			my $searchHash = $sth->fetchall_hashref("id");
			$searchHash = helpers::decodeDBHash($searchHash, $curr_lang);
			$sth = $dbh->prepare("SELECT column_name_$curr_lang FROM metadata 
									WHERE table_name = ? AND column_name = ?");
			$sth->execute(params->{'select_db'}, "name_$curr_lang");
			my $columnName = $sth->fetchall_arrayref();
			
			$$columnName[0][0] = decode_utf8($$columnName[0][0]);
			$dbh->disconnect();
			helpers::printToLog((session 'current_user') . " used search at " . scalar localtime);
			template 'search', {
				'query' => $searchHash,
				'column_name' => $$columnName[0][0],
				# 'has_result' => $hasResult,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}else{
			languages( [$curr_lang] );
			template 'search.tt', {
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/parts/edit/:id' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		$dbh = connect_db();
		my $id = params->{'id'};
		my $sth = $dbh->prepare("SELECT id, name FROM models") ;
		$sth->execute() ;
		die if $sth->rows() < 1;
		my $modelsHash = $sth->fetchall_hashref('id');
		$sth->finish();
		$sth = $dbh->prepare("SELECT id, name FROM computers") ;
		$sth->execute ;
		die if $sth->rows() < 1;
		my $computersHash = $sth->fetchall_hashref('id');
		$sth->finish();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			$sth = $dbh->prepare("UPDATE parts SET name = ?, waranty = ?,
								model_id = ?, computer_id = ? WHERE id = ?") ;
			$sth->execute(params->{'part_name'}, 
						params->{'part_waranty'},
						findID('models', params->{'model_select'}), 
						findID('computers', params->{'computer_select'}),
						$id) ;
			$sth->finish();
			$dbh->commit ;
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
								AND parts.id = ?") ;
			$sth->execute($id) ;
			my $part = $sth->fetchall_arrayref();
			$sth->finish();
			$dbh->disconnect();
			template 'edit_part.tt', {
				'computers' => $computersHash,
				'models' => $modelsHash,
				'part' => $part,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/computers/edit/:id' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		$dbh = connect_db();
		my $id = params->{'id'};
		my $sth = $dbh->prepare("SELECT id, name FROM networks") ;
		$sth->execute ;
		die if $sth->rows() < 1;
		my $networksHash = $sth->fetchall_hashref('id');
		$sth->finish();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			$sth = $dbh->prepare("UPDATE computers SET name = ?, network_id = ? WHERE id = ?") ;
			$sth->execute(params->{'computer_name'}, 
						findID('networks', params->{'network_select'}),
						$id) ;
			$sth->finish();
			$dbh->commit ;
			$dbh->disconnect();
			redirect "/computers/edit/$id";
		}else{
			$sth = $dbh->prepare("SELECT computers.id, 
								computers.name AS c_name, 
								networks.name AS n_name 
								FROM computers, networks 
								WHERE computers.network_id = networks.id
								AND computers.id = ?") ;
			$sth->execute($id) ;
			my $computer = $sth->fetchall_arrayref();
			$sth->finish();
			$dbh->disconnect();
			template 'edit_computer.tt', {
				'networks' => $networksHash,
				'computer' => $computer,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/network_devices/edit/:id' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		$dbh = connect_db();
		my $id = params->{'id'};
		my $sth = $dbh->prepare("SELECT id, name FROM networks") ;
		$sth->execute ;
		die if $sth->rows() < 1;
		my $networksHash = $sth->fetchall_hashref('id');
		$sth->finish();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			$sth = $dbh->prepare("UPDATE network_devices SET name = ?, network_id = ? WHERE id = ?") ;
			$sth->execute(params->{'network_device_name'}, 
						findID('networks', params->{'network_select'}),
						$id) ;
			$sth->finish();
			$dbh->commit ;
			$dbh->disconnect();
			redirect "/network_devices/edit/$id";
		}else{
			$sth = $dbh->prepare("SELECT network_devices.id, 
								network_devices.name AS d_name, 
								networks.name AS n_name 
								FROM network_devices, networks 
								WHERE network_devices.network_id = networks.id
								AND network_devices.id = ?") ;
			$sth->execute($id) ;
			my $device = $sth->fetchall_arrayref();
			$sth->finish();
			$dbh->disconnect();
			template 'edit_network_device.tt', {
				'networks' => $networksHash,
				'device' => $device,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/models/edit/:id' => sub {
	my $dbh;
	if ((session 'logged_in') && (session 'user_can_read')) {
		$dbh = connect_db();
		my $id = params->{'id'};
		my $sth = $dbh->prepare("SELECT id, name_en FROM types") ;
		$sth->execute ;
		die if $sth->rows() < 1;
		my $typesHash = $sth->fetchall_hashref('id');
		$sth->finish();
		if ((request->method() eq "POST") && (session 'user_can_write')){
			$sth = $dbh->prepare("UPDATE models SET name = ?, type_id = ? WHERE id = ?") ;
			$sth->execute(params->{'model_name'}, 
						findIDModel('types', params->{'type_select'}),
						$id) ;
			$sth->finish();
			$dbh->commit ;
			$dbh->disconnect();
			redirect "/models/edit/$id";
		}else{
			$sth = $dbh->prepare("SELECT models.id, models.name AS m_name, 
								types.name_en AS t_name 
								FROM models, types
								WHERE models.type_id = types.id
								AND models.id = ?") ;
			$sth->execute($id) ;
			my $model = $sth->fetchall_arrayref();
			$sth->finish();
			$dbh->disconnect();
			template 'edit_model.tt', {
				'types' => $typesHash,
				'model' => $model,
				'logged' => 'true',
				'user' => session 'current_user'
			};
		}
	}else{
		redirect '/';
	}
};

any ['get', 'post'] => '/account_management' => sub {
	my $dbh;
	if(session 'logged_in'){
		$dbh = connect_db();
		if(request->method() eq "POST"){
			my $name = params->{"name"};
			my $sth = $dbh->prepare("UPDATE accounts SET rights = ? WHERE name = ?") ;
			$sth->execute(int(params->{"new_account_rights_$name"}), $name) ;
			$dbh->commit ;
			$sth->finish();
			$dbh->disconnect();
			redirect '/account_management';
		}else{
			if (not session 'user_is_admin'){
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
				$sth->execute() ; 
				$pages = int(($sth->rows()) / 10);
				$pages++ if ($sth->rows % 10) != 0;
				$sth->finish();
				$sth = $dbh->prepare("SELECT id, name, mail, rights FROM accounts
										LIMIT 10 OFFSET ?") ;
				$sth->execute($offset*10) ;
				my $accountsHash = $sth->fetchall_hashref('id');
				$sth->finish();
				$dbh->disconnect();
				my $curr_lang = session "user_current_lang";
				languages( [$curr_lang] );
				template 'account_management', {
					'accounts' => $accountsHash,
					'pages' => $pages,
					'curr_page' => $offset+1,
					'logged' => 'true',
					'user' => session 'current_user'
				};
			}
		}
	}else{
		redirect '/';
	}
};

true;