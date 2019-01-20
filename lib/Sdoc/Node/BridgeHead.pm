package Sdoc::Node::BridgeHead;
use base qw/Sdoc::Node/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 3.00;

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
Zwischenüberschrifts-Knoten folgende zusätzliche Attribute:

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

=item linkId => $str (memoize)

Berechneter SHA1-Hash, unter dem der Knoten von einem
Verweis aus referenziert wird.

=item referenced => $n (Default: 0)

Die Zwischenüberschrift ist $n Mal Ziel eines Link. Zeigt an,
ob für die Zwischenüberschrift ein Anker erzeugt werden muss.

=item title => $str

Titel der Zwischenüberschrift.

=item titleS => $str

Titel des Zwischenüberschrift nach Parsing der Segmente.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'brk';

# -----------------------------------------------------------------------------

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
        $title =~ s/\s*=+$//; # trailing =+ entfernen
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
        referenced => 0,
        title => undef,
        titleS => undef,
        # memoize
        anchorA => undef,
        linkId => undef,
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'title');

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Verweise

=head3 anchor() - Anker der Zwischenüberschrift

=head4 Synopsis

    $anchor = $brh->anchor;

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

=head3 linkText() - Verweis-Text

=head4 Synopsis

    $linkText = $brh->linkText($gen);

=head4 Returns

Text (String)

=head4 Description

Liefere den Verweis-Text als fertigen Zielcode.

=cut

# -----------------------------------------------------------------------------

sub linkText {
    my ($self,$gen) = @_;
    return $self->expandText($gen,'titleS');
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $code = $brh->html($gen);

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
    return $self->htmlSectionCode($h);
}

# -----------------------------------------------------------------------------

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $brh->latex($gen);

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

    return $l->section(
        $self->latexSectionName($l),
        $self->expandText($l,'titleS'),
        -label => $self->referenced? $self->linkId: undef,
        -notToc => 1,
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
