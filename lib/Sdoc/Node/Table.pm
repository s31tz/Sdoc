package Sdoc::Node::Table;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::AsciiTable;
use Sdoc::Core::LaTeX::LongTable;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Table - Tabellen-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Tabelle.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Tabellen-Knoten folgende zusätzliche Attribute:

=over 4

=item anchor => $anchor (Default: undef)

Anker der Tabelle.

=item anchorA => \@anchors (memoize)

Anker-Pfad der Tabelle.

=item asciiTable => $obj

Referenz auf das Sdoc::Core::AsciiTable-Objekt.

=item border => $str

Legt fest, welche Linien in und um die Tabelle gezeichnet werden.
Der Wert ist eine Kombination aus einem oder mehreren der
folgenden Buchstaben.

=over 4

=item t

Linie zwischen Titel und Daten.

=item h

Horizontale Linien I<zwischen> den Zeilen. Impliziert t.

=item v

Vertikale Linien I<zwischen> den Spalten.

=item H

Horizontale Linien ober- und unterhalb der Tabelle.

=item V

Vertikale Linien links und rechts von der Tabelle.

=back

=item caption => $text

Beschriftung der Tabelle. Diese erscheint unter der Tabelle.

=item formulaA => \@formulas

Array mit den in Zellen vorkommenden Formeln (M-Segmente).

=item identation => $bool (Default: 1)

Rücke die Tabelle ein. Das Attribut ist nur bei C<< align =>
'left' >> von Bedeutung.

=item linkA => \@links

Array mit Informationen über die in Zellen vorkommenden Links
(L-Segmente).

=item graphicA => \@graphics

Array mit Informationen über die in Zellen vorkommenden
Inline-Grafiken (G-Segmente).

=item linkId => $linkId

Ist die Tabelle das Ziel eines Link, ist dies der Anker, der in
das Zielformat eingesetzt wird.

=item text => $text

Quelltext der Tabelle.

=item titleColor => $rgb (Default: 'e8e8e8')

Farbe der Titelzeile.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Tabellen-Knoten

=head4 Synopsis

    $tab = $class->new($par,$variant,$root,$parent);

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

Tabellen-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Table:
        #   KEY=VAL
        # TEXT
        # .
        $attribH = $par->readBlock('text');
    }
    elsif ($markup eq 'sdoc') {
        # kein Markup
    }

    # Objekt instantiieren

    # FIXME: Ausprobieren, ob G-, M-, L-Segmente in einer Tabelle
    # funktionieren

    CORE::state $tableNumber = 0;
    my $self = $class->SUPER::new('Table',$variant,$root,$parent,
        anchor => undef,
        asciiTable => undef,
        border => undef,
        caption => undef,
        captionS => undef,
        formulaA => [],
        graphicA => [],
        linkA => [],
        linkId => undef,
        indentation => 1,
        number => ++$tableNumber,
        text => undef,
        titleColor => 'e8e8e8',
        # memoize
        anchorA => undef,
    );
    $self->setAttributes(%$attribH);

    # AsciTable-Objekt instantiieren, Segemente in
    # allen Zellen parsen

    my $atb = Sdoc::Core::AsciiTable->new($self->text);
    my $titleA = $atb->titles;
    for (my $i = 0; $i < @$titleA; $i++) {
        $par->parseSegments($self,\$titleA->[$i]);
    }
    my $rowA = $atb->rows;
    for my $row (@$rowA) {
        for (my $i = 0; $i < @$row; $i++) {
            $par->parseSegments($self,\$row->[$i]);
        }
    }
    $self->set(asciiTable=>$atb);

    # Segmente in caption parsen
    $par->parseSegments($self,'caption');

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Verweise

=head3 anchor() - Anker der Tabelle

=head4 Synopsis

    $anchor = $tab->anchor;

=head4 Returns

Anker (String)

=head4 Description

Liefere den Wert des Attributs C<anchor>. Falls dieses keinen Wert
hat, liefere den Wert des Attributs C<caption>. Falls dieses auch
keinen Wert hat, liefere (sprachabhängig) "Tabelle N" oder
"Table N". Letzteres ist kein guter Anker, da dieser sich ändert,
wenn sich etwas an der Tabellenreihenfolge ändert.

=cut

# -----------------------------------------------------------------------------

sub anchor {
    my $self = shift;

    my $doc = $self->root;

    my $anchor = $self->get('anchor');
    if (!defined $anchor) {
        $anchor = $self->caption;
        if (!defined $anchor) {
            $anchor = $doc->language eq 'german'? 'Tabelle': 'Table';
            $anchor .= ' '.$self->number;
        }
    }
    
    return $anchor;
}

# -----------------------------------------------------------------------------

=head3 latexLinkText() - Verweis-Text

=head4 Synopsis

    $linkText = $tab->latexLinkText($l);

=head4 Returns

Text (String)

=head4 Description

Liefere den Verweis-Text als fertigen LaTeX-Code.

=cut

# -----------------------------------------------------------------------------

sub latexLinkText {
    my ($self,$l) = @_;
    return $self->latexText($l,'captionS');
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $com->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latex {
    my ($self,$l) = @_;

    my $root = $self->root;

    my $atb = $self->asciiTable;

    my $border = $self->border;
    if (!defined $border) {
        $border = $atb->multiLine? 'hvHV': 'hHV';
    }

    return Sdoc::Core::LaTeX::LongTable->latex($l,
        align => 'l',
        alignments => scalar $atb->alignments,
        border => $border,
        callbackArguments => [$self],
        caption => $self->latexText($l,'captionS'),
        indent => $self->indentation? $root->indentation.'em': undef,
        label => $self->linkId,
        multiLine => $atb->multiLine,
        postVSpace => $l->modifyLength($root->latexParSkip,'*-2'),
        rows => scalar $atb->rows,
        rowCallback => sub {
            my ($self,$l,$row,$n,$node) = @_;
            my @row;
            for my $val (@$row) {
                push @row,$node->latexText($l,\$val);
            }
            return @row;
        },
        titleColor => $self->titleColor,
        titleWrapper => '\textsf{\textbf{%s}}',
        titles => scalar $atb->titles,
        titleCallback => sub {
            my ($self,$l,$title,$n,$node) = @_;
            return $node->latexText($l,\$title);
        },
    )."\n";
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
