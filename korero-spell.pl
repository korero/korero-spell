#! /usr/bin/perl
# Copyright (C) 2015  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

package Korero::Spell;
use strict;
use warnings;
use utf8;
use CGI qw/-utf8 no_xhtml/;
use CGI::Carp qw(fatalsToBrowser);
use Text::Hunspell;

main();

sub main {
  my $q = CGI->new;
  if ($q->path_info eq '/check') {
  } else {
    print $q->header,
    $q->start_html(-title => 'Korero Spell', -dtd => 'html'),
    $q->h1('Korero Spell'),
    $q->p(T('This website allows you to do spell-checking using %s.',
	  $q->a({-href=>'http://hunspell.sourceforge.net/'}, 'Hunspell')),
	  T('With it, we\'re trying to show how useful our dictionaries and word lists can be.'),
	);
    $q->end_html;
  }
}

sub T {
  my ($template, @args) = @_;
  # TODO: Translate $template
  return sprintf($template, @args);
}
