#!/usr/bin/env perl
use Mojolicious::Lite;
use Text::Hunspell;
use utf8;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
    my $self = shift;
    $self->render('index');
} => 'main';

get '/check' => sub {
    my $self = shift;
    $self->render('check');
};

post '/check' => sub {
    my $self = shift;
    my $text = $self->param('text');
    # FIXME: do something interesting here
    $self->render(template => 'result', result => $text);
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Korero';
<h1>Korero</h1>
<blockquote>
<b>kōrero</b>: <i>speech, narrative, story, news, account, discussion, conversation, discourse, statement, information</i><br>
– <a href="http://www.maoridictionary.co.nz/search?keywords=korero">Te Aka Online Māori Dictionary</a>
</blockquote>
<p>Welcome! Korero is a Swiss non-profit association supporting language with technical services.
Our emphasis is on minority languages.
<p>Services:</p>
<ul>
<li><%= link_to 'Spellchecking' => 'check' %></li>
</ul>

@@ check.html.ep
% layout 'default';
% title 'Korero Spellchecking';
<h1>Korero Spellchecking</h1>
<p>
Back to the <%= link_to 'main page' => 'main' %>.
<form method="POST" action="/check">
<textarea name='text' autofocus='autofocus' required='required' maxlength='10000'></textarea>
<p>
<input type="submit">
</form>

@@ result.html.ep
% layout 'default';
% title 'Korero Spellchecking';
<h1>Korero Spellchecking</h1>
<p>
Back to the <%= link_to 'main page' => 'main' %>.
<p class='result'>
<%= $result %>

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head><title><%= title %></title></head>
<style type="text/css">
body {
      padding: 1em;
}
.result {
  border: 1px solid #333;
  padding: 1ex;
  min-height: 20ex;
}
textarea {
  width: 100%;
  height: 30em;
}
</style>
<body>
<%= content %>
<hr>
<p>
Contact: <a href="mailto:kensanata@gmail.com">Alex Schroeder</a>&#x2003;<a href="https://github.com/korero/korero-spell">Source on GitHub</a>
</body>
</html>
