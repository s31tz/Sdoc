package Sdoc::Node::Comment;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Comment - Kommentar-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Kommentar.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Kommentar-Knoten folgende zusätzliche Attribute:

=over 4

=item text => $text

Text des Kommentars.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Kommentar-Knoten

=head4 Synopsis

    $com = $class->new($par,$variant,$root,$parent);

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

Kommentar-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Comment:
        #   KEY=VAL
        # TEXT
        # .
        $attribH = $par->readBlock('text');
    }
    elsif ($markup eq 'sdoc') {
        # # TEXT

        my $lineA = $par->lines;
        my $input = $lineA->[0]->input;
        my $lineNum = $lineA->[0]->number;

        my $text = '';
        while (@$lineA) {
            my $str = $lineA->[0]->text;
            if (substr($str,0,2) ne '% ') {
                last;
            }
            $text .= substr($str,1)."\n";
            shift @$lineA;
        }
        $text = Sdoc::Core::Unindent->string($text);
        chomp $text;

        $attribH = {
            input => $input,
            lineNum => $lineNum,
            text => $text,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Comment',$variant,$root,$parent,
        text => undef,
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 generateHtml() - Generiere HTML-Code

=head4 Synopsis

    $code = $par->generateHtml($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateHtml {
    my ($self,$h) = @_;

    if (!$self->root->copyComments) {
        # Keine Kommentare ins Zielformat übernehmen
        return '';
    }

    return $h->comment($self->text);
}

# -----------------------------------------------------------------------------

=head3 generateLatex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $com->generateLatex($gen);

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

    if (!$self->root->copyComments) {
        # Keine Kommentare ins Zielformat übernehmen
        return '';
    }

    return $l->comment($self->text,-nl=>2);
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
