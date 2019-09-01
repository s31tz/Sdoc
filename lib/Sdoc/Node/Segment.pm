package Sdoc::Node::Segment;
use base qw/Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '3.00';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Segment - Segment-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Segment-Definition.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Segment-Knoten folgende zusätzliche Attribute:

=over 4

=item name => $name (Default: undef)

Name der Segment-Definition.

=item html => $code (Default: undef)

Umsetzung des Segment-Texts nach HTML.

=item latex => $code (Default: undef)

Umsetzung des Segment-Texts nach LaTeX.

=item mediawiki => $code (Default: undef)

Umsetzung des Segment-Texts nach MediaWiki.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'seg';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Segment-Knoten

=head4 Synopsis

    $seg = $class->new($par,$variant,$root,$parent);

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

Segment-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Segment:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # nichts
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Segment',$variant,$root,$parent,
        name => undef,
        html => undef,
        latex => undef,
        mediawiki => undef,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

    $code = $seg->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Segment-Knoten hat keine Darstellung, daher liefert die Methode
konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub htmlCode {
    my ($self,$h) = @_;
    return '';
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $seg->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Segment-Knoten hat keine Darstellung, daher liefert die Methode
konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub latexCode {
    my ($self,$l) = @_;
    return '';
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

    $code = $seg->mediawikiCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Segment-Knoten hat keine Darstellung, daher liefert die Methode
konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub mediawikiCode {
    my ($self,$l) = @_;
    return '';
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
