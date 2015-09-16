#!/usr/bin/env perl
use Mojolicious::Lite;
use Mojo::ByteStream;
use Text::Hunspell;
use Encode;
use utf8;

# directories to look for dictionaries
my @hunspell_dir = (
  '/usr/share/hunspell',
  # Mac
  '/Library/Spelling/', # ignore ~/Library/Spelling/
  # Office
  '/Applications/LibreOffice.app/Contents/share/extensions/dict-*', # will be globbed
    );
my %languages;

sub load_languages {
  my @files;
  for my $dir (map {glob "'$_'"} @hunspell_dir) {
    $dir =~ s/^'(.*)'$/$1/;
    opendir(my $dh, $dir) || next;
    push(@files, map {"$dir/$_"} readdir($dh));
    closedir $dh;
  }

  my @dic = grep s/\.dic$//, @files;
  my %aff = map { $_ => 1; } grep s/\.aff$//, @files;

  for my $dic (@dic) {
    next unless $aff{$dic};
    my $label = $dic;
    $label =~ s/.*\///;
    $label =~ s/_/-/g;
    $languages{$label} = $dic;
  }

  die "Cannot find Hunspell dictionaries in any of the following directories:\n  "
      . join("\n  ", @hunspell_dir) . "\n" unless %languages;

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
  my $lang = $self->param('lang') || 'en-US';
  my $base = $languages{$lang};
  my $speller = Text::Hunspell->new("$base.aff", "$base.dic");
  die unless $speller;

  my $encoding;
  open(my $fh, '<', "$base.aff");
  while (my $line = <$fh>) {
    if ($line =~ /^SET\s+(\S+)/) {
      $encoding = $1;
      last;
    }
  }

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

    my $encoded = $word;
    $encoded = encode($encoding, $word) unless $encoding eq 'UTF-8';
    if ($speller->check($encoded)) {
      push(@tokens, $word);
    } else {
      push(@tokens, suggestions_for($self, $speller, $encoding, $encoded, $word));
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
  my ($self, $speller, $encoding, $encoded, $word) = @_;
  my @suggestions = $speller->suggest($encoded);
  if ($encoding) {
    for (@suggestions) {
      $_ = decode($encoding, $_);
    }
  }
  my $html = $self->render_to_string(
    template => 'misspelled_word',
    word => $word,
    suggestions => \@suggestions, );
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


@@ misspelled_word.html.ep
<span class="misspelled">\
<span class="suggestions">\
% for my $suggestion (@$suggestions) {
<span class="suggestion"><%= $suggestion %></span>\
% }
</span>\
<span class="word"><span><%= $word %></span></span>\
</span>\

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/korero.css'
%= stylesheet begin
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
/* fake red wave underline */
.misspelled .word {
  border-bottom: 1px dotted #ff0000;
  padding:1px;
}
.misspelled .word span {
  border-bottom: 1px dotted #ff0000;
}
/* menu for suggestions */
.misspelled .suggestions {
  display: none;
}
.misspelled:hover .suggestions {
  display: block;
}
.misspelled .suggestions {
  position: absolute;
  border: 1px solid black;
  background-color: white;
  margin-top: 0.2ex;
}
.misspelled .suggestion {
  display: block;
  padding: 0.2ex 1ex;
}
.misspelled .suggestion:hover {
  background-color: #b0e0e6;
}
textarea {
 width: 100%;
 height: 30em;
}
% end
</head>
<body>
<%= content %>
<hr>
<p>
Contact: <a href="mailto:kensanata@gmail.com">Alex Schroeder</a>&#x2003;<a href="https://github.com/korero/korero-spell">Source on GitHub</a>
</body>
</html>
