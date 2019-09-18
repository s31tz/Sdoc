package Sdoc::Node::TableOfContents;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::TableOfContents - Inhaltsverzeichnis-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Inhaltsverzeichnis.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Inhaltsverzeichnis-Knoten folgende zusätzliche Attribute:

=over 4

=item htmlIndent => $bool (Default: undef)

Rücke das Inhaltsverzeichnis ein.

=item htmlTitle => $bool (Default: 1)

(Default: 1) Versieh das Inhaltsverzeichnis in HTML mit einer
Überschrift ("Inhaltsverzeichnis" oder "Contents").

=item maxLevel => $n (Default: 3)

Tiefe, bis zu welcher Abschnitte ins Inhaltsverzeichnis
aufgenommen werden. Mögliche Werte: -2, -1, 0, 1, 2, 3, 4. -2 =
kein Inhaltsverzeichnis.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'toc';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Inhaltsverzeichnis-Knoten

=head4 Synopsis

  $toc = $class->new($par,$variant,$root,$parent);

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

Inhaltsverzeichnis-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %TableOfContents:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # nichts
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('TableOfContents',$variant,$root,$parent,
        htmlIndent => undef,
        htmlTitle => 1,
        maxLevel => 3,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 htmlTitle() - Inhaltsverzeichnis-Überschrift

=head4 Synopsis

  $str = $toc->htmlTitle;

=head4 Returns

Überschrift (String)

=head4 Description

Prüfe, ob das Attribut C<htmlTitle=BOOL> wahr ist. Wenn ja,
liefere die Überschrift für das Inhaltsverzeichnis passend
zur Dokument-Sprache (C<Document.language=LANGUAGE>).

=cut

# -----------------------------------------------------------------------------

sub htmlTitle {
    my $self = shift;

    my $title;
    if ($self->get('htmlTitle')) {
        my $doc = $self->root;
        $title = $doc->language eq 'german'? 'Inhaltsverzeichnis': 'Contents';
    }

    return $title;
}

# -----------------------------------------------------------------------------

=head2 Einrückung

=head3 indentBlock() - Prüfe, ob Inhaltsverzeichnis eingerückt werden soll

=head4 Synopsis

  $bool = $toc->indentBlock;

=head4 Returns

Bool

=cut

# -----------------------------------------------------------------------------

sub indentBlock {
    my $self = shift;

    my $indentMode = $self->root->getUserNodeAttribute('indentMode');
    my $htmlIndent = $self->htmlIndent;

    return $htmlIndent || $indentMode && !defined $htmlIndent? 1: 0;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 css() - Generiere CSS-Code

=head4 Synopsis

  $code = $toc->css($c,$global);

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

        return $c->restrictedRules('.'.$self->cssClass,
            '' => [
                # Leerraum unter- und oberhalb des Konstrukts
                # marginTop => '8px',
                marginTop => '16px',
                marginBottom => '26px',
            ],
            'h3' => [
                # Kein Rand oberhalb des Inhaltsverzeichnisses
                marginTop => 0,
                # Abstand zw. Überschrift und Baum verkleinern
                marginBottom => '8px',
            ],
            'ul' => [
                # Kein Item-Symbol
                listStyleType => 'none',
            ],
            '> ul' => [
                margin => 0,
                paddingLeft => 0,
            ],
            '> ul.indent' => [
                # Abstand vom linken Rand, wenn Einrückung
                marginLeft => $doc->htmlIndentation.'px',
            ],
            'ul ul' => [
                # Einrückung der tieferen Ebenen
                paddingLeft => '22px',
            ],
            'li' => [
                # Abstand zwischen den Inhaltsverzeichnis-Zeilen
                marginTop => '2px',
                marginBottom => '2px',
            ],
            'span.number' => [
                # zus. Abstand zw. Abschnittsnummer und Abschnittstitel
                paddingRight => '2px',
            ],
        );
    }

    # Lokale CSS-Regeln der Knoten-Instanz
    return '';
}

# -----------------------------------------------------------------------------

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $toc->htmlCode($gen);

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

    my $html = '';
    if ($self->maxLevel >= -1) {
        $html = $self->root->htmlTableOfContents($h,$self);
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $toc->latexCode($gen);

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

    if ($self->maxLevel < -1) {
        # Kein Inhaltsverzeichnis
        return '';
    }

    my $code = $l->c('{\hypersetup{hidelinks}\tableofcontents}');

    # Wenn der nächste Knoten kein Abschnitt ist, fügen wir
    # vertikalen Leerraum hinzu, da der Inhalt sonst direkt unter
    # dem Inhaltsverzeichnis "klebt". Wir überlesen alle Knoten,
    # die keine visuelle Repräsentation haben.

    if (my $node = $self->nextVisibleNode) {
        my $type = $node->type;
        if (!($type eq 'Section' || $type eq 'BridgeHead')) {
            $code .= $l->c('\vspace{4ex}');
            
        }
    }

    return "$code\n";
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $toc->mediawikiCode($gen);

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

    # MEMO: Ein Inhaltsverzeichnis kann nicht mit : eingerückt werden

    return $m->tableOfContents($self->maxLevel >= -1);
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
