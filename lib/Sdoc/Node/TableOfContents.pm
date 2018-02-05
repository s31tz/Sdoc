package Sdoc::Node::TableOfContents;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

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

=item maxDepth => $n (Default: 3)

Tiefe, bis zu welcher Abschnitte ins Inhaltsverzeichnis
aufgenommen werden. Mögliche Werte: 0, 1, 2, 3, 4, 5. 0 = kein
Inhaltsverzeichnis.

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
        maxDepth => 3,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $toc->latex($gen);

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

    if ($self->maxDepth == 0) {
        # Kein Inhaltsverzeichnis
        return '';
    }

    return $self->root->latexTableOfContents($l);
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
