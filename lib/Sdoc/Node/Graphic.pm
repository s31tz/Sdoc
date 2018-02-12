package Sdoc::Node::Graphic;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::LaTeX::Figure;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Graphic - Abbildungs-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Abbildung.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Inhaltsverzeichnis-Knoten folgende zusätzliche Attribute:

=over 4

=item align => 'left'|'center'|'right' (Default: 'left')

Horizontale Ausrichtung des Bildes.

=item anchor => $anchor (Default: undef)

Anker der Abbildung.

=item anchorA => \@anchors (memoize)

Anker-Pfad der Grafik.

=item border => $bool (Default: 0)

Zeichne einen Rahmen um die Abbildung.

=item borderMargin => $length (Default: '0mm')

Zeichne den Rahmen (Attribut C<border>) mit dem angegebenen
Abstand um die Abbildung.

=item caption => $text

Beschriftung der Abbldung. Diese erscheint unter der Abbildung.

=item definition => $bool (Default: I<kontextabhängig>)

Wenn gesetzt, stellt der Grafik-Block lediglich eine Definition dar,
d.h. die Grafik wird nicht an dieser Stelle angezeigt, sondern an
anderer Stelle von einem G-Segment referenziert. Ist Attribut
C<name> definiert, ist der Default 1, andernfalls 0.

=item file => $path

Pfad der Bilddatei. Beginnt der Pfad mit C<+/>, wird das
Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=item latexOptions => $str

LaTeX-spezifische Optionen, die als direkt an das LaTeX-Makro
C<\includegraphics> übergeben werden.

=item linkId => $linkId

Die Grafik ist Ziel eines Link. Dies ist der Anker für das
Zielformat.

=item name => $name

Name der Grafik. Ein Name muss angegeben sein, wenn die Grafik von
einem G-Segment referenziert wird. Ist ein Name gesetzt, ist der
Default für das Attribut C<definition> 1, sonst 0.

=item noIndentation => $bool (Default: 0)

Rücke die Grafik nicht ein. Das Attribut ist nur bei C<< align =>
'left' >> von Bedeutung.

=item scale => $factor

Skalierungsfaktor. Im Falle von LaTeX wird dieser zu den
C<latexOptions> hinzugefügt, sofern dort kein Skalierungsfaktor
angegeben ist.

=item useCount => $n

Die Anzahl der G-Segmente im Text, die diesen Grafik-Knoten
nutzen. Nach dem Parsen kann anhand dieses Zählers geprüft werden,
ob jeder Grafik-Knoten mit C<definition=1> genutzt wird.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Abbildungs-Knoten

=head4 Synopsis

    $toc = $class->new($par,$variant,$root,$parent);

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

Abbildungs-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Graphic:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # nichts
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Graphic',$variant,$root,$parent,
        align => 'left',
        anchor => undef,
        border => 0,
        borderMargin => '0mm',
        caption => undef,
        captionS => undef,
        definition => undef,
        file => undef,
        formulaA => [],
        graphicA => [],
        noIndentation => 0,
        latexOptions => undef,
        linkA => [],
        linkId => undef,
        name => undef,
        scale => undef,
        useCount => 0,
        # memoize
        anchorA => undef,
    );
    $self->setAttributes(%$attribH);

    # Defaultwert für definition

    if (!defined $self->definition) {
        $self->set(definition=>$self->name? 1: 0);
    }

    # Segmente in caption parsen
    $par->parseSegments($self,'caption');

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Verweise

=head3 anchor() - Anker des Abschnitts

=head4 Synopsis

    $anchor = $gph->anchor;

=head4 Returns

Anker (String)

=head4 Description

Liefere den Wert des Attributs C<anchor>. Falls dies keinen Wert hat,
liefere den Wert des Attributs C<caption>.

=cut

# -----------------------------------------------------------------------------

sub anchor {
    my $self = shift;
    return $self->get('anchor') || $self->caption;
}

# -----------------------------------------------------------------------------

=head3 latexLinkText() - Verweis-Text

=head4 Synopsis

    $linkText = $gph->latexLinkText($l);

=head4 Returns

Text (String)

=head4 Description

Liefere den Verweis-Text als fertigen LaTeX-Code.

=cut

# -----------------------------------------------------------------------------

sub latexLinkText {
    my ($self,$l) = @_;
    return $self->latexText($l,'captionS');
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $gph->latex($gen);

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

    my $root = $self->root;

    if ($self->definition) {
        return '';
    }

    return Sdoc::Core::LaTeX::Figure->latex($l,
        align => substr($self->align,0,1),
        border => $self->border,
        borderMargin => $self->borderMargin,
        caption => $self->latexText($l,'captionS'),
        file => $root->expandPlus($self->file),
        indent => $self->noIndentation? undef: $root->indentation.'em',
        label => $self->linkId,
        options => $self->latexOptions,
        postVSpace => $l->modifyLength($root->latexParSkip,'*-2'),
        scale => $self->scale,
    )."\n";
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
