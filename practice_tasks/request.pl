use WWW::Mechanize;
use strict;
use Data::Dumper;

my $mail = 'martin.iv96@gmail.com';
my $password = 'shell_script';

my $mech = WWW::Mechanize->new();

$mech->get("http://shop.optimalprint.bg/index.php?route=account/login");
$mech->form_id('login');
$mech->field("email", $mail);
$mech->field("password", $password);
$mech->submit_form();

$mech->get("http://shop.optimalprint.bg/index.php?route=product/product&path=73_76&product_id=452");
$mech->form_id('product');
$mech->field("quantity",10);
my $response = $mech->submit_form();

$mech->get("http://shop.optimalprint.bg/index.php?route=checkout/shipping");
$mech->form_id("shipping");
print Dumper($mech->field("shipping_method", "econt.econt"));
print Dumper($mech->find_all_inputs());
print Dumper($mech->field("shipping_method", "econt.econt"));
# $mech->set_fields("shipping_method", ["econt.econt", 1]);
print Dumper($mech->set_fields("shipping_method" => "econt.econt"));
# sleep 5;
# TODO - FIND A WAY TO TOOGLE THE econt.econt radio button 
$mech->form_id('econt_form');
$mech->field("company", "Telebid Pro");
$mech->field("postcode", 1000);
$mech->field("city", "Sofiya");
$mech->field("quarter", "kv. Strelbishte");
$mech->field("street", "bul. Gotse Delchev");
$mech->field("street_num", 103);
$mech->submit_form();

