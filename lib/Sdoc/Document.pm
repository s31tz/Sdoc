# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Document - Sdoc-Dokument

=head1 BASE CLASS

L<Sdoc::Core::Object>

=head1 SYNOPSIS

  use Sdoc::Document;
  
  my $doc = Sdoc::Document->parse($input);
  print $doc->generate('html');
  print $doc->generate('latex');
  print $doc->generate('mediawiki');
  print $doc->generate('tree');

=head1 DESCRIPTION

Diese Klasse implementiert die Klassenmethode parse(), mit der ein
Sdoc-Dokument in einen Parsingbaum überführt wird. Die Methode
liefert den Wurzelknoten auf diesen Parsingbaum zurück. Der
Wurzelknoten ist vom Typ Sdoc::Node::Document. Alle weiteren
Methoden, um auf dem Parsingbaum zu operieren, implementiert die
Klasse Sdoc::Node::Document oder deren Basisklasse Sdoc::Node.

=cut

# -----------------------------------------------------------------------------

package Sdoc::Document;
use base qw/Sdoc::Core::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Node::BridgeHead;
use Sdoc::Node::Code;
use Sdoc::Node::Comment;
use Sdoc::Node::Document;
use Sdoc::Node::Format;
use Sdoc::Node::Graphic;
use Sdoc::Node::Include;
use Sdoc::Node::Item;
use Sdoc::Node::Link;
use Sdoc::Node::List;
use Sdoc::Node::PageBreak;
use Sdoc::Node::Paragraph;
use Sdoc::Node::PostProcessor;
use Sdoc::Node::Quote;
use Sdoc::Node::Section;
use Sdoc::Node::Segment;
use Sdoc::Node::Style;
use Sdoc::Node::Table;
use Sdoc::Node::TableOfContents;
use Sdoc::Core::Option;
use Sdoc::Core::Path;
use Sdoc::Core::Shell;
use Sdoc::LineProcessor;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 parse() - Parse Sdoc-Dokument

=head4 Synopsis

  $doc = $class->parse($file,@opt);
  $doc = $class->parse(\$str,@opt);
  $doc = $class->parse(\@lines,@opt);

=head4 Arguments

=over 4

=item $file

Sdoc-Quelltext in einer Datei. Existiert neben der Datei $file
ein Programm mit dem gleichen Grundnamen, aber der Extension
'.srun' (wenn $file die Endung '.sdoc' hat) oder '.srun3' (wenn
$file die Endung '.sdoc3' hat), wird dieses vor Beginn des
Einlesens der Sdoc-Datei $file ausgeführt.

=item $str

Sdoc-Quelltext als Zeichenkette.

=item @lines

Sdoc-Quelltest als Array von Zeilen.

=item @opt

Liste von Optionen.

=back

=head4 Options

=over 4

=item -configH => $conf

Referenz auf ein Objekt der Klasse Sdoc::Core::Hash, das
die Werte einer Konfigurationsdatei enthält.

=item -markup => $markup (Default: 'sdoc')

Markup-Variante. Mögliche Werte: 'sdoc'.

=item -quiet => $bool (Default: 0)

Gib keine Warnungen aus.

=item -userH => $opt

Referenz auf ein Objekt der Klasse Sdoc::Core::Hash, das
Aufruf-Optionen des Benutzers enthält.

=back

=head4 Returns

Referenz auf Dokument-Knoten (Typ: Sdoc::Node::Document)

=head4 Description

Parse ein Sdoc-Dokument und liefere eine Referenz auf
den Wurzelknoten des Parsingbaums zurück.

=cut

# -----------------------------------------------------------------------------

