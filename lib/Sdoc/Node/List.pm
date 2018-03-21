package Sdoc::Node::List;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Css;

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

=item listType => $listType

Art der Liste. Mögliche Werte: 'description', 'ordered', 'unordered'.
Wenn nicht gesetzt, wird der Wert vom ersten List-Item gesetzt.

=item number => $n

Nummer der Liste. Wird automatisch hochgezählt.

=back

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
        listType => undef,
        number => $root->increment('countList'),
    );
    $self->setAttributes(%$attribH);

    # Child-Knoten verarbeiten
    
    my $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant,$type) = $par->nextType(1);

        # Abbruch bei einem anderen Typ als Item oder einem Item
        # eines anderen Listentyps
        
        if ($type ne 'Item') {
            last;
        }

        $self->push(childA=>$nodeClass->new($variant,$par,$root,$self));
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 generateHtml() - Generiere HTML-Code

=head4 Synopsis

    $code = $lst->generateHtml($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateHtml {
    my ($self,$h) = @_;

    my $doc = $self->root;

    my $id = sprintf 'lst%02d',$self->number;

    # Abbildung der Sdoc-Aufzählungstypen auf HTML-Aufzählungstypen

    my $listType = $self->listType;
    my $tag = {
        ordered => 'ol',
        unordered => 'ul',
        description => 'dl',
    }->{$listType};

    my @style;
    if ($doc->indentStyle) {
        push @style,paddingLeft=>sprintf('%spx',$doc->htmlIndentation+18);
    }

    # Generiere HTML

    return $h->cat(
        $h->tag('style',
            Sdoc::Core::Css->new('flat')->restrictedRules("#$id",
                '' => \@style,
                # FIXME: In Default-Stylesheet verlagern
                'li > *:first-child' => [
                    marginTop => '4px',
                ],
                'li > *:last-child' => [
                    marginBottom => '4px',
                ],
            )
        ),
        $h->tag($tag,
            class => "sdoc-list-$listType",
            id => $id,
            $self->generateChilds('html',$h)
        ),
    );
}

# -----------------------------------------------------------------------------

=head3 generateLatex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $lst->generateLatex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateLatex {
    my ($self,$l) = @_;

    my $root = $self->root;

    # Abbildung der Sdoc-Aufzählungstypen auf die LaTeX-Aufzählungstypen

    my $listType = $self->listType;
    if ($listType eq 'ordered') {
        $listType = 'enumerate';
    }
    elsif ($listType eq 'unordered') {
        $listType = 'itemize';
    }

    # Durch die Sonderbehandlung von itemize und enumerate sorgen wir
    # dafür, dass die Einrückung von enumerate, itemize und verbatim
    # (siehe Klasse Sdoc::Node::Code) aufeinander abgestimmt
    # ist. Die Option leftmargin setzt das LaTeX-Paket enumitem
    # voraus.

    my $childs = $self->generateChilds('latex',$l);
    $childs =~ s/\n{2,}$/\n/;

    my @opt;
    if ($listType eq 'itemize') {
        push @opt,sprintf 'leftmargin=%sem',1.1+$root->latexIndentation;
    }
    elsif ($listType eq 'enumerate') {
        push @opt,sprintf 'leftmargin=%sem',1.15+$root->latexIndentation;
    }

    return $l->env($listType,
        $childs,
        -o => \@opt,
        -nl => 2,
    );
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
