package Sdoc::Node::Section;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Section - Abschnitts-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Abschnitt.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Abschnitts-Knoten folgende zusätzliche Attribute:

=over 4

=item anchor => $anchor (Default: undef)

Anker des Abschnitts.

=item anchorA => \@anchors (memoize)

Anker-Pfad des Abschnitts.

=item childA => \@childs

Liste der Subknoten.

=item formulaA => \@formulas

Array mit den im Abschnittstitel vorkommenden Formeln aus
M{}-Segmenten.

=item graphicA => \@graphics

Array mit Informationen über die im Abschnittstitel vorkommenden
G-Segmente (Inline-Grafiken).

=item isAppendix => $bool (Default: 0)

Mit diesem Abschnitt beginnen die Appendizes.

=item level => $n

Tiefe des Abschnitts in der Abschnittshierarchie. Werte: =- -1,
==- 0, = 1, == 2, === 3, ==== 4.

=item linkA => \@links

Array mit Informationen über die im Abschnittstitel vorkommenden
Links.

=item linkId => $linkId

Der Abschnitt ist Ziel eines Link. Dies ist der Anker für das
Zielformat.

=item number => $str (Default: undef)

Nummer des Abschitts in der Form N.N.N (abhängig von der Ebene).
Der Attributwert wird automatisch generiert.

=item stopToc => $bool (Default: 0)

Alle Abschnitte unterhalb dieses Abschnitts werden nicht in das
Inhaltsverzeichnis aufgenommen.

=item title => $str

Titel des Abschnitts.

=item titleS => $str

Titel des Abschnitts nach Parsing der Segmente.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Abschnitts-Knoten

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
        # =+[!+]* TITLE

        my $line = $par->shiftLine;
        $line->text =~ /^(=+)([-+!]*) (.*)/;

        my $level = length $1;
        my $isHigher = index($2,'-') >= 0? 1: 0;
        my $isAppendix = index($2,'+') >= 0? 1: 0;
        my $tocStop = index($2,'!') >= 0? 1: 0;
        my $title = $3;
        $title =~ s/^\s+//g;
        $title =~ s/\s+$//g;
        $title =~ s/\s{2,}/ /g;

        $attribH = {
            input => $line->input,
            lineNum => $line->number,
            level => $isHigher? -2+$level: $level,
            isAppendix => $isAppendix,
            tocStop => $tocStop,
            title => $title,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Section',$variant,$root,$parent,
        anchor => undef,
        childA => [],
        formulaA => [],
        graphicA => [],
        isAppendix => 0,
        level => undef,
        linkA => [],
        linkId => undef,
        number => undef,
        tocStop => 0,
        title => undef,
        titleS => undef,
        # memoize
        anchorA => undef,
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'title');

    # Konsistenz-Prüfungen

    if ($self->isAppendix && $self->level != 1) {
        $self->warn('Appendix flag allowed on toplevel sections only');
        $self->isAppendix(0);
    }

    # Child-Knoten verarbeiten
    
    my $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant,$type) = $par->nextType(1);

        # Abbruch bei Section mit gleichem oder kleinerem Level
        if ($type eq 'Section' && $par->sectionLevel <= $self->level) {
            last;
        }

        $self->push(childA=>$nodeClass->new($variant,$par,$root,$self));
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Verweise

=head3 anchor() - Anker des Abschnitts

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

=head3 latexLinkText() - Verweis-Text

=head4 Synopsis

    $linkText = $sec->latexLinkText($l);

=head4 Returns

Text (String)

=head4 Description

Liefere den Verweis-Text als fertigen LaTeX-Code.

=cut

# -----------------------------------------------------------------------------

sub latexLinkText {
    my ($self,$l) = @_;
    return $self->latexText($l,'titleS');
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $sec->latex($gen);

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

    # Prüfe, ob die Abschnittsüberschrift im Inhaltsverzeichnis
    # unterdrückt werden soll. Dies ist der Fall, ein
    # *übergeordneter* Abschnitt seine untergeordneten
    # Abschnittsüberschriften blockiert hat (=!).

    my $toc = 1;
    my $node = $self;
    while ($node = $node->parent) {
        if ($node->type ne 'Section') {
            last;
        }
        elsif ($node->tocStop) {
            $toc = 0;
            last;
        }
    }

    my $code;

    # Beginnen mit dem Abschnitt die Appendizes?

    if ($self->isAppendix) {
        $code .= $l->c('\appendix');
    }

    $code .= $l->section(
        $self->latexLevelToSectionName($l,$self->level),
        $self->latexText($l,'titleS'),
        -label => $self->linkId,
        -toc => $toc,
    );
    $code .= $self->generateChilds('latex',$l);

    return $code;
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
