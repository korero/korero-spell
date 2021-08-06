#!/usr/bin/env perl
use Mojolicious::Lite;
use FindBin;
use I18N::LangTags::List;
use Text::Hunspell;
use File::Temp qw/tempfile/;
use Encode;
use utf8;

# Directories to look for dictionaries.
# Earlier directories have precedence.
my $home = "$FindBin::Bin";

# The path where espeak and lame can be found.
$ENV{PATH} = '/usr/bin:/usr/local/bin';

my @hunspell_dir = (
  # Our own Korero dictionaries
  "$home/rules",
  # Default hunspell directory for Debian Wheezy
  '/usr/share/hunspell',
  # Mac Homebrew system directory
  '/Library/Spelling/', # ignore ~/Library/Spelling/
  # Mac Libre Office
  '/Applications/LibreOffice.app/Contents/share/extensions/dict-*', # will be globbed
    );

# Global variable for all the languages and the location of their files.
# "en-US" => "/Applications/LibreOffice.app/Contents/share/extensions/dict-en/en_US".
# Initialized using load_languages.
my %languages;
# "en-US" => "US English".
my %language_names;

sub load_languages {
  my $app = shift;
  %languages = ();
  %language_names = ();
  my @files;
  # Reverse directory to make sure precedence is correct.
  for my $dir (map {glob "'$_'"} reverse @hunspell_dir) {
    $dir =~ s/^'(.*)'$/$1/;
    opendir(my $dh, $dir) || next;
    push(@files, map {"$dir/$_"} readdir($dh));
    closedir $dh;
  }

  my @dic = grep s/\.dic$//, @files;
  my %aff = map { $_ => 1; } grep s/\.aff$//, @files;

  for my $dic (@dic) {
    next unless $aff{$dic};
    my $code = $dic;
    $code =~ s/.*\///;
    $code =~ s/_/-/g;
    $languages{$code} = $dic;

    if ($code =~ /^[a-z]+(-[a-zA-Z]+)?$/) {
      $language_names{$code} = I18N::LangTags::List::name($code);
    }
    $language_names{$code} ||= $code;

    $app->log->info("Found dictionary $language_names{$code} ($code)");
  }

  die "Cannot find Hunspell dictionaries in any of the following directories:\n  "
      . join("\n  ", @hunspell_dir) . "\n" unless %languages;
}

# Global variable for all the voices. Keys are human-readable.
# "de" => "German"
# Initialized using load_voices.
my %voices;

sub load_voices {
  my $app = shift;
  %voices = ();

  open(my $fh, '-|', 'espeak --voices')
      or warn("Cannot determine espeak voices: $!");
  while(<$fh>) {
    my ($pty, $language, $gender, $name) = split;
    next unless $language =~ /^[a-z-]+$/;
    $name = join(' ', map { $_ eq 'en' ? 'English' : ucfirst }
		 split(/[ _-]+/, $name));
    $voices{$language} = $name;
    $app->log->info("Found voice $name");
  }
  close($fh);
}

get '/' => sub {
  my $self = shift;
  $self->render('index');
} => 'main';

get '/input' => sub {
  my $self = shift;
  $self->stash(languages => [ map { [ $language_names{$_} => $_ ] }
			      sort { $language_names{$a} cmp $language_names{$b} }
			      keys %language_names ],
	       voices => [ map { [ $voices{$_} => $_ ] }
			   sort { $voices{$a} cmp $voices{$b} }
			   keys %voices ] );
  $self->render('input');
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
  $self->stash(id => 'word0000');
  while ($text =~ /\G(.*?)$re/gs) {
    my ($stuff, $word) = ($1, $2);

    # handle the stuff between words
    if (length($stuff) > 0) {
      push(@tokens, $stuff);
    }

    my $encoded = $word;
    $encoded = encode($encoding, $word) if $encoding and $encoding ne 'UTF-8';
    if ($speller->check($encoded)) {
      push(@tokens, analysis_of($self, $speller, $encoding, $encoded, $word));
    } else {
      push(@tokens, suggestions_for($self, $speller, $encoding, $encoded, $word));
    }

    $last = pos($text);
  }

  # add any remaining stuff
  if ($last < length($text)) {
    push(@tokens, substr($text, $last));
  }

  return $self->render(json => {
    map {
      my ($type, $word, @suggestions) = @$_;
      $word => \@suggestions;
    } grep { ref($_) eq 'ARRAY' and $_->[0] eq 'misspelled' } @tokens})
      if $self->param('format')||'' eq 'json';

  $self->render(template => 'result', result => \@tokens);
};

