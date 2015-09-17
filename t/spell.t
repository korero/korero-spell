use Test::More;
use Test::Mojo;
use strict;
use warnings;

use FindBin;
require "$FindBin::Bin/../server.pl";

my $t = Test::Mojo->new;

$t->get_ok('/')
    ->status_is(200)
    ->content_like(qr/Korero/);

our %languages;
load_languages();
ok($languages{'en-US'},
   'an US English dictionary was found');

$t->get_ok('/check')
    ->status_is(200)
    ->content_like(qr/Languages:/,
		   'has Languages')
    ->content_like(qr/<option value="en-US">en-US<\/option>/,
		   'lists US English');

$t->post_ok('/check' => form => {
  text => "Ein Mensch\nund eine Fliege\nim Raum",
  lang => 'en-US'})
    ->status_is(200)
    ->content_like(qr/<span class="word"><span>Ein<\/span><\/span>/,
		   '"Ein" is misspelled')
    ->content_like(qr/<span class="suggestion" onclick=".*">In<\/span>/,
		   '"In" is a suggestion');

$t->post_ok('/check' => form => {
  text => "Ein Mensch\nund eine Fliege\nim Raum",
  lang => 'en-US',
  format => 'json'})
    ->status_is(200)
    ->json_is('/Ein/0' => 'In',
              'found "In" as a suggestion for "Ein" in JSON document');


done_testing();
