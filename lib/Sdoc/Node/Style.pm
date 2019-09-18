package Sdoc::Node::Style;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Style - Style-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert Stylesheet-Code

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Stylesheet-Knoten folgende zusätzliche Attribute:

=over 4

=item code => $code

Stylesheet-Code aus dem Rumpf des Style-Blocks.

=item source => $path

Pfad zu einer Stylesheet-Datei. Beginnt der Pfad mit C<+/>, wird
das Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'sty';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Stylesheet-Knoten

=head4 Synopsis

  $sty = $class->new($par,$variant,$root,$parent);

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
        # %Style:
        #   KEY=VAL
        # CODE
        # .
        $attribH = $par->readBlock('code');
    }
    elsif ($markup eq 'sdoc') {
        # kommt nicht vor
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Style',$variant,$root,$parent,
        code => '',
        source => undef,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Prüfung

=head3 validate() - Prüfe Knoten auf Korrektheit

=head4 Synopsis

  $sty->validate;

=cut

# -----------------------------------------------------------------------------

sub validate {
    my $self = shift;

    my $doc = $self->root;

    # Prüfe, dass die angegebene StyleSheet-Datei existiert

    if (my $path = $doc->expandPath($self->source)) {
        if (!-f $path) {
            $self->warn('StyleSheet does not exist: %s',$path);
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 css() - Generiere CSS-Code

=head4 Synopsis

  $code = $sty->css($c,$global);

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
        return '';
    }

    # Lokale CSS-Regeln der Knoten-Instanz

    my $code = $self->code;
    if ($code) {
        my $cssPrefix = $self->root->getUserNodeConfigAttribute('cssPrefix',
            'sdoc3');
        $code =~ s/\$PREFIX/$cssPrefix/g;
        $code .= "\n";
    }

    return $c->makeFlat($code);
}

# -----------------------------------------------------------------------------

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $sty->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Description

Ein Style-Knoten hat in HTML keine Darstellung, daher liefert
die Methode konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub htmlCode {
    my ($self,$h) = @_;
    return '';
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $sty->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Description

Ein Style-Knoten hat in LaTeX keine Darstellung, daher liefert
die Methode konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub latexCode {
    my ($self,$l) = @_;
    return '';
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $sty->mediawikiCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein Style-Knoten hat in MediaWiki keine Darstellung, daher liefert
die Methode konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub mediawikiCode {
    my ($self,$m) = @_;
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
