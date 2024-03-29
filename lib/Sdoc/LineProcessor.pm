# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::LineProcessor - Sdoc Zeilen-Prozessor

=head1 BASE CLASS

L<Sdoc::Core::LineProcessor>

=cut

# -----------------------------------------------------------------------------

package Sdoc::LineProcessor;
use base qw/Sdoc::Core::LineProcessor/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Core::LineProcessor::Line;
use Sdoc::Core::Option;
use Sdoc::Core::Unindent;
use Sdoc::Core::Converter;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Parser-Objekt

=head4 Synopsis

  $par = $class->new($file,@opt);
  $par = $class->new(\$str,@opt);
  $par = $class->new(\@lines,@opt);

=head4 Arguments

=over 4

=item $file

Pfad einer Sdoc-Datei.

=item $str

Sdoc-Quelltext als Zeichenkette.

=item @lines

Sdoc-Quelltest als Array von Zeilen.

=item @opt

Liste von Optionen.

=back

=head4 Options

=over 4

=item -markup => $markup (Default: 'sdoc')

Parse die Eingabe nach Markup $markup.

=back

=head4 Returns

Parser-Objekt

=head4 Description

Instantiiere eine Parser-Objekt für Sdoc-Dateien und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $input = shift;
    # @_: @opt

    # Optionen

    my $markup = 'sdoc';

    Sdoc::Core::Option->extract(-mode=>'sloppy',\@_,
        -markup => \$markup,
    );

    # Instantiiere Objekt

    my $self = $class->SUPER::new($input,@_);
    $self->add(markup=>$markup);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Parsing

=head3 nextType() - Ermittele Typ des nächsten Knotens

=head4 Synopsis

  ($nodeClass,$variant,$type) | $type = $par->nextType($removeEmptyLines);

=head4 Arguments

=over 4

=item $removeEmptyLines

Konsumiere Leerzeilen am Anfang.

=back

=head4 Returns

=over 4

=item $nodeClass

Name der nächsten Knotenklasse.

=item $variant

Nummer der Markup-Variante.

=item $type

Typ-Bezeichnung des nächsten Knotens.

=back

=cut

# -----------------------------------------------------------------------------

sub nextType {
    my ($self,$removeEmptyLines) = @_;

    if ($removeEmptyLines) {
        # Leerzeilen konsumieren
        $self->removeEmptyLines;
    }

    my $markup = $self->markup;
    my $line = $self->lines->[0];
    my $input = $line->input;
    my $lineNum = $line->number;
    my $text = $line->text;

    my ($type,$variant);
    if ($text =~ /^%([A-Za-z]+):/) {
        $type = $1;
        $variant = 0;
    }
    elsif ($markup eq 'sdoc') {
        if (substr($text,0,2) eq '% ') {
            $type = 'Comment';
            $variant = 1;
        }
        elsif ($text =~ /^=+[-+!]* /) {
            $type = 'Section';
            $variant = 1;
        }
        elsif ($text =~ /^=+[*]* /) {
            $type = 'BridgeHead';
            $variant = 1;
        }
        elsif ($text =~ /^> /) {
            $type = 'Quote';
            $variant = 1;
        }
        elsif ($text =~ /^\[.+?\]:/ || $text =~ /^\[.+?:\]/) {
            $type = 'Item';
            $variant = 1;
        }
        elsif ($text =~ /^[*o+] /) {
            $type = 'Item';
            $variant = 2;
        }
        elsif ($text =~ /^([A-Za-z]|\d+)\. /) {
            $type = 'Item';
            $variant = 3;
        }
        elsif (substr($text,0,1) eq ' ') {
            $type = 'Code';
            $variant = 1;
        }
        elsif ($text eq '---PageBreak---') {
            $type = 'PageBreak';
            $variant = 1;
        }
        else {
            $type = 'Paragraph';
            $variant = 1;
        }
    }
    elsif ($markup eq 'pure') {
        # Diese Exception greift, da obige Regel
        # $text =~ /^%([A-Za-z]+):/ nicht gematcht hat

        $self->throw(
            'SDOC-00004: Unexpected text (only pure markup allowed)',
            Text => $text,
            Input => $input,
            Line => $lineNum,
        );
    }
    else {
        $self->throw(
            'SDOC-00002: Unknown markup',
            Markup => $markup,
        );
    }

    # Überprüfe Knotentyp

    my $nodeClass = "Sdoc::Node::$type";
    if (!$nodeClass->isa('Sdoc::Node')) {
        $self->throw(
            'SDOC-00002: Unknown node type',
            Type => $type,
            Input => $input,
            Line => $lineNum,
        );
    }

    return wantarray? ($nodeClass,$variant,$type): $type;
}

