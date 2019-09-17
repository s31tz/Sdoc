package Sdoc::Node::List;
use base qw/Sdoc::Node/;

use v5.10.0;
use strict;
use warnings;

our $VERSION = '3.00';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::List - Listen-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Listen-Knoten folgende zusätzliche Attribute:

=over 4

=item childA => \@childs

Liste der Subknoten.

=item indent => $bool (Default: undef)

Rücke die Liste ein. Das Attribut ist nur für Aufzählungs- und
Markierungslisten von Bedeutung.

=item listType => $listType

Art der Liste. Mögliche Werte: 'description', 'ordered', 'unordered'.
Wenn nicht gesetzt, wird der Wert vom ersten List-Item gesetzt.

=item number => $n

Nummer der Liste. Wird automatisch hochgezählt.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'lst';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Listen-Knoten

=head4 Synopsis

  $lst = $class->new($par,$variant,$root,$parent);

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

Listen-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %List:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # nichts
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('List',$variant,$root,$parent,
        childA => [],
        indent => undef,
        listType => undef,
        number => $root->increment('countList'),
    );
    $self->setAttributes(%$attribH);

    # Child-Knoten verarbeiten
    
    my $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant,$type) = $par->nextType(1);

        if ($type ne 'Item') {
            # Abbruch bei einem anderen Typ als Item
            last;
        }
        else { # $type eq 'Item'
            my $listType = $self->listType;
            if ($listType && $listType ne $par->listType) {
                # Abbruch bei einem Item eines anderen Listentyps
                last;
            }
        }

        $self->push(childA=>$nodeClass->new($variant,$par,$root,$self));
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Test

=head3 isEmbedded() - Prüfe, ob Liste in andere Liste eingebettet ist

=head4 Synopsis

  $bool = $lst->isEmbedded;

=head4 Returns

Bool

=head4 Description

Prüfe, ob die Liste in einer anderen Liste untergeordnet ist. Wenn
ja liefere 1, wenn nein, liefere 0.

=cut

# -----------------------------------------------------------------------------

sub isEmbedded {
    my $self = shift;

    my $node = $self;
    while ($node = $node->parent) {
        if ($node->type eq 'List') {
            return 1;
        }
    }

    return 0;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 css() - Generiere CSS-Code

=head4 Synopsis

  $code = $lst->css($c,$global);

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
    
    if ($global) {
        # Globale CSS-Regeln der Knoten-Klasse

        my $doc = $self->root;
        my $cssClass = $self->cssClass;

        my $htmlIndentation = $doc->htmlIndentation;

        return $c->restrictedRules(".$cssClass",
            '' => [
                # Rand ober- und unterhalb der Liste
                marginTop => '16px',
                marginBottom => '16px',
            ],
            '> ul:first-child' => [
                paddingLeft => ($htmlIndentation+14).'px',
            ],
            '> ol:first-child' => [
                paddingLeft => ($htmlIndentation+16).'px',
            ],
            '&.noindent > ul:first-child' => [
                paddingLeft => '15px',
            ],
            '&.noindent > ol:first-child' => [
                paddingLeft => '15px',
            ],
            '&.noindent > dl > dd' => [
                marginLeft => 0,
            ],
            'ul' => [
                marginTop => 0,
                marginBottom => 0,
            ],
            'li > *:first-child' => [
                # Kompakter Leerraum vor dem ersten Element
                marginTop => '4px',
            ],
            'li > *:last-child' => [
                # Kompakter Leerraum nach dem letzen Element
                marginBottom => '4px',
            ],
            'ol' => [
                marginTop => 0,
                marginBottom => 0,
            ],
            'dl' => [
                marginTop => 0,
                marginBottom => 0,
            ],
            'dt' => [
                fontWeight => 'bold',
            ],
            'dd' => [
                marginLeft => ($htmlIndentation+4).'px',
            ],
            'dd > *:first-child' => [
                # Kompakter Leerraum vor dem ersten Element
                marginTop => '2px',
            ],
            'dd > *:last-child' => [
                # Kompakter Leerraum nach dem letzen Element
                marginBottom => '6px',
            ],
            'p' => [
                marginTop => '4px',
                marginBottom => '4px',
            ],
        );
    }

    # Lokale CSS-Regeln der Knoten-Instanz
    return '';
}

# -----------------------------------------------------------------------------

=head3 htmlTag() - HTML-Tag der Liste

=head4 Synopsis

  $tag = $lst->htmlTag;

=head4 Returns

HTML Tag (String)

=head4 Description

Liefere den HTML-Tag der Liste. Der Tag ergibt sich aus dem Typ
der Liste:

  List-Type   HTML-Tag
  ----------- --------
  ordered        ol
  unordered      ul
  description    dl

=cut

# -----------------------------------------------------------------------------

my %ListTag = (
    ordered => 'ol',
    unordered => 'ul',
    description => 'dl',
);

sub htmlTag {
    my $self = shift;
    return $ListTag{$self->listType} // $self->throw;
}

# -----------------------------------------------------------------------------

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $lst->htmlCode($gen);

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

    # HTML der Liste erzeugen

    my $html = $h->tag($self->htmlTag,
        $self->generateChilds('html',$h)
    );

    # Wenn oberste Liste, Struktur in <div> einfassen

    if (!$self->isEmbedded) {
        # Einrückung. Wir setzen CSS-Klasse "noindent", wenn *keine*
        # Einrückung erfolgen soll.

        my $cssClass = $self->cssClass;
        my $indent = $self->indent;
        if (defined $indent && $indent eq '0') {
            $cssClass .= ' noindent';
        }

        $html = $h->tag('div',
            class => $cssClass,
            id => $self->cssId,
            $html
        );
    }
    
    return $html;
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $lst->latexCode($gen);

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

    my $doc = $self->root;

    # Abbildung der Sdoc-Aufzählungstypen auf die LaTeX-Aufzählungstypen

    my $listType = $self->listType;
    if ($listType eq 'ordered') {
        $listType = 'enumerate';
    }
    elsif ($listType eq 'unordered') {
        $listType = 'itemize';
    }

    # Einrückung

    my $indent = 0;
    if ($self->indent || !defined $self->indent) {
        $indent = $doc->latexIndentation;
    }
    
    my @opt;
    if ($listType eq 'itemize') {
        # 10pt ist der Offset, bei dem der Bullet genau am linken Rand steht
        push @opt,sprintf 'leftmargin=%spt',10+$indent;
    }
    elsif ($listType eq 'enumerate') {
        # 11pt ist der Offset, bei die Zahl genau am linken Rand steht
        push @opt,sprintf 'leftmargin=%spt',12+$indent;
    }
    else { # $listType eq 'description'
        push @opt,
            'style=nextline', # Kann auch global gesetzt werden
            sprintf 'leftmargin=%spt',$indent;
    }

    # Childs

    my $childs = $self->generateChilds('latex',$l);
    $childs =~ s/\n{2,}$/\n/;

    # LaTeX-Code generieren

    return $l->env($listType,
        $childs,
        -o => \@opt,
        -nl => 2,
    );
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $lst->mediawikiCode($gen);

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

    my $code = $self->generateChilds('mediawiki',$m);
    if ($self->parent->type ne 'Item') {
        # Sind wir eine Unterliste, fügen wir keinen
        # zusätzlichen Zeilenumbruch an
        $code .= "\n";
    }

    return $code;
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
