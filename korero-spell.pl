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
use CGI qw/-utf8/;
use CGI::Carp qw(fatalsToBrowser);
use Text::Hunspell;

main();

sub main {
  my $q = CGI->new;
  print $q->header,
  $q->start_html('hello world'),
  $q->h1('hello world'),
  $q->end_html;
}
