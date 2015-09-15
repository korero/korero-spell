# Dependencies

1. Hunspell
2. Text::Hunspell from CPAN

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
