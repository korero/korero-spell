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



# Dependencies

1. Hunspell
2. Text::Hunspell from CPAN
3. [Mojolicious](http://mojolicio.us/)


## On Debian

```
sudo apt-get install libmojolicious-perl libtext-hunspell-perl
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


## On a Mac using Homebrew

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

## CPAN Trouble

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
