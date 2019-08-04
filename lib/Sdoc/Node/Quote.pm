package Sdoc::Node::Quote;
use base qw/Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '3.00';

use Sdoc::Core::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Quote - Zitat-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Zitat.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Zitat-Knoten folgende zusätzliche Attribute:

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

Text des Zitats.

=item textS => $textS

Text des Paragraphen mit geparsten Segmenten.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'quo';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Zitat-Knoten

=head4 Synopsis

    $quo = $class->new($par,$variant,$root,$parent);

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

Zitat-Knoten (Object)

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
            if (substr($str,0,2) ne '> ') {
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

    my $self = $class->SUPER::new('Quote',$variant,$root,$parent,
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

=head3 css() - Generiere CSS-Code

=head4 Synopsis

    $code = $quo->css($c,$global);

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

        return $c->restrictedRules('.'.$self->cssClass,
            '' => [
                fontStyle => 'italic',
            ],
        );
    }

    # Lokale CSS-Regeln der Knoten-Instanz
    return '';
}

# -----------------------------------------------------------------------------

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $code = $quo->html($gen);

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
    my ($self,$h) = @_;

    return $h->tag('blockquote',
        class => $self->cssClass,
        $self->expandText($h,'textS')
    );
}

# -----------------------------------------------------------------------------

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $quo->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latex {
    my ($self,$l) = @_;

    # Quote-Umgebung

    return $l->env('quoting',$self->expandText($l,'textS'),
        -nl => 2,
    );
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
