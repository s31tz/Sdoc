package Sdoc::Node::Link;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Link - Link-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Link.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Inhaltsverzeichnis-Knoten folgende zusätzliche Attribute:

=over 4

=item name => $name (Default: undef)

Name der Link-Definition.

=item file => $path (Default: undef)

Pfad einer lokalen Datei.

=item regex => $regex (Default: undef)

Regex, der den internen Zielknoten identifiziert.

=item url => $url (Default: undef)

URL eines externen Dokuments.

=item useCount => $n

Die Anzahl der Links im Text, die diesen Link-Knoten nutzen. Nach
dem Parsen kann anhand dieses Zählers geprüft werden, ob jeder
Link-Knoten genutzt wird.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Link-Knoten

=head4 Synopsis

    $lnk = $class->new($par,$variant,$root,$parent);

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

Link-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Link:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # nichts
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Link',$variant,$root,$parent,
        name => undef,
        file => undef,
        regex => undef,
        url => undef,
        useCount => 0,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code (Leerstring)

=head4 Synopsis

    $code = $node->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

Leerstring ('')

=cut

# -----------------------------------------------------------------------------

sub latex {
    my $self = shift;
    return '';
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
