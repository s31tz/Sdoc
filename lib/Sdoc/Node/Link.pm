# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Link - Link-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Link-Definition.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Link-Knoten folgende zusätzliche Attribute:

=over 4

=item name => $name (Default: undef)

Name der Link-Definition. Mehrere Namen können mit | getrennt
definiert werden. Beispiel: C<name="Sdoc|Sdoc Homepage">

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

=cut

# -----------------------------------------------------------------------------

package Sdoc::Node::Link;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

# -----------------------------------------------------------------------------

our $Abbrev = 'lnk';

# -----------------------------------------------------------------------------

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

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $lnk->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Link-Knoten hat keine Darstellung, daher liefert die Methode
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

  $code = $lnk->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Link-Knoten hat keine Darstellung, daher liefert die Methode
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

  $code = $lnk->mediawikiCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Link-Knoten hat keine Darstellung, daher liefert die Methode
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

Copyright (C) 2021 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
