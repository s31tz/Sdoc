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

=item indent => $bool (Default: undef)

Rücke die Liste ein. Das Attribut ist nur für Aufzählungs- und
Markierungslisten von Bedeutung.

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

=head2 Formate

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $code = $lst->html($gen);

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

    my $id = sprintf 'lst%02d',$self->number;

    # Abbildung der Sdoc-Aufzählungstypen auf HTML-Aufzählungstypen

    my $listType = $self->listType;
    my $tag = {
        ordered => 'ol',
        unordered => 'ul',
        description => 'dl',
    }->{$listType};

    my @style;
    if ($doc->indentMode) {
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

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $lst->latex($gen);

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