get '/say' => sub {
  my $self = shift;
  my $outname = $self->flash('file') or return $self->redirect_to('input');
  my $asset = Mojo::Asset::File->new(path => $outname);
  $asset->cleanup(1);
  my $headers = $self->res->content->headers();
  $headers->add('Content-Type', 'audio/mpeg');
  $headers->add('Content-Length' => $asset->size);
  # Stream content directly from file
  $self->res->content->asset($asset);
  return $self->rendered(200);
};


post '/say' => sub {
  my $self = shift;
  my $text = $self->param('text') or return $self->redirect_to('input');
  my $voice = $self->param('voice') || 'en';
  $voice =~ /^[a-z-]+$/ or die "Illegal voice: $voice";
  my ($out, $outname) = tempfile("koreroXXXXXX", UNLINK => 0);
  open(my $fh, "| espeak -v $voice --stdin --stdout | lame --quiet --preset voice - $outname")
      or die "Cannot fork espeak/lame: $?";
  local $SIG{PIPE} = sub { die "Pipe to espeak/lame broke" };
  print $fh $text;
  $self->flash('file' => $outname);
  $self->redirect_to('say');
};

sub suggestions_for {
  my ($self, $speller, $encoding, $encoded, $word) = @_;
  my @suggestions = $speller->suggest($encoded);
  if ($encoding) {
    for (@suggestions) {
      $_ = decode($encoding, $_);
    }
  }
  return ['misspelled', $word, @suggestions];
}

sub analysis_of {
  my ($self, $speller, $encoding, $encoded, $word) = @_;
  my $analysis = join("\n", $speller->analyze($encoded));
  $analysis = decode($encoding, $analysis) if $encoding;
  return ['correct', $word, $analysis];
}

app->log->level('info');
app->log->info("Looking at $home");
load_languages(app);
load_voices(app);
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
<li><%= link_to 'Spell Checking and Text Reading' => 'input' %></li>
</ul>


@@ input.html.ep
% layout 'default';
% title 'Korero Spell Checking and Text Reading';
<h1>Spell Checking and Text Reading</h1>
<p>
Back to the <%= link_to 'main page' => 'main' %>.
<form method="POST">
<textarea name='text' autofocus='autofocus' required='required' maxlength='10000'></textarea>
<p>
<label for="lang">Languages:</label>
%= select_field lang => [@$languages]
<button formaction='/check'>Spell Check</button>
<p>
<label for="voice">Voices:</label>
%= select_field voice => [@$voices]
<button formaction='/say'>Say</button>
</form>


@@ result.html.ep
% layout 'default';
% title 'Korero Spell Checking';
%= javascript '/result.js'
%= javascript begin
function replace(id, event) {
  document.getElementById(id).textContent = event.target.textContent;
}
% end
<h1>Spell Checking</h1>
<p>
Check a <%= link_to 'different text' => 'input' %> or go back to <%= link_to 'main page' => 'main' %>.
%# onclick="" added so that iOS will react to :hover (and remove it from the menu)
<p class='result' onclick="">
% for my $token (@$result) {
%   if (not ref($token)) {
<%= $token %>\
%   } elsif (ref($token) eq 'ARRAY' and $token->[0] eq 'misspelled') {
%     my ($type, $word, @suggestions) = @$token;
<span id="<%= $id %>" class="<%= $type %>" onclick="">\
<span class="suggestions">\
%     for my $suggestion (@suggestions) {
<span class="suggestion" onclick="javascript:replace('<%= $id %>', event)"><%= $suggestion %></span>\
%     }
</span>\
<span class="word"><span><%= $word %></span></span>\
</span>\
%     $id++;
%   } elsif ($token->[0] eq 'correct') {
%     my ($type, $word, $analysis) = @$token;
<span class="<%= $type %>" title="<%= $analysis %>"><%= $word %></span>\
%   }
% }


@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet '/korero.css'
%= stylesheet begin
body {
  padding: 1em;
  font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif;
}
label { width: 10ex; display: inline-block; }
select { width: 30ex; }
button { width: 20ex; }
.result {
  border: 1px solid #333;
  padding: 0 1ex;
  font-family: sans-serif;
  min-height: 20ex;
  white-space: pre-wrap;
  // iOS: prevent flash when clicking on the paragraph
  -webkit-tap-highlight-color:rgba(0,0,0,0);
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
.misspelled:hover .suggestions {
  opacity: 1;
  visibility:visible;
  opacity:1;
  transition-delay:0s;
}
.misspelled .suggestions {
  position: absolute;
  border: 1px solid black;
  background-color: white;
  margin-top: 1.2em;
  visibility:hidden;
  opacity:0;
  transition:visibility 0s linear 1s, opacity 1s linear;
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
<meta name="viewport" content="width=device-width">
</head>
<body>
<%= content %>
<hr>
<p>
<%= link_to 'Korero' => 'main' %>&#x2003;<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a>&#x2003;<a href="https://alexschroeder.ch/cgit/korero/about/">Source</a>
</body>
</html>
