package Sdoc::Node::Table;
use base qw/Sdoc::Node/;

use strict;
use warnings;
use utf8;

our $VERSION = 0.01;

use Sdoc::Core::AsciiTable;

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
        border => 'hHV',
        caption => undef,
        captionS => undef,
        formulaA => [],
        graphicA => [],
        linkA => [],
        linkId => undef,
        number => ++$tableNumber,
        text => undef,
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
    if ($atb->multiLine) {
        $self->set(border=>'hvHV');
    }
    $self->set(asciiTable=>$atb);

    # Segmente in caption parsen
    $par->parseSegments($self,'caption');

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Anker

=head3 anchor() - Anker der Tabelle

=head4 Synopsis

    $anchor = $tab->anchor;

=head4 Returns

Anker (String)

=head4 Description

Liefere den Wert des Attributs C<anchor>. Falls dieses keinen Wert
hat, liefere den Wert des Attributs C<caption>. Falls dieses auch
keinen Wert hat, liefere (sprachabhängig) "Tabelle N" oder
"Table N".

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
    my ($self,$gen) = @_;

    # Dokument-Knoten
    my $doc = $self->root;

    # Information über Tabelle

    my $atb = $self->asciiTable;
    my $titleA = $atb->titles;
    my $alignA = $atb->alignments;
    my $rowA = $atb->rows;
    my $multiLine = $atb->multiLine;
    my $border = $self->border // '';

    # Hilfsfunktion zum Erzeugen einer Zelle

    my $cell = sub {
        my ($self,$gen,$val,$align) = @_;

        if ($val =~ tr/\n//) {
            $val = $self->latexText($gen,\$val);
            $val =~ s/\n/\\\\/g;
            return $gen->cmd('makecell',
                -o => $align,
                -p => $val,
                -nl => 0,
            );
        }

        return $self->latexText($gen,\$val);
    };

    my $code;

    # Anker

    # Linie oberhalb der Tabelle

    if (index($border,'H') >= 0) {
       $code .= $gen->cmd('hline');
    }

    # Titelbereich

    if (@$titleA) {
        my $line;
        for (my $i = 0; $i < @$titleA; $i++) {
            if ($line) {
                $line .= ' & ';
            }
            # FIXME: Fonteinstellung eleganter machen
            $line .= $gen->cmd('textsf',
                -p => $gen->cmd('textbf',
                    -p => $cell->($self,$gen,$titleA->[$i],$alignA->[$i].'b'),
                    -nl => 0,
                ),
                -nl => 0,
            );
            # Funktioniert nicht. Warum? s. renewcommand Node::Document
            # $line .= $cell->($self,$gen,$titleA->[$i],$alignA->[$i]);
        }
        $code .= "\\rowcolor{light-gray} $line \\\\";
        if ($border =~ /[th]/) {
            $code .= ' '.$gen->cmd('hline',-nl=>0);
        }
        $code .= "\n";
        if (my $linkId = $self->linkId) {
            $code .= $gen->cmd('label',-p=>$linkId);
        }
        $code .= $gen->cmd('endfirsthead');
        $code .= $gen->cmd('multicolumn',
            -p => $atb->width,
            -p => 'r',
            -p => $gen->cmd('emph',-nl=>0,-p=>$doc->language eq 'german'?
                'Fortsetzung': 'Continued'),
            -nl => 0,
        );
        $code .= " \\\\ \\hline\n";
        $code .= "\\rowcolor{light-gray} $line \\\\";
        if ($border =~ /[th]/) {
            $code .= ' '.$gen->cmd('hline',-nl=>0);
        }
        $code .= "\n";
    }
    $code .= $gen->cmd('endhead');
    
    # Definition Zwischenfußzeile 
    
    if (index($border,'H') >= 0) {
       $code .= $gen->cmd('hline');
    }
    $code .= $gen->cmd('multicolumn',
        -p => $atb->width,
        -p => 'r',
        -p => $gen->cmd('emph',-nl=>0,-p=>$doc->language eq 'german'?
            'Fortsetzung nächste Seite': 'Continued next page'),
    );
    $code .= $gen->cmd('endfoot');

    # Definition letzte Fußzeile

    if (index($border,'H') >= 0) {
       $code .= $gen->cmd('hline');
    }
    if (my $caption = $self->latexText($gen,'captionS')) {
        # Tabellenunterschrift
        $code .= $gen->cmd('caption',-p=>$caption);
    }
    $code .= $gen->cmd('endlastfoot');

    # Zeilen

    for my $row (@$rowA) {
        my $line;
        for (my $i = 0; $i < @$row; $i++) {
            if ($line) {
                $line .= ' & ';
            }
            $line .= $cell->($self,$gen,$row->[$i],$alignA->[$i].'t');
        }
        $code .= $line;
        if ($row != $rowA->[-1]) {
            $code .= ' \\\\';
        }
        if (index($border,'h') >= 0 && $row != $rowA->[-1]) {
            $code .= ' '.$gen->cmd('hline',-nl=>0);
        }
        $code .= "\n";
    }

    my $colSpec = join index($border,'v') >= 0? '|': '',@$alignA;
    if (index($border,'V') >= 0) {
        $colSpec = "|$colSpec|";
    }

    return $gen->env('longtable',$code,
        -p => $colSpec,
        -nl => 2,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

0.01

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
