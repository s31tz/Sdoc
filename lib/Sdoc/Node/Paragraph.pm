package Sdoc::Node::Paragraph;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Paragraph - Paragraph-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Paragraphen.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Paragraph-Knoten folgende zusätzliche Attribute:

=over 4

=item formulaA => \@formulas

Array mit den im Paragraph vorkommenden Formeln aus M{}-Segmenten.

=item graphicA => \@graphics

Array mit Informationen über die im Paragraph vorkommenden
G-Segmente (Inline-Grafiken).

=item linkA => \@links

Array mit Informationen über die im Paragraph vorkommenden
L-Segmenten (Links).

=item text => $text

Text des Paragraphen.

=item textS => $textS

Text des Paragraphen mit geparsten Segmenten.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Paragraph-Knoten

=head4 Synopsis

    $par = $class->new($par,$variant,$root,$parent);

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

Paragraph-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Paragraph:
        #   KEY=VAL
        # TEXT
        # .
        $attribH = $par->readBlock('text');
    }
    elsif ($markup eq 'sdoc') {
        # TEXT

        my $lineA = $par->lines;
        my $input = $lineA->[0]->input;
        my $lineNum = $lineA->[0]->number;

        my $text = '';
        while (@$lineA) {
            my $line = $lineA->[0];
            if ($line->isEmpty || $par->nextType ne 'Paragraph') {
                last;
            }
            $text .= $line->textNl;
            shift @$lineA;
        }
        chomp $text;

        $attribH = {
            input => $input,
            lineNum => $lineNum,
            text => $text,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Paragraph',$variant,$root,$parent,
        formulaA => [],
        graphicA => [],
        linkA => [],
        text => undef,
        textS => undef,
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'text');

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $par->latex($gen);

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
    return $self->latexText($l,'textS')."\n\n";
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
