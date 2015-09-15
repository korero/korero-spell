#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::ByteStream;
use Text::Hunspell;
use utf8;

# plugin 'TagHelpers';

my $hunspell_dir = '/usr/share/hunspell';
my %languages;

sub load_languages {
    opendir(my $dh, $hunspell_dir) || die "can't opendir $hunspell_dir: $!";
    my @files = readdir($dh);
    closedir $dh;

    my @dic = grep { s/\.dic$//; } @files;
    my %aff = grep { s/\.aff$//; $_ => 1 } @files;

    for my $dic (@dic) {
	next unless $aff{$dic};
	my $label = $dic;
	$label =~ s/_/-/g;
	$languages{$label} = $dic;
    }	
}

get '/' => sub {
    my $self = shift;
    $self->render('index');
} => 'main';

get '/check' => sub {
    my $self = shift;
    $self->stash(languages => [sort keys %languages]);
    $self->render('check');
};

post '/check' => sub {
    my $self = shift;
    my $text = $self->param('text');
    my $lang = $languages{$self->param('lang')} || 'en_US';
    my $speller = Text::Hunspell->new(
	"/usr/share/hunspell/$lang.aff",    # Hunspell affix file
	"/usr/share/hunspell/$lang.dic"     # Hunspell dictionary file
	);
    die unless $speller;
    
    # What's a word? $1 is a word.
    my $re;
    $re = qr/(\w+(:?'\w+)*)/ if $lang =~ /^en/; # "isn't it"
    $re = qr/(\w+)/ unless $re;

    my @tokens;
    my $last = 0;
    while ($text =~ /\G(.*?)$re/gs) {
	my ($stuff, $word) = ($1, $2);

	# handle the stuff between words
	if (length($stuff) > 0) {
	    push(@tokens, $stuff);
	}

	if ($speller->check($word)) {
	    push(@tokens, $word);
	} else {
	    push(@tokens, suggestions_for($word));
	}

	$last = pos($text);
    }

    # add any remaining stuff
    if ($last < length($text)) {
	push(@tokens, substr($text, $last));
    }

    $self->render(template => 'result', result => \@tokens);
};

sub suggestions_for {
    my $word = shift;
    # FIXME: do something
    my $html = "<b>$word</b>";
    return Mojo::ByteStream->new($html);
}

load_languages();
app->start;

__DATA__

@@ index.html.ep
% layout 'default';
% title 'Korero';
<h1>Korero</h1>
<blockquote>
<b>kōrero</b>: <i>speech, narrative, story, news, account, discussion, conversation, discourse, statement, information</i><br>
<span style="font-size:80%">– <a href="http://www.maoridictionary.co.nz/search?keywords=korero">Te Aka Online Māori Dictionary</a></span>
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
<label for="lang">Languages:</label>
%= select_field lang => [@$languages]
<p>
<input type="submit">
</form>


@@ result.html.ep
% layout 'default';
% title 'Korero Spellchecking';
<h1>Korero Spellchecking</h1>
<p>
Check a <%= link_to 'different text' => 'check' %> or go back to <%= link_to 'main page' => 'main' %>.
<p class='result'>
% for my $token (@$result) {
<%= $token %>\
% }

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head><title><%= title %></title></head>
<body>
<style type="text/css">
body {
      padding: 1em;
}
.result {
  border: 1px solid #333;
  padding: 0 1ex;
  font-family: sans-serif;
  min-height: 20ex;
  white-space: pre-wrap;
}
textarea {
  width: 100%;
  height: 30em;
}
</style>
<%= content %>
<hr>
<p>
Contact: <a href="mailto:kensanata@gmail.com">Alex Schroeder</a>&#x2003;<a href="https://github.com/korero/korero-spell">Source on GitHub</a>
</body>
</html>
