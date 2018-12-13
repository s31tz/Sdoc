package Sdoc::Node::Table;
use base qw/Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 3.00;

use Sdoc::Core::AsciiTable;
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

=item align => 'left'|'center' (Default: 'left')

Horizontale Ausrichtung der Tabelle.

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
        align => 'left',
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

=head2 Einrückung

=head3 indentBlock() - Prüfe, ob Tabelle eingrückt werden soll

=head4 Synopsis

    $bool = $tab->indentBlock;

=head4 Returns

Bool

=cut

# -----------------------------------------------------------------------------

sub indentBlock {
    my $self = shift;

    if (substr($self->align,0,1) eq 'c') {
        return 0;
    }

    my $indentMode = $self->root->getUserNodeAttribute('indentMode');
    my $indent = $self->indent;

    return $indent || $indentMode && !defined $indent? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 css() - Generiere CSS-Code

=head4 Synopsis

    $code = $tab->css($c,$global);

=head4 Arguments

=over 4

=item $c

Generator für CSS.

=item $global

Wenn gesetzt, werden die globalen CSS-Regeln der Knoten-Klasse
geliefert, sonst die lokalen CSS-Regeln der Knoten-Instanz.

=back

=head4 Returns

CSS-Code (String)

=head4 Description

Generiere den CSS-Code der Knoten-Klasse oder der Knoten-Instanz
und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub css {
    my ($self,$c,$global) = @_;

    my $doc = $self->root;

    if ($global) {
        # Globale CSS-Regeln der Knoten-Klasse

        my $cssClass = $self->cssClass;

        return $c->rules(
            ".$cssClass.indent" => [
                marginLeft => $doc->htmlIndentation.'px',
            ],
            ".$cssClass table" => [
                borderCollapse => 'collapse',
            ],
            ".$cssClass table th" => [
                padding => '4px',
            ],
            ".$cssClass table td" => [
                padding => '4px',
            ],
            # Default-Layout der Bildunterschrift
            # * Text verkleinert
            # * Abstand zwischen Bild und Text verkleinert
            # * Präfix fett
            ".$cssClass p" => [
                # fontSize => 'smaller',
                marginTop => '6px',
            ],
            ".$cssClass span.prefix" => [
                fontWeight => 'bold',
            ],
        );
    }

    # Lokale CSS-Regeln der Tabellen-Instanz

    my $atb = $self->asciiTable;
    my (@div,@table,@thead,@th,@tr,@td,@tdLast);

    # Titelfarbe

    if (my $color = $self->titleColor) {
        push @thead,backgroundColor=>$color;
    }

    # Ausrichtung der Tabelle als Ganzes

    if (substr($self->align,0,1) eq 'c') {
        push @div,textAlign=>'center';
        push @table,margin=>'0 auto';
    }

    # Umrandung

    my $border = $self->border;
    if (!defined $border) {
        $border = $atb->multiLine? 'hvHV': 'hHV';
    }

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
        push @table,borderTop=>$b,borderBottom=>$b;
    }
    elsif ($bV) {
        push @table,borderLeft=>$b,borderRight=>$b;
    }

    return $c->restrictedRules('#'.$self->cssId,
        '' => \@div,
        'table' => \@table,
        'table thead' => \@thead,
        'table th' => \@th,
        'table td' => \@td,
        'table td:last-child' => \@tdLast,
        'table th:last-child' => \@tdLast,
    );
}

# -----------------------------------------------------------------------------

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

    my $doc = $self->root;
    my $atb = $self->asciiTable;

    # Prüfe, ob die Tabelle eingerückt werden soll. Wenn ja, fügen
    # wir die CSS-Klasse 'indent' hinzu.

    my $cssClass = $self->cssClass;
    if ($self->indentBlock) {
        $cssClass .= ' indent';
    }

    # Tabellenunterschrift

    my $caption = $self->caption;
    my $captionPrefix;
    if ($caption) {
        $captionPrefix = sprintf $doc->language eq 'german'? 'Tabelle %s: ':
            'Table %s: ',$self->number;
    }

    return $h->tag('div',
        class => $cssClass,
        id => $self->cssId,
        '-',
        Sdoc::Core::Html::Table::List->html($h,
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
        ),
        $h->tag('p',
            '-',
            $h->tag('span',
                class => 'prefix',
                $captionPrefix
            ),
            $h->tag('span',
                class => 'caption',
                $caption
            ),
        ),
    );
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
    # FIXME: Test durch $self->indentBlock ersetzen

    my $indent;
    if ($self->indent || $doc->getUserNodeAttribute('indentMode') &&
            !defined $self->indent) {
        $indent = $doc->latexIndentation.'pt';
    }

    # Trennlinien

    my $border = $self->border;
    if (!defined $border) {
        $border = $atb->multiLine? 'hvHV': 'hHV';
    }

    # LaTeX-Code erzeugen

    return Sdoc::Core::LaTeX::LongTable->latex($l,
        align => $self->align,
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

=head3 mediawiki() - Generiere MediaWiki-Code

=head4 Synopsis

    $code = $tab->mediawiki($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

MediaWiki-Code (String)

=cut

# -----------------------------------------------------------------------------

sub mediawiki {
    my ($self,$m) = @_;

    my $doc = $self->root;
    my $atb = $self->asciiTable;

    my $caption = $self->caption;
    if ($caption) {
        my $info = sprintf '%s %s',
            $doc->language eq 'german'? 'Tabelle': 'Table',
            $self->number;
        $caption = sprintf "%s: %s",$m->fmt('bold',$info),$caption;
    }

    # Einrückung

    my $code;
    if ($self->indentBlock) {
        $code .= $m->indent(1);
    }

    # Tabelle erzeugen

    $code .= $m->table(
        alignments => scalar $atb->alignments('html'),
        caption => $caption,
        rows => scalar $atb->rows,
        titleBackground => $self->titleColor,
        titles => scalar $atb->titles,
        valueCallback => sub {
            return $self->expandText($m,\shift);
        },
    );

    return $code;
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
