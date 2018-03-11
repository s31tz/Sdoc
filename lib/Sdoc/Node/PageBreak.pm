package Sdoc::Node::PageBreak;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::PageBreak - Seitenumbruch-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Seitenumbruch.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Inhaltsverzeichnis-Knoten folgende zusätzliche Attribute:

I<keine>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Seitenumbruch-Knoten

=head4 Synopsis

    $pbr = $class->new($par,$variant,$root,$parent);

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

Seitenumbruch-Knoten (Object)

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
        my $line = $par->shiftLine;
        
        $attribH = {
            input => $line->input,
            lineNum => $line->number,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('PageBreak',$variant,$root,$parent,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 generateLatex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $pbr->generateLatex($gen);

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
    return $l->c('\newpage',-nl=>2);
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
