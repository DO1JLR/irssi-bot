#!/usr/bin/perl
use JSON;                       # Zum verwenden der nodes.json
use LWP::Simple;                # Zum testen, wie die nodes.json aussieht, wird aber gerade nicht benötigt...
use Data::Dumper;				# Ausgabe der json zum testen (produktiv nicht benoetigt)
use strict;                     # Good practice
use warnings;                   # Good practice
use Irssi;                      # Für den Bot
use vars qw($VERSION %IRSSI);
$VERSION = "1.0";
%IRSSI = (
        authors         => "L3D",
        contact         => 'l3d@see-base.de',
        name            => "Freifunk Bot",
        description     => "Ein Freifunk-IRC-Bot, der interessante Fakten des Freifunkes in den IRC pasten kann.",
        version         => "0.0.4",
		status			=> "alpha",
        license         => "GPL"
);
# important Variables:
our $channelName = "ffbsee"; #Operate in this channel !1ELF
our $secoundChannel = "see-base-talk"; #A 2. channel for testing...
our $url = "http://vpn3.ffbsee.de/nodes.json"; #Link zur nodes.json
our $path = "/var/www/modes.json"; #Pfad zur nodes.json


Irssi::signal_add 'message public', 'sig_message_public';
our @node_name;   # Global Array for Node-Names
our $anzahl;      # How many nodes exist
our $clients;     # How many Clients are connected...


sub sig_message_public {
    my ($server, $msg, $nick, $nick_addr, $target) = @_;
    if ($target =~ m/#(?:$channelName|$secoundChannel)/) { # only operate in these channels
                # different messages to do something:
                if ($msg =~ m/!help/i){ #Reagiert auf "!help"
                $server->command("msg $nick Hey $nick, auf folgende Nachrichten reagiere ich:");
                        $server->command("msg $nick !help - ruft diese Hilfe auf!");
                        $server->command("msg $nick !node - Sagt, wie viele Nodes gerade online sind!");
                        $server->command("msg $nick !name - Sagt die namen, der Nodes, die gerade online sind!");
			$server->command("msg $nick !top  - Zeigt die Top 5 Nodes mit den meisten Clients");
		}
                if ($msg =~ m/!node/i){ #Reagiert auf "!node"
                       nodes(); #Ruft node() auf um eine aktuelle Zahl der nodes zu bekommen
                       $server->command("msg $target Es sind aktuell $anzahl Nodes online!");
                       $server->command("script load nodes.pl"); #Läd das script neu, da es sonst irgendwie immer abgestürzt ist...
                }
                if ($msg =~ m/!name/i){ #Reagiert auf "!name"
                        nodes();
                        $server->command("msg $target Folgende $anzahl Nodes sind aktuell online:");
                        $server->command("msg $target @node_name");
                        $server->command("script load nodes.pl");
                }
				if ($msg =~ m/!top/i) { #Reagiert auf "!top"
						nodes();
						#Hier könnte ausgewertet werden, wieviele Clients bei welchen Knoten sind oder so...
				}
        }
}


#Hier werden die Informationen aus der nodes.json geholt...
sub nodes{
		my $name;
my $json_text;
#		my $json_text = get( $url );   # Download the nodes.json

open(DATEI, "/var/www/nodes.json") || die "Datei wurde nicht gefunden\n";
while((my $zeichen = getc(DATEI)) ne "") {
#  print $zeichen;
$json_text .= $zeichen;
}
close(DATEI);


		my $json        = JSON->new->utf8; #force UTF8 Encoding
		my $perl_scalar = $json->decode( $json_text ); #decode nodes.json
		$anzahl = 0; #Resette Anzahl auf 0
		my $anzanhl_korrektur = 0;
		#	print Dumper $perl_scalar;
		my $json_list = $perl_scalar->{"nodes"}->[$anzahl]->{"name"};
		while (defined $json_list){
                $json_list = $perl_scalar->{"nodes"}->[$anzahl]->{"name"} ; # Suche nach "name" in der node.json
				if ( not defined $json_list){ #Falls der $name nicht gesetzt wurde!
				$anzahl = $anzahl + 1;
				$anzanhl_korrektur = $anzanhl_korrektur + 1;
				$json_list = $perl_scalar->{"nodes"}->[$anzahl]->{"name"};
						if ( not defined $json_list){ #Falls der $name nicht gesetzt wurde!
						$anzahl = $anzahl + 1;
						$anzanhl_korrektur = $anzanhl_korrektur + 1;
						$json_list = $perl_scalar->{"nodes"}->[$anzahl]->{"name"};	
						}
				}
				else {
						$anzanhl_korrektur = 0;
						push(@node_name, "$json_list, "); #Füge die Node-Names dem Array zu.
						$anzahl = $anzahl + 1;
				}
		}
		$anzahl = $anzahl - $anzanhl_korrektur;
		@node_name = sort @node_name;
}