sub parse {
    my $class = shift;
    my $input = shift;
    # @_: @opt

    # Optionen

    my $configH = undef;
    my $markup = 'sdoc';
    my $quiet = 0;
    my $shellEscape = 0;
    my $userH = undef;

    Sdoc::Core::Option->extract(\@_,
        -configH => \$configH,
        -markup => \$markup,
        -quiet => \$quiet,
        -shellEscape => \$shellEscape,
        -userH => \$userH,
    );

    # Dokument kommt aus einer Datei

    if (!ref $input) {
        my $p = Sdoc::Core::Path->new;

        # Relativen Pfad in absoluten Pfad wandeln
        $input = $p->absolute($input);

        # Vorverarbeitungs-Programm aufrufen (falls existent)

        my $ext = $p->extension($input) eq 'sdoc3'? 'srun3': 'srun';
        my $program = $p->basePath($input).".$ext";
        if (-e $program) {
            (my $dir,$program) = $p->split($program);
            Sdoc::Core::Shell->exec("(cd $dir; ./$program)");
        }
    }

    # Instantiiere LineProcessor

    my $par = Sdoc::LineProcessor->new($input,
        -encoding => 'utf-8',
        -lineContinuation => 'backslash',
        -skip => qr/^#/,
    );

    # Instantiiere den Dokument-Knoten. Dieser bildet die
    # Wurzel des Sdoc-Parsingbaums.

    my $doc = Sdoc::Node::Document->new(undef,$par,undef,undef);
    $doc->set(
        configH => $configH,
        input => $input,
        quiet => $quiet,
        shellEscape => $shellEscape,
        userH => $userH,
    );
    $doc->weaken(root=>$doc); # Verweis auf sich selbst

    # Sdoc-Quelltext in Parsingbaum überführen

    my $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant) = $par->nextType(1);
        $doc->push(childA=>$nodeClass->new($variant,$par,$doc,$doc));
    }

    # Erzeuge TableOfContens-Knoten, wenn nicht existiert und per
    # Default erzeugt werden soll
    $doc->createTableOfContentsNode;

    # Kennzeichne Appendix-Abschnitte
    $doc->flagSectionsAsAppendix;

    # Kennzeichne Abschnitte, die nicht im Inhaltsverzeichnis
    # erscheinen sollen
    $doc->flagSectionsNotToc;

    # Löse L-Segmente (Links) auf
    $doc->resolveLinks;

    # Löse G-Segmente (Inline-Grafiken) auf
    $doc->resolveGraphics;

    # Prüfe alle Knoten des Dokuments

    for my $node ($doc->nodes) {
        $node->validate;
    }

    return $doc;
}

# -----------------------------------------------------------------------------

=head3 sdoc2ToSdoc3() - Konvertiere Sdoc2-Code in Sdoc3-Code

=head4 Synopsis

  $code = $class->sdoc2ToSdoc3($code);

=head4 Arguments

=over 4

=item $code (String)

Sdoc2-Code

=back

=head4 Returns

Sdoc3-Code (String)

=head4 Description

