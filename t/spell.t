use Test::More;
use Test::Mojo;
use strict;
use warnings;

use FindBin;

# Fix path for 'perl t/spell.t'
$ENV{MOJO_HOME} = "$FindBin::Bin/..";
require "$FindBin::Bin/../server.pl";

my $t = Test::Mojo->new;

$t->get_ok('/')
    ->status_is(200)
    ->content_like(qr/Korero/);

$t->get_ok('/check')
    ->status_is(200)
    ->content_like(qr/Languages:/,
		   'has Languages')
    ->content_like(qr/<option value="rm-sursilv">rm-sursilv<\/option>/,
		   'lists the rm-sursilv dictionary');

$t->post_ok('/check' => form => {
  text => "Ein Mensch\nund eine Fliege\nim Raum",
  lang => 'rm-sursilv'})
    ->status_is(200)
    ->content_like(qr/<span class="word"><span>Mensch<\/span><\/span>/,
		   '"Mensch" is misspelled')
    ->content_like(qr/<span class="suggestion" onclick=".*">Aschamein<\/span>/,
		   '"Aschamein" is a suggestion');

$t->post_ok('/check' => form => {
  text => "Ein Mensch\nund eine Fliege\nim Raum",
  lang => 'rm-sursilv',
  format => 'json'})
    ->status_is(200)
    ->json_is('/Mensch/0' => 'Aschamein',
              'found "Aschamein" as a suggestion for "Ein" in JSON document');


done_testing();