# -----------------------------------------------------------------------------

=head3 readBlock() - Konsumiere Block

=head4 Synopsis

  $attribH = $par->readBlock; # ohne Content
  $attribH = $par->readBlock($key); # mit Content
  $attribH = $par->readBlock($key,\@noContent); # Content mit Ausnahme
  $attribH = $par->readBlock($key,\@noContent,$orig);

=head4 Arguments

=over 4

=item $key

Wenn angegeben, besitzt der Block einen Inhalt. Dieser Inhalt wird
geparst und an das Attibut $key des gelieferten Hashs zugewiesen.

=item \@noContent

Liste der Attribute, bei deren Auftreten der Knoten keinen Content
hat. Beispiel: %Code-Block mit Attribut C<load=PATH>.

=item $orig

Der Content wird unverändert geliefert, also mit etwaiger
Einrückung und Leerraum am Anfang und am Ende. Beispiel: %Format-Block.

=back

=head4 Returns

=over 4

=item $attribH

Hash mit den geparsten Knoten-Attributen.

=back

=head4 Description

Lies den nächsten Block und liefere den Attribut-Hash des Blocks
zurück.

=cut

# -----------------------------------------------------------------------------

sub readBlock {
    my $self = shift;
    my $key = shift;
    my $noContentA = shift // [];
    my $orig = shift // 0;

    my $lineA = $self->lines;
    my $input = $lineA->[0]->input;
    my $lineNum = $lineA->[0]->number;

    my ($type,$h) = $self->readBlockHead(1);

    my $attribH = {
        variant => 0,
        input => $input,
        lineNum => $lineNum,
        %$h,
    };

    if ($key && !grep {$attribH->{$_}} @$noContentA) {
        # Mit Content

        my $content = '';
        while (my $line = shift @$lineA) {
            if ($line->text eq '.') {
                last;
            }
            $content .= $line->textNl;
        }

        if (!$orig) {
            chomp $content;
            $content = Sdoc::Core::Unindent->string($content);
        }
        $attribH->{$key} = $content;
    }

    return $attribH;
}

# -----------------------------------------------------------------------------

=head3 readBlockHead() - Lies Blockanfang

=head4 Synopsis

  ($type,$attribH) = $par->readBlockHead($remove); # lies und entferne Zeilen
  $attribH = $par->readBlockHead; # analysiere Zeilen

=head4 Arguments

=over 4

=item $remove (Default: 0)

Entferne die gelesenen Zeilen aus der Eingabe.

=back

=head4 Returns

=over 4

=item $type (String)

Der Block-Typ.

=item $attribH (Hash-Referenz)

Hash mit den geparsten Knoten-Attributen.

=back

=head4 Description

Lies den nächsten Blockanfang und liefere dessen Typ $type und
Attribut-Hash $attribH zurück.

=cut

# -----------------------------------------------------------------------------

sub readBlockHead {
    my ($self,$remove) = @_;

    # Attribute lesen. Die Attributzeilen enden, wenn eine Zeile
    # nicht mit einem eingerücktem KEY= beginnt.

    my $lineA = $self->lines;

    my $i = 0;
    my ($type,$str);
    while ($lineA->[$i]) {
        my $text = $lineA->[$i]->text;
        if ($i == 0) {
            ($type,$str) = $text =~ /^%(\w+):(.*)/;
        }
        elsif ($text =~ /^\s+\w+=/) {
            $str .= $text;
        }
        else {
            last;
        }
        $i++;
    }
    my $attribH = {Sdoc::Core::Converter->stringToKeyVal($str)};

    if ($remove) {
        splice @$lineA,0,$i;
    }

    return wantarray? ($type,$attribH): $attribH;
}

# -----------------------------------------------------------------------------

=head3 listType() - Ermittele Listen-Typ

=head4 Synopsis

  $listType = $par->listType;

=head4 Returns

Listentyp-Bezeichner (String)

=head4 Description

Diese Methode rufen wir, wenn wir wissen, dass das nächste Element
der Eingabe ein Item ist. Sie ermittelt den Listentyp dieses
Items. Wir nutzen diese Methode im Konstruktor der List-Klasse,
um zu entscheiden, ob das aktuelle Item zu der Liste gehört oder
zu einer neuen Liste eines anderen Typs.

