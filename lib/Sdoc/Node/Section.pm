package Sdoc::Node::Section;
use base qw/Sdoc::Node/;

use v5.10.0;
use strict;
use warnings;

our $VERSION = '3.00';

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

Der Abschnitt gehört zu den Appendix-Abschnitten.

=item level => $n

Tiefe des Abschnitts in der Abschnittshierarchie. Werte: =- -1,
==- 0, = 1, == 2, === 3, ==== 4.

=item linkA => \@links

Array mit Informationen über die im Abschnittstitel vorkommenden
Links.

=item linkId => $str (memoize)

Berechneter SHA1-Hash, unter dem der Knoten von einem
Verweis aus referenziert wird.

=item notToc => $bool (Default: 0)

Wenn gesetzt, wird der Abschnitt nicht ins Inhaltsverzeichnis
übernommen. Dieses Attribut wird von der Methode
$doc->flagSectionsNotToc() nach dem Parsen des Dokumentbaums
für alle Abschnitte gesetzt, die Unterabschnitte eines Abschnitts
mit C<notToc=1> sind.

=item sectionNumber => $str (Default: undef)

Nummer des Abschitts in der Form N.N.N. Der Wert wird beim ersten
Zugriff über die Methode sectionNumber() für alle Abschnitte
gesetzt.

=item referenced => $n (Default: 0)

Der Abschnitt ist $n Mal Ziel eines Link. Zeigt an,
ob für den Abschnitt ein Anker erzeugt werden muss.

=item title => $str

Titel des Abschnitts.

=item titleS => $str

Titel des Abschnitts nach Parsing der Segmente.

=item tocStop => $bool (Default: 0)

Alle Abschnitte unterhalb dieses Abschnitts werden nicht in das
Inhaltsverzeichnis aufgenommen.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'sec';

# -----------------------------------------------------------------------------

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
        $title =~ s/\s*=+$//; # trailing =+ entfernen
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
        sectionNumber => undef,
        notToc => 0,
        referenced => 0,
        tocStop => 0,
        title => undef,
        titleS => undef,
        # memoize
        anchorA => undef,
        linkId => undef,
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'title');

    # Konsistenz-Prüfungen

    if ($self->isAppendix && $self->level > 1) {
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

=head2 Abschnittsnummer

=head3 sectionNumber() - Dokument-Abschnittsnummer

=head4 Synopsis

  $str = $sec->sectionNumber;

=head4 Returns

Dokument-Abschnittsnummer (String)

=head4 Description

Liefere die Dokument-Abschnittsnummer. Die Dokument-Abschnittsnummer
besteht aus n Zahlen, die mit einem Punkt getrennt sind, wobei
jede Zahl eine Abschnittsebene nummeriert. Z.B. 1.3.2.

=cut

# -----------------------------------------------------------------------------

sub sectionNumber {
    my $self = shift;
    $self->root->numberSections;
    return $self->get('sectionNumber');
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

=head3 linkText() - Verweis-Text

=head4 Synopsis

  $linkText = $sec->linkText($gen);

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

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $sec->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub htmlCode {
    my ($self,$h) = @_;
    return $self->htmlSectionCode($h).$self->generateChilds('html',$h);
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $sec->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latexCode {
    my ($self,$l) = @_;

    my $doc = $self->root;

    # Beginnen mit dem Abschnitt die Appendizes?
    # Bei LaTeX wird nur der Beginn gekennzeichnet.

    my $code;
    my $first = $doc->firstAppendixSection;
    if ($first && $self == $first) {
        $code .= $l->c('\appendix');
    }
    $code .= $l->section(
        $self->latexSectionName($l),
        $self->expandText($l,'titleS'),
        -label => $self->referenced? $self->linkId: undef,
        -notToc => $self->notToc,
    );
    $code .= $self->generateChilds('latex',$l);

    return $code;
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $sec->mediawikiCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

MediaWiki-Code (String)

=cut

# -----------------------------------------------------------------------------

sub mediawikiCode {
    my ($self,$m) = @_;

    my $doc = $self->root;

    my $level = $self->level+(1-$doc->highestSectionLevel);
    my $title = $self->expandText($m,'titleS');
    my $code = $m->section(($level,$title));
    $code .= $self->generateChilds('mediawiki',$m);

    return $code;
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
