package Sdoc::Node::BridgeHead;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::BridgeHead - Zwischenüberschrift-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Zwischenüberschrift.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Zwischenberschrifts-Knoten folgende zusätzliche Attribute:

=over 4

=item anchor => $anchor (Default: undef)

Anker der Zwischenüberschrift.

=item anchorA => \@anchors (memoize)

Anker-Pfad der Zwischenüberschrift.

=item formulaA => \@formulas

Array mit den im Abschnittstitel vorkommenden Formeln aus
M{}-Segmenten.

=item graphicA => \@graphics

Array mit Informationen über die im Abschnittstitel vorkommenden
G-Segmenten (Inline-Grafiken).

=item level => $n

Größe der Zwischenüberschrift, beginnend mit 1.

=item linkA => \@links

Array mit Informationen über die im Titel vorkommenden Links.

=item linkId => $linkId

Die Zwischenberschrift ist Ziel eines Link. Dies ist der Anker für
das Zielformat.

=item title => $str

Titel der Zwischenüberschrift.

=item titleS => $str

Titel des Zwischenberschrift nach Parsing der Segmente.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Zwischenüberschrifts-Knoten

=head4 Synopsis

    $sec = $class->new($par,$variant,$root,$parent);

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

Abschnitts-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Section:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # =+[*]* TITLE

        my $line = $par->shiftLine;
        $line->text =~ /^(=+)([*]*) (.*)/;

        my $level = length $1;
        my $title = $3;
        $title =~ s/^\s+//g;
        $title =~ s/\s+$//g;
        $title =~ s/\s{2,}/ /g;

        $attribH = {
            input => $line->input,
            lineNum => $line->number,
            level => $level,
            title => $title,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('BridgeHead',$variant,$root,$parent,
        anchor => undef,
        formulaA => [],
        graphicA => [],
        level => undef,
        linkA => [],
        linkId => undef,
        title => undef,
        titleS => undef,
        # memoize
        anchorA => undef,
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'title');

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Anker

=head3 anchor() - Anker der Zwischenüberschrift

=head4 Synopsis

    $anchor = $sec->anchor;

=head4 Returns

Anker (String)

=head4 Description

Liefere den Wert des Attributs C<anchor>. Falls dies keinen Wert hat,
liefere den Wert des Attributs C<title>.

=cut

# -----------------------------------------------------------------------------

sub anchor {
    my $self = shift;
    return $self->get('anchor') || $self->title;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $brh->latex($gen);

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

    return $gen->section(
        $self->latexLevelToSectionName($gen,$self->level),
        $self->latexText($gen,'titleS'),
        -label => $self->linkId,
        -toc => 0,
    );
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