=cut

# -----------------------------------------------------------------------------

sub listType {
    my $self = shift;

    my $markup = $self->markup;
    my $lineA = $self->lines;

    my $listType;
    my $text = $lineA->[0]->text;
    if ($text =~ /^%Item:(.*)/) {
        my $key = $self->readBlockHead->{'key'};
        if (length($key) == 1 && index('*o+',$key) >= 0) {
            $listType = 'unordered';
        }
        elsif ($key =~ /^\d+$/) {
            $listType = 'ordered';
        }
        else {
            $listType = 'description';
        }
    }
    elsif ($self->markup eq 'sdoc') {
        my $c = substr $text,0,1;
        if ($c eq '[') {
            $listType = 'description';
        }
        elsif (index('*o+',$c) >= 0) {
            $listType = 'unordered';
        }
        else {
            $listType = 'ordered';
        }
    }
    else {
        $self->throw;
    }

    return $listType;
}

# -----------------------------------------------------------------------------

=head3 sectionLevel() - Ermittele Abschnitts-Ebene

=head4 Synopsis

  $level = $par->sectionLevel;

=head4 Returns

Abschnitts-Ebene (Integer)

=head4 Description

Liefere die Ebene des nächsten Abschnitts in der Eingabe.

=cut

# -----------------------------------------------------------------------------

sub sectionLevel {
    my $self = shift;

    my $markup = $self->markup;
    my $lineA = $self->lines;

    my $level;
    my $text = $lineA->[0]->text;
    if ($text =~ /^%Section:(.*)/) {
        $level = $self->readBlockHead->{'level'};
    }
    elsif ($self->markup eq 'sdoc') {
        ($level) = $text =~ /^(=+)(-)?/;
        $level = $2? 1-length($level): length($level);
    }

    return $level;
}

# -----------------------------------------------------------------------------

=head3 parseSegments() - Parse Segmente eines Knoten-Attributs

=head4 Synopsis

  $par->parseSegments($node,$key);
  $par->parseSegments($node,\$str);

=head4 Arguments

=over 4

=item $node

Knoten.

=item $key

Knoten-Attribut, dessen Segmente geparst werden.

=item $str

String, dessen Segmente geparst werden.

=back

=head4 Description

Parse Segmente auf Knoten-Attribut $key oder in String $str und
setze die Attribute des Knotens $node entsprechend.

Der Wert mit (oder ohne) Segmenten wird so vorbereitet, dass
dieser formatspezifisch bearbeitet werden kann. Auf dem
gelieferten Wert können anschließend die Operationen vorgenommen
werden:

=over 4

=item 1.

Reservierte Zeichen des Zielformats können geschützt werden.

=item 2.

Der Wert der Segmente kann in das Zielformat gewandelt werden.

=back

Diese Operationen werden von den Methoden <format>Text() bei der
Codegenerierung durchgeführt.

=cut

# -----------------------------------------------------------------------------

