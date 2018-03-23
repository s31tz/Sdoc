package Sdoc::Node::Include;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::LineProcessor;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Include - Include-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert includierten Sdoc-Quelltext.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Code-Knoten folgende zusätzliche Attribute:

=over 4

=item childA => \@childs

Liste der Subknoten.

=item load => $file

Lade Datei $file und füge dessen Inhalt in das Dokument
ein. Beginnt der Pfad mit C<+/>, wird das Pluszeichen zum Pfad des
Dokumentverzeichnisses expandiert.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Include-Knoten

=head4 Synopsis

    $inc = $class->new($par,$variant,$root,$parent);

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

Code-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Code:
        #   KEY=VAL
        # TEXT
        # .
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # nichts
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Include',$variant,$root,$parent,
        childA => [],
        load => undef,
    );
    $self->setAttributes(%$attribH);

    if (my $file = $root->expandPath($self->load)) {
        my $lineA = $par->lines;

        # Datei lesen und dem Input hinzufügen

        unshift @$lineA,Sdoc::Core::LineProcessor->new($file,
            -encoding => 'utf-8',
            -lineContinuation => 'backslash',
        )->lines;

        # Hinzugefügte Zeilen als Child-Knoten verarbeiten

        while (@$lineA) {
            my ($nodeClass,$variant,$type) = $par->nextType(1);

            # Ende, wenn alle Zeilen der Datei verarbeitet sind
            if ($lineA->[0]->input ne $file) {
                last;
            }

            $self->push(childA=>$nodeClass->new($variant,$par,$root,$self));
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $code = $inc->html($gen);

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
    my ($self,$gen) = @_;
    return $self->generateChilds('html',$gen);
}

# -----------------------------------------------------------------------------

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $inc->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latex {
    my ($self,$gen) = @_;
    return $self->generateChilds('latex',$gen);
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
