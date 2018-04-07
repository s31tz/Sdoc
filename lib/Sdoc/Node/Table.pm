package Sdoc::Node::Table;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::AsciiTable;
use Sdoc::Core::Css;
use Sdoc::Core::Html::Table::List;
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

=item linkId => $str (memoize)

Berechneter SHA1-Hash, unter dem der Knoten von einem
Verweis aus referenziert wird.

=item graphicA => \@graphics

Array mit Informationen über die in Zellen vorkommenden
Inline-Grafiken (G-Segmente).

=item number => $n

Tabellennummer. Wird automatisch hochgezählt.

=item referenced => $n

Die Tabelle ist $n Mal Ziel eines Link. Zeigt an,
ob für die Tabelle ein Anker erzeugt werden muss.

=item text => $text

Quelltext der Tabelle.

=item titleColor => $color (Default: '#e8e8e8')

Farbe der Titelzeile.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'tab';

# -----------------------------------------------------------------------------

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

    my $self = $class->SUPER::new('Table',$variant,$root,$parent,
        anchor => undef,
        asciiTable => undef,
        border => undef,
        caption => undef,
        captionS => undef,
        formulaA => [],
        graphicA => [],
        linkA => [],
        indent => undef,
        number => $root->increment('countTable'),
        referenced => 0,
        text => undef,
        titleColor => '#e8e8e8',
        # memoize
        anchorA => undef,
        linkId => undef,
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

=head3 linkText() - Verweis-Text

=head4 Synopsis

    $linkText = $tab->linkText($gen);

=head4 Returns

Text (String)

=head4 Description

Liefere den Verweis-Text als fertigen Zielcode.

=cut

# -----------------------------------------------------------------------------

sub linkText {
    my ($self,$gen) = @_;
    return $self->expandText($gen,'captionS');
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $code = $tab->html($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($self,$h) = @_;

    my $atb = $self->asciiTable;
    my $cssId = sprintf 'table%03d',$self->number;
    my $border = $self->border;
    if (!defined $border) {
        $border = $atb->multiLine? 'hvHV': 'hHV';
    }

    my (@table,@thead,@th,@tr,@td,@tdLast);
    push @table,borderCollapse=>'collapse';
    push @th,padding=>'4px';
    push @td,padding=>'4px';

    my $bh = index($border,'h') >= 0;
    my $bt = index($border,'t') >= 0;
    my $bv = index($border,'v') >= 0;
    my $bH = index($border,'H') >= 0;
    my $bV = index($border,'V') >= 0;
    my $b = '1px solid black';
    
    if ($bh) {
        push @td,borderTop=>$b;
    }
    elsif ($bt) {
        push @th,borderBottom=>$b;
    }
    if ($bv) {
        push @td,borderRight=>$b;
        push @th,borderRight=>$b;
        push @tdLast,borderRight=>'1px none black';
    }
    if ($bH && $bV) {
        push @table,border=>$b;
    }
    elsif ($bH) {
        push @table,borderLeft=>$b,borderRight=>$b;
    }
    elsif ($bV) {
        push @table,borderTop=>$b,borderBottom=>$b;
    }
    if (my $color = $self->titleColor) {
        push @thead,backgroundColor=>$color;
    }

    my $html = $h->tag('style',
        Sdoc::Core::Css->new('flat')->restrictedRules("#$cssId",
            '' => \@table,
            thead => \@thead,
            th => \@th,
            td => \@td,
            'td:last-child' => \@tdLast,
            'th:last-child' => \@tdLast,
        )
    );
    $html .= Sdoc::Core::Html::Table::List->html($h,
        class => 'sdoc-table',
        id => $cssId,
        border => undef,
        allowHtml => 1,
        cellpadding => undef,
        cellspacing => undef,
        align => scalar $atb->alignments('html'),
        # FIXME: verbessern
        titles => [map { $self->expandText($h,\$_);
            s/\n/$h->tag('br')/ge; $_ } $atb->titles],
        rows => scalar $atb->rows,
        rowCallbackArguments => [$self],
        rowCallback => sub {
            my ($row,$i,$node) = @_;
            my @row;
            for (@$row) {
                my $text = $node->expandText($h,\$_);
                $text =~ s/\n/$h->tag('br')/ge;
                push @row,$text;
            }
            return (undef,@row);
        },
    );

    return $html;
}

# -----------------------------------------------------------------------------

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $tab->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latex {
    my ($self,$l) = @_;

    my $doc = $self->root;

    my $atb = $self->asciiTable;

    # Einrückung

    my $indent;
    if ($self->indent || $doc->indentMode && !defined $self->indent) {
        $indent = $doc->latexIndentation.'pt';
    }

    # Trennlinien

    my $border = $self->border;
    if (!defined $border) {
        $border = $atb->multiLine? 'hvHV': 'hHV';
    }

    # LaTeX-Code erzeugen

    return Sdoc::Core::LaTeX::LongTable->latex($l,
        align => 'l',
        alignments => scalar $atb->alignments('latex'),
        border => $border,
        callbackArguments => [$self],
        caption => $self->expandText($l,'captionS'),
        indent => $indent,
        label => $self->referenced? $self->linkId: undef,
        multiLine => $atb->multiLine,
        postVSpace => $l->modifyLength($doc->latexParSkip,'*-2'),
        rows => scalar $atb->rows,
        rowCallback => sub {
            my ($self,$l,$row,$n,$node) = @_;
            my @row;
            for my $val (@$row) {
                push @row,$node->expandText($l,\$val);
            }
            return @row;
        },
        titleColor => $self->titleColor,
        titleWrapper => '\textsf{\textbf{%s}}',
        titles => scalar $atb->titles,
        titleCallback => sub {
            my ($self,$l,$title,$n,$node) = @_;
            return $node->expandText($l,\$title);
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