sub parseSegments {
    my $self = shift;
    my $node = shift;
    my $arg = shift; # $key -or- $ref

    my $val = ref $arg? $$arg: $node->get($arg);
    if (!defined $val) {
        return;
    }

    my $markup = $self->markup;
    if ($markup eq 'sdoc') {
        my $sub = sub {
            my ($seg,$val) = @_;

            if ($seg eq 'A') {
                if (!$node->exists('anchor')) {
                    # Sieht der Knoten keinen Anker vor, geben wir
                    # eine Warnung aus und tasten das Segment nicht
                    # an
                    $node->warn('Node does not allow anchors: A{%s}',$val);
                }
                else {
                    # Wir werten nur das erste A{}-Segment aus alle
                    # weiteren warnen wir an

                    if (defined $node->get('anchor')) {
                        $node->warn('More than one anchor: A{%s}',$val);
                    }
                    else {
                        $node->set(anchor=>$val);
                        $val = '';
                    }
                }
            }
            elsif ($seg eq 'G') {
                if (!$node->exists('graphicA')) {
                    # Sieht der Knoten keine Inline-Grafik vor, geben wir
                    # eine Warnung aus, erzeugen keinen Eintrag in
                    # graphicA (da ja auch nicht existent) und setzen
                    # entsprechend auch keinen Index als Wert ein.
                    # Den Segment-Wert lassen wir unangetastet. Dieser
                    # Fall wird in den Methoden xxxText() speziell
                    # behandelt.
                    $node->warn('Node does not allow inline'.
                        ' graphics: G{%s}',$val);
                }
                else {
                    # Inline-Grafik. Die unten stehende Komponente
                    # undef wird nach dem Parsen des gesamten
                    # Dokuments durch einen Verweis auf den
                    # Grafik-Knoten ersetzt.

                    my $graphicA = $node->graphicA;
                    push @$graphicA,[$val,undef];
                    $val = $#$graphicA;
                }
            }
            elsif ($seg eq 'L') {
                # Linktext kanonisieren
                $val =~ s/[\n\t]/ /g;
                $val =~ s/ {2,}/ /g;

                if (!$node->exists('linkA')) {
                    # Sieht der Knoten keine Links vor, geben wir
                    # eine Warnung aus, erzeugen keinen Eintrag in
                    # linkA (da ja auch nicht existent) und setzen
                    # entsprechend auch keinen Index als Wert ein.
                    # Den Segment-Wert lassen wir unangetastet. Dieser
                    # Fall wird in den Methoden xxxText() speziell
                    # behandelt.
                    $node->warn('Node does not allow links: L{%s}',$val);
                }
                else {
                    # Link. Die unten stehende Komponente undef wird nach
                    # dem Parsen des gesamten Dokuments durch einen Hash
                    # mit Link-Information ersetzt.

                    my $linkA = $node->linkA;
                    push @$linkA,[$val,undef];
                    $val = $#$linkA;
                }
            }
            elsif ($seg eq 'M') {
                if (!$node->exists('formulaA')) {
                    # Sieht der Knoten keine Formeln vor, geben wir
                    # eine Warnung aus, erzeugen keinen Eintrag in
                    # formulaA (da ja auch nicht existent) und setzen
                    # entsprechend auch keinen Index als Wert ein.
                    # Den Segment-Wert lassen wir unangetastet. Dieser
                    # Fall wird in den Methoden xxxText() speziell
                    # behandelt.
                    $node->warn('Node does not allow formulas: M~%s~',$val);
                }
                else {
                    # Mathematische Formel

                    my $formulaA = $node->formulaA;
                    push @$formulaA,$val;
                    $val = $#$formulaA;
                }
            }

            # ...und sonstige Segmente

            $val =~ s/\\\{/\x03/g; # geschützte öffnende Klammer wandeln
            $val =~ s/\\\}/\x04/g; # geschützte schließende Klammer wandeln
            return "$seg\x01$val\x02";
        };

        # Behandele Newline-Segmente
        $val =~ s/~N~/$sub->('N','')/eg;

        # Behandele Formel-Segmente (mit ~ als Begrenzer)
        $val =~ s/(?<!\\)M~(([^~]|\\~)*)(?<!\\)~/$sub->('M',$1)/eg;

        # Ersetze Segment-Klammern { und } durch \x01 und \x02 von
        # "innen" nach "außen", also gemäß der Schachtelung, und innerhalb
        # der Klammern die geschützten Klammern \{ und \}

        1 while $val
            =~ s/(?<!\\)([ABCGILQS])\{(([^{}]|\\[{}])*)(?<!\\)\}/
            $sub->($1,$2)/ex;

        # Leeres A{}-Segment einschließlich Whitespace
        # entfernen. Davon sollte es maximal eins geben. Gibt es
        # mehr, werden die weiteren nicht beachtet
        # (s.o. $anchorCount).

        if (index($val,"A\x01\x02") >= 0) {
            if ($val !~ s/^A\x01\x02\s+//m) {             # Zeilenanfang
                if ($val !~ s/\s+A\x01\x02$//m) {         # Zeilenende
                    if ($val !~ s/ +A\x01\x02( +)/$1/m) { # im Text
                        $val =~ s/A\x01\x02//m;           # in Wort
                    }
                }
            }
        }

        # Nachdem die Schachtelung aufgelöst wurde, wandeln wir die
        # ehedem geschützten { } zurück
        $val =~ tr/\x03\x04/{}/;

        # Wir entfernen den Backslash vor geschützten Segmenten (diese
        # sollten im Text nur außerhalb von Segementen vorkommen.

        $val =~ s/\\([ABCGILQS]\{)/$1/g;
        $val =~ s/\\M~/M~/g;
        $val =~ s/~\\N~/~N~/g;
    }
    else {
        $self->throw;
    }

    if (ref $arg) {
        # Änderung "in place"
        $$arg = $val;
    }
    else {
        # Auf Attribut speichern
        $node->set($arg.'S'=>$val);
    }

    return;
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