Wandele Sdoc2-Code in Sdoc3-Code und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub sdoc2ToSdoc3 {
    my ($class,$code) = @_;

    # Sonderfälle
    $code =~ s|IMGDIR|/home/fs2/opt/blog/image|g;

    # Blöcke konvertieren

    my $subBlock = sub {
        my ($name,$block) = @_;
        # warn "---\n$block";
        
        if ($name eq 'Document') {
            $block =~ s/ +generateAnchors=\S+\n?//;
            $block =~ s/ +utf8=\S+\n?//;
        }
        elsif ($name eq 'Figure') {
            $block =~ s/%Figure:/%Graphic:/;
            # $block =~ s/file=/source=/;
            $block =~ s/url=/link=/;
        }
        elsif ($name eq 'Code') {
            $block =~ s/highlight=/lang=/;
        }

        # warn "---\n$block";
        return $block;
    };

    $code =~ s/(%([A-Za-z]+):(( +[A-Za-z\d]+=.*)?\n)+)/$subBlock->($2,$1)/eg;

    # Segmente konvertieren

    my $links = '';
    my $gCount = 0;
    my $graphics = '';

    my $subSegment = sub {
        my ($segment,$content) = @_;

        # Zeilenfortsetzungen auflösen
        (my $line = $content) =~ s/\\\n\s*//g;

        warn sprintf "---IN---\n%s{%s}\n",$segment,$line;

        # Argument und Optionen auflösen

        my ($arg,%opt);
        if ($line =~ s/^"(.*?)"//) {
            $arg = $1;
            %opt = $line =~ /(\w+)="(.*?)"/g;
        }
        else {
            $arg = $line;
        }

        # Segmente umschreiben

        my $text;
        if ($segment eq 'U') {
            if (my $name = $opt{'text'}) {
                $text = sprintf '%s{%s}','L',$name;
                if ($links) {
                    $links .= "\n";
                }
                $links .= qq|%Link:\n  name="$opt{'text'}"\n  url="$arg"\n|;
            }
            else {
                $text = sprintf '%s{%s}','L',$arg;
            }
        }
        elsif ($segment eq 'G') {
            my $name = sprintf 'Graphic%s',++$gCount;

            $text = sprintf '%s{%s}','G',$name;

            if ($graphics) {
                $graphics .= "\n";
            }
            $graphics .= sprintf qq|%%Graphic:\n  name="%s"\n  file="%s"\n|,
                $name,$arg;
            for my $key (sort keys %opt) {
                $graphics .= sprintf qq|  %s="%s"\n|,$key,$opt{$key};
            }
        }
        else {
            # Keine Änderung
            $text = sprintf '%s{%s}',$segment,$content;
        }
        
        if ($text) {
            warn sprintf "---OUT---\n%s\n",$text;
        }

        return $text;
    };

    $code =~ s/(([GLlU])\{([^}]+)\})/$subSegment->($2,$3)/eg;

    if ($graphics) {
        warn "---GRAPHICS---\n$graphics";
        $code =~ s/\s*\n# eof\n\s*$/\n/;
        $code .= "\n$graphics\n# eof\n";
    }
    if ($links) {
        warn "---LINKS---\n$links";
        $code =~ s/\s*\n# eof\n\s*$/\n/;
        $code .= "\n$links\n# eof\n";
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 foswikiToSdoc3() - Konvertiere FOSWIKI-Code in Sdoc3-Code

=head4 Synopsis

  $code = $class->foswikiToSdoc3($code);

=head4 Arguments

=over 4

=item $code (String)

FOSWIKI-Code

=back

=head4 Returns

Sdoc3-Code (String)

=head4 Description

Wandele FOSWIKI-Code in Sdoc3-Code und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub foswikiToSdoc3 {
    my ($class,$code) = @_;

    # Global zu entfernende Konstrukte

    $code =~ s/\r//g;
    $code =~ s/\n\s*%DRAWING\{synopsis\}%\s*/\n/g;
    $code =~ s/%META\{.*?\}%\s*//g;
    $code =~ s{(<font.*?>|</font>)}{}gs;
    $code =~ s{</?noautolink>}{}g;
    $code =~ s{<br\s*/>}{}g;
    $code =~ s{!([A-Z])}{$1}g;

    # Segmente expandieren

    my $expandSegments = sub {
        my $str = shift;
        $str =~ s/(^|[ \(])_(\S.*?\S)_([^A-Za-z0-9]|$)/$1I{$2}$3/gms; # italic
        $str =~ s/(^|[ \(])=(\S.*?\S)=([^A-Za-z0-9]|$)/$1C{$2}$3/gms; # Code
        $str =~ s/\*(\S.*?\S)\*/B{$1}/g; # Bold
        $str =~ s|<b>(.+)</b>|B{$1}|g; # Bold
        $str =~ s/"(.+?)"/Q{$1}/g; # Quote
        $str =~ s/&gt;/>/g; # &gt;
        return $str;
    };

    # Tabellen umwandeln

    my $processTable = sub {
        my $in = shift;

        # Tabellenzeilen und Kolumnenlängen ermitteln

        my (@lines,@colLen,$hasTitles);
        for my $line (split /\n/,$in) {
            $line =~ s/^\|\s*//gm;             # | am Anfang entfernen
            $line =~ s/\s*\|\s*$//gm;          # | am Ende entfernen
            my @cols = split /\s*\|\s*/,$line; # Zeile in Kolumen zerlegen
            if (!@lines) {
                # Eine Titelzeile erkennen wir an den Sternen
                $hasTitles = $cols[0] =~ /\*.+?\*/? 1: 0;
                @cols = map {s/\*(.*)\*/$1/; $_} @cols;
            }
            for (my $i = 0; $i < @cols; $i++) {
                $cols[$i] = $expandSegments->($cols[$i]);
            }            
            for (my $i = 0; $i < @cols; $i++) {
                my $len = length $cols[$i];
                my $colLen = $colLen[$i];
                if (!defined($colLen) || $colLen < $len) {
                    $colLen[$i] = $len;
                }
            }
            push @lines,\@cols;
        }

        # Formatstring für die Tabellenzeilen erstellen

        my $fmt;
        for my $colLen (@colLen) {
            if ($fmt) {
                $fmt .= ' ';
            }
            $fmt .= "%-${colLen}s";
        }

        # Sdoc-Tabelle aufbauen

        my $out = '';
        # Titelzeile
        if ($hasTitles) {
            $out = sprintf "$fmt\n",@{shift @lines};
        }
        # Trennzeile
        my $i = 0;
        for my $colLen (@colLen) {
            if ($i++) {
                $out .= ' ';
            }
            $out .= ('-' x $colLen);
        }
        $out .= "\n";
        # Zeilen des Tabellenkörpers
        for my $colA (@lines) {
            my $line = sprintf "$fmt\n",@$colA;
            $line =~ s/\s+$/\n/;
            $out .= $line;
        }
        $out = "%Table:\n$out.\n";

        return $out;
    };
    $code =~ s/((^\|.*\n)+)/$processTable->($1)/egm;

    # Überschriften und Textauszeichnungen umschreiben

    # $code =~ s/(^|[ \(])_(\S.*?\S)_([\s.\)])/$1I{$2}$3/gms; # italic
    # $code =~ s/(^|[ \(])=(\S.*?\S)=([\s.\)])/$1C{$2}$3/gms; # Code
    # $code =~ s/\*(\S+?)\*/B{$1}/gm; # Bold
    # $code =~ s/&gt;/>/g; # &gt;
    $code = $expandSegments->($code);
    $code =~ s/^---(\++)/'=' x length($1)/egm;

    # Image-Tags
    # <img alt='image005.png' height='386' src='%ATTACHURLPATH%/image005.png'
    # width='955' />

    my $i = 0;
    my @images;
    my $processImage = sub {
        my $str = shift;

        my ($url) = $str =~ /src=["'](.*?)["']/;
        my ($width) = $str =~ /width=["'](.*?)["']/;
        my ($height) = $str =~ /height=["'](.*?)["']/;
        my $name = sprintf 'BILD%02d',++$i;

        push @images,[$name,$url,$width,$height];

        return "G{$name}";
    };
    $code =~ s|<img (.*?)/>|$processImage->($1)|egs;

    # Links umschreiben

    my @links;
    my $processLink = sub {
        my ($url,$str) = @_;

        if (!defined $str) {
            if ($url =~ /^http/) {
                # Externer Link als direkte HTTP(S)-Adresse
                return "L{$url}";
            }
            elsif ($url =~ /^(BA|IF|MM|PS|RC|SJ)\S+$/) {
                # Interner Link auf eine andere Schnittstelle
                push @links,[$url,$url];
                return "L{$url}";
            }
            else {
                # Interner FOSWIKI-Link, den wir nicht auflösen können.
                # Muss manuell korrigiert werden
                return "$url (in FOSWIKI)";
            }
        }

        $str =~ s/\n/ /g;
        push @links,[$url,$str];

        return "L{$str}";
    };
    $code =~ s/\[\[(.*?)\]\[(.*?)\]\]}/$processLink->($1,$2)/egs;
    $code =~ s/\[\[(\S+?)\]\]/$processLink->($1)/egs;

    # Bullet-Listen umwandeln (auch eingerückte). Eine Bullet-Liste
    # beginnt mit einer Zeile mit einem eingerückten Stern (*) und
    # geht bis zu einer letzten Zeile mit einem eingerückten Stern.

    my $processBulletList = sub {
        my $str = shift;

        $str =~ /^( *)/;
        my $ind = $1;
        $str =~ s/^$ind//gm;

        return $str;
    };
    $code =~ s/((^ *\*.*\n)+)/$processBulletList->($1)/egm;

    # Verbatim Abschnitt <verbatim>...</verbatim> verarbeiten

    my $processVerbatimBlock = sub {
        my $str = shift;

        $str =~ s/\s*$/\n/;
        $str = "%Code:\n$str.\n";

        return $str;
    };
    $code =~ s|<verbatim>(.*?)</verbatim>\n|$processVerbatimBlock->($1)|egms;

    $code =~ s/\s+$/\n/; # Code auf genau ein Newline enden lassen

    # Links definieren

    for (@links) {
        my ($url,$str) = @$_;
        if ($url =~ /^(BA|IF|MM|PS|RC|SJ)\S+$/) {
            $url = "/schnittstelleDetail?sch_name=$url";
        }
        $code .= qq~\n%Link:\n  name="$str"\n  url="$url"\n~;
    }

    # Bilder definieren

    for (@images) {
        my ($name,$url,$width,$height) = @$_;

        $code .= qq~\n%Graphic:\n  name="$name"\n  url="$url"\n~;
        if ($width) {
            $code .= qq~  width="$width"\n~;
        }
        if ($height) {
            $code .= qq~  height="$height"\n~;
        }
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2022 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
