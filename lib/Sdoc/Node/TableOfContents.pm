package Sdoc::Node::TableOfContents;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

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

=item htmlTitle => $bool (Default: 1)

Wenn gesetzt, wird in HTML das Inhaltsverzeichnis mit einer
Überschrift ("Inhaltsverzeichnis" oder "Contents") versehen.

=item maxDepth => $n (Default: 3)

Tiefe, bis zu welcher Abschnitte ins Inhaltsverzeichnis
aufgenommen werden. Mögliche Werte: -2, -1, 0, 1, 2, 3, 4. -2 =
kein Inhaltsverzeichnis.

=back

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
        htmlTitle => 1,
        maxDepth => 3,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 generateHtml() - Generiere HTML-Code

=head4 Synopsis

    $code = $toc->generateHtml($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateHtml {
    my ($self,$h) = @_;

    my $doc = $self->root;

    if ($self->maxDepth < -1) {
        # Kein Inhaltsverzeichnis
        return '';
    }

    return $doc->htmlTableOfContents($h,$self);
}

# -----------------------------------------------------------------------------

=head3 generateLatex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $toc->generateLatex($gen);

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

    if ($self->maxDepth < -1) {
        # Kein Inhaltsverzeichnis
        return '';
    }

    my $code = $l->c('{\hypersetup{hidelinks}\tableofcontents}');
    if (my $nextNode = $self->nextNode) {
        # Wenn der nächste Knoten kein Abschnitt ist, fügen wir
        # vertikalen Leerraum hinzu, da der Inhalt sonst direkt unter
        # dem Inhaltsverzeichnis "klebt".

        my $type = $nextNode->type;
        if (!($type eq 'Section' || $type eq 'BridgeHead')) {
            $code .= $l->c('\vspace{4ex}');
        }
    }

    return "$code\n";
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
