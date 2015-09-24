# Using It

Using the web interface is very easy and you can do that on the
[Korero](http://korero.org/) website.

If you want to write an application that needs do do spell checking,
you can use our JSON interface. Use a POST request and provide the
following:

* `text` is the text to check
* `lang` is the language to use
* `format=json` switches to the output from HTML to JSON

Here's how to test it from the command line:

```
curl http://korero.org/check \
     --form text="Ein Mensch und eine Fliege im Raum" \
     --form lang="en-US" \
	 --form format=json
```

The Result in this case – given that the text is in German and the language requested is US English:

```json
{
  "eine":  ["wine","seine","Seine","Reine","Heine","sine","nine","tine","line","cine","dine","mine","pine","fine","vine"],
  "Ein":   ["In","Erin","Edin","Evin","Sin","Tin","Din","Gin","Min","Pin","Bin","Yin","Fin","Kin","Win"],
  "und":   ["ind","undo","fund","Lund","dun","end","and","Ind","undue","under","unit"],
  "Raum":  ["Ram","Raul","Ra um","Ra-um","Arum","Rum","Trauma","Radium","Maura","Umbra","Roam","RAM"],
  "im":    ["mi","um","om","in","i","m","ism","aim","rim","dim","imp","him","vim","Sim","Tim"],
  "Fliege":["Liege","F liege","Flinger","Flier","Fledge","Flicker","Flexed"]
}
```

# Running It

This application uses [Mojolicious](http://mojolicio.us/).
While you're developing the application:

```
morbo server.pl
```

This will run the server on port 3000. Visit `http://localhost:3000`
to test it. As soon as you edit the file, `morbo` will restart the
server. You just need to reload the page to see any changes you made.

Learn more: [Mojolicious::Guides::Tutorial](http://mojolicio.us/perldoc/Mojolicious/Guides/Tutorial).


# Deploying It

Use [Hypnotoad](http://mojolicio.us/perldoc/Mojo/Server/Hypnotoad)
which is part of [Mojolicious](http://mojolicio.us/).

```
hypnotoad server.pl
```

Verify that it is working by visiting `http://localhost:8081`.  Port
8080 is the default port for Hypnotoad but `server.pl` changes the
port to 8081.

If you're using Apache, configure your virtual server to act as a
proxy and pass requests through to port 8081. Make sure you have
`mod_proxy` and `mod_proxy_http`enabled.  Our setup also uses an extra
header. Thus, you also need `mod_headers`.

```
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod headers
sudo service apache2 restart
```

Once this works, you need to write a config file for your site. Here's
ours:

```
<VirtualHost *:80>
    ServerAdmin kensanata@gmail.com
    ServerName korero.org
    ServerAlias www.korero.org
    <Proxy *>
	Order deny,allow
	Allow from all
    </Proxy>
    ProxyRequests Off
    ProxyPreserveHost On
    ProxyPass / http://korero.org:8081/ keepalive=On
    ProxyPassReverse / http://korero.org:8081/
    RequestHeader set X-Forwarded-Proto "http"
</VirtualHost>
```

Reload your Apache config using `sudo service apache2 graceful`.

This is based on the
[Mojolicious Cookbook](http://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#Apache-mod_proxy).

And finally, if you're using [Monit](https://mmonit.com/monit/) to
monitor your server, here's an example of how you could set it up
including statements to start and stop the server.

```
## http://www.howtoforge.com/server-monitoring-with-munin-and-monit-on-debian-wheezy-p2

# Only restart when the website is unreachable for 10 minutes!
check process korero-spell with pidfile /home/alex/korero.org/hypnotoad.pid
    start program = "/usr/bin/hypnotoad /home/alex/korero.org/server.pl"
    stop program = "/usr/bin/hypnotoad --stop /home/alex/korero.org/server.pl"
    if failed host localhost port 8081 type tcp protocol http
      and request "/" for 5 cycles then restart
    if totalmem > 500 MB for 5 cycles then restart
    if 3 restarts within 15 cycles then timeout
```


# Dependencies

1. Hunspell
2. Text::Hunspell from CPAN
3. [Mojolicious](http://mojolicio.us/)


## On Debian

```
sudo apt-get install libmojolicious-perl libtext-hunspell-perl
```

Note that `libmojolicious-perl` is too old on Debian Wheezy. You can
try to install it anyway, but if it fails, you'll have to install the
latest from CPAN:

```
cpan Mojolicious
```

You also need to install some dictionaries. These should all end up in
`/usr/share/hunspell`. You might want to try something like the
following:

```
sudo apt-get install hunspell-an hunspell-ar hunspell-be \
    hunspell-da hunspell-de-de hunspell-de-at hunspell-de-ch \
    hunspell-en-us hunspell-en-ca hunspell-eu-es hunspell-fr \
    hunspell-gl-es hunspell-hu hunspell-kk hunspell-ko hunspell-ml \
    hunspell-ne hunspell-ro hunspell-ru hunspell-se hunspell-sh \
    hunspell-sr hunspell-sv-se hunspell-uz hunspell-vi
```

This will result in files like `de_CH.dic` and `de_CH.aff` in
`/usr/share/hunspell`. We need both of these files in order to
recognize a valid language.


## On a Mac

### Hunspell using Homebrew

If you're using [Homebrew](http://brew.sh/), `brew install hunspell`
and note the following:

```
Dictionary files (*.aff and *.dic) should be placed in
~/Library/Spelling/ or /Library/Spelling/. Homebrew itself provides no
dictionaries for Hunspell, but you can download compatible
dictionaries from other sources, such as
https://wiki.openoffice.org/wiki/Dictionaries .
```

If you already have Libre Office installed, the files are easy to find.

```
alex@Megabombus:~$ locate en_US.aff
/Applications/LibreOffice.app/Contents/share/extensions/dict-en/en_US.aff
```

The files will all be in
`/Applications/LibreOffice.app/Contents/share/extensions/dict-*` and
the files will end in `*.aff` and `*.dic`.

### Perl using Perlbrew

I'm using [Perlbrew](http://perlbrew.pl/) to install a new Perl and
run it alongside the system default. If you follow the instructions,
you'll end up with the following line in your `~/.bashrc`:

```
source ~/perl5/perlbrew/etc/bashrc
```

Just remember that if you write CGI scripts or similar things, you can
no longer rely on the shebang line `#!/usr/bin/perl` – you'll be using
something like
`#!/Users/alex/perl5/perlbrew/perls/perl-5.18.2/bin/perl` instead.

### Text::Hunspell using CPAN

When installing from CPAN, `Text::Hunspell` wouldn't install:

```
...
Running test for module 'Text::Hunspell'
  COSIMO/Text-Hunspell-2.11.tar.gz
  Has already been unwrapped into directory /Users/alex/.cpan/build/Text-Hunspell-2.11-XRrGMO
  COSIMO/Text-Hunspell-2.11.tar.gz
  No 'Makefile' created
, not re-running
CPAN: CPAN::Meta loaded ok (v2.150005)
```

I did it manually:

```
alex@Megabombus:~$ cd /Users/alex/.cpan/build/Text-Hunspell-2.11-XRrGMO/
alex@Megabombus:~/.cpan/build/Text-Hunspell-2.11-XRrGMO$ perl Makefile.PL 
Checking if your kit is complete...
Looks good
Generating a Unix-style Makefile
Writing Makefile for Text::Hunspell
Writing MYMETA.yml and MYMETA.json
alex@Megabombus:~/.cpan/build/Text-Hunspell-2.11-XRrGMO$ make
...
alex@Megabombus:~/.cpan/build/Text-Hunspell-2.11-XRrGMO$ make test
...
All tests successful.
Files=5, Tests=17,  0 wallclock secs ( 0.06 usr  0.03 sys +  0.19 cusr  0.05 csys =  0.33 CPU)
Result: PASS
alex@Megabombus:~/.cpan/build/Text-Hunspell-2.11-XRrGMO$ make install
...
```

### Mojolicious using CPAN

```
cpan Mojolicious
```

