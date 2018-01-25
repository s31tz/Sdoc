package Sdoc::Node::Table;
use base qw/Sdoc::Node/;

use strict;
use warnings;

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

=item text => $text

Quelltext der Tabelle.

=item object => $obj

Referenz auf das Sdoc::Core::AsciiTable-Objekt.

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

    my $self = $class->SUPER::new('Table',$variant,$root,$parent,
        asciiTable => undef,
        text => undef,
    );
    $self->setAttributes(%$attribH);

    # AsciTable-Objekt instantiieren
    $self->set(asciiTable=>Sdoc::Core::AsciiTable->new($self->text));

    return $self;
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
    return $self->asciiTable->asLaTeX($gen);
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
