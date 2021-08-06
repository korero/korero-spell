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

# no file
$t->get_ok('/say')
    ->status_is(302); # temporarily

# no text!
$t->post_ok('/say' => form => {})
    ->status_is(302); # temporarily

$t->post_ok('/say' => form => {text => 'test'})
    ->status_is(302); # temporarily
$t->get_ok('/say')
    ->status_is(200) # but now there is a response
    ->header_is('Content-Type' => 'audio/mpeg');

done_testing();
