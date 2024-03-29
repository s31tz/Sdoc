# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Item - Listenelement-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Listenelement.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Listenelement-Knoten folgende zusätzliche Attribute:

=over 4

=item childA => \@childs

Liste der Subknoten.

=item formulaA => \@formulas

Array mit den im Key vorkommenden Formeln aus
M-Segmenten.

=item key => $key

Schlüssel im Falle einer Definitionsliste.

=item keyS => $keyS

Schlüssel mit geparsten Segmenten.

=item linkA => \@links

Array mit Informationen über die im Key vorkommenden Links.

=back

=cut

# -----------------------------------------------------------------------------

package Sdoc::Node::Item;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Node::List;
use Sdoc::LineProcessor;

# -----------------------------------------------------------------------------

our $Abbrev = 'itm';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Listenelement-Knoten

=head4 Synopsis

  $itm = $class->new($par,$variant,$root,$parent);

=head4 Arguments

=over 4

=item $par

Parser-Objekt.

=item $variant

Markup-Variante.

=item $root

Wurzelknoten des Parsingbaums.

=item $parent

Eltern-Knoten.

=back

=head4 Returns

Listenelement-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Falls der Parent kein List-Knoten ist, fügen wir einen
    # List-Block in den Parsing-Stream ein und delegieren die
    # Verarbeitung an die List-Klasse.

    if ($parent->type ne 'List') {
        # Wir geben der Liste die Zeilennummer und Quelle des Item.
        # Der Listentyp wird vom ersten Item gesetzt.

        my $lineA = $par->lines;
        unshift @$lineA,$par->lineClass->new('%List:',
            $lineA->[0]->number,$lineA->[0]->inputR);

        return Sdoc::Node::List->new(0,$par,$root,$parent);
    }

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my ($attribH,$firstLine,$indent);
    if ($variant == 0) {
        # %Item:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # [...]: -or- [...:]
        # *, o, +
        # N.

        my $line = $par->shiftLine;

        my ($listType,$key,$text);
        if ($variant == 1) {
            $listType = 'description';
            $line->text =~ /^\[(.*?)\]:(.*)/ ||
                $line->text =~ /^\[(.*?:)\](.*)/;
            $key = $1;
            $text = $2;
        }
        elsif ($variant == 2) {
            $listType = 'unordered';
            $line->text =~ /^([*o+]) (.*)/;
            $key = $1;
            $text = $2;
            $indent = 2;
        }
        elsif ($variant == 3) {
            $listType = 'ordered';
            $line->text =~ /^([A-Za-z]|\d+)\. (.*)/;
            $key = $1;
            $text = $2;
            $indent = length($key)+2;
        }
        if (!defined $parent->listType) {
            $parent->listType($listType);
        }

        # Falls auf der Zeile des ersten Item ein Text angegeben ist,
        # fügen wir diesen als erste Zeile des Subdokumentes unten
        # hinzu.

        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
        if ($text ne '') {
            $line->text($text);
            $firstLine = $line;
        }

        $attribH = {
            input => $line->input,
            lineNum => $line->number,
            key => $key,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Item',$variant,$root,$parent,
        childA => [],
        formulaA => [],
        graphicA => [],
        key => undef,
        keyS => undef,
        linkA => [],
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'key');

    # Eingerücktes Subdokument einlesen

    $par->removeEmptyLines;
    my $lineA = $par->lines;
    my @lines;
    while (@$lineA) {
        my $line = $lineA->[0];
        if (!defined $indent) {
            # Die Einrücktiefe des Subdokuments ist die Einrücktiefe
            # der ersten Zeile (diese ist nichtleer, da wir oben
            # Leerzeilen überlesen haben). Sonderfall: Wenn die
            # Einrücktiefe 0 ist, brechen wir unmittelbar ab, da das
            # dann kein Subdokument gibt.

            $indent = $line->indentation;
            if ($indent == 0) {
                last;
            }
        }
        if (!$line->isEmpty) {
            if ($line->indentation < $indent) {
                # Wir haben das Ende des Subdokuments erreicht, wenn
                # die Einrücktiefe sich verringert.
                last;
            }

            # Wir entfernen die Einrückung von der eingerückten Zeile
            $line->unindent($indent);
        }
        push @lines,$par->shiftLine;
    }
    if ($firstLine) {
        unshift @lines,$firstLine;
    }

    # Child-Objekte aus dem Subdokument verarbeiten

    $par = Sdoc::LineProcessor->new(\@lines,
        -encoding => 'utf-8',
        -lineContinuation => 'backslash',
    );

    $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant) = $par->nextType(1);

        $self->push(childA=>$nodeClass->new($variant,$par,$root,$self));
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $itm->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub htmlCode {
    my ($self,$h) = @_;

    my $listType = $self->parent->listType;
    my $key = $self->key;
    my $childs = $self->generateChilds('html',$h);

    if ($listType eq 'ordered') {
        # N. => list-style-type: decimal (Default)

        my $key = $self->key;
        my $mark;
        if ($key =~ /^[A-Za-z]$/) {
            $mark = 'lower-alpha';
        }

        return $h->tag('li',
            style => $mark? "list-style-type:$mark": undef,
            $childs,
        );
    }
    elsif ($listType eq 'unordered') {
        # '*' => 'disc', (Default)
        my $mark = {
            'o' => 'circle',
            '+' => 'square',
        }->{$self->key};

        return $h->tag('li',
            style => $mark? "list-style-type:$mark": undef,
            $childs,
        );
    }
    elsif ($listType eq 'description') {
        return $h->cat(
            $h->tag('dt',
                $self->expandText($h,'keyS')
            ),
            $h->tag('dd',
                $childs
            ),
        );
    }

    $self->throw("Unexpected listType: $listType");
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $itm->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latexCode {
    my ($self,$l) = @_;

    my $code;
    
    my $listType = $self->parent->listType;
    if ($listType eq 'description') {
        # [{}] weil sonst Probleme bei Macros mit Optionen (\includegraphics)
        $code .= $l->c('\item[{%s}]',$self->expandText($l,'keyS'));
    }
    else {
        $code .= $l->c('\item');
    }

    $code .= $self->generateChilds('latex',$l);
    
    return $code;
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $itm->mediawikiCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

MediaWiki-Code (String)

=cut

# -----------------------------------------------------------------------------

sub mediawikiCode {
    my ($self,$m) = @_;

    # MEMO: Es gibt Item-spezifischen Code in den
    # mediawiki()-Methoden von Paragraph und List

    # Sdoc-Listentyp auf MediaWiki-Listentyp abbilden

    my $type = {
        unordered => '*',
        ordered => '#',
        description => ';',
    }->{$self->parent->listType} || $self->throw;

    my $childs = $self->generateChilds('mediawiki',$m);
    $childs =~ s/\n/ /g;
    if ($type eq ';') {
        my $key = $self->expandText($m,'keyS');
        $key =~ s/:/&#58;/g;
        return $m->item($type,$key,$childs);
    }

    return $m->item($type,$childs);
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2023 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
