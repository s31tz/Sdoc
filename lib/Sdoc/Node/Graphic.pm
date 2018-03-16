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

=item file => $path

Pfad der Bilddatei. Beginnt der Pfad mit C<+/>, wird das
Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=item height => $height

Höhe in Pixeln (ohne Angabe einer Einheit), auf die das Bild
skaliert wird.

=item latexOptions => $str

LaTeX-spezifische Optionen, die als direkt an das LaTeX-Makro
C<\includegraphics> übergeben werden.

=item link => $url

Versieh die Grafik mit einem Verweis. Dies kann ein Verweis auf
ein internes oder externes Ziel sein wie bei einem L-Segment (nur
dass das Attribut den Link-Text als Wert hat ohne den
Segment-Bezeichner und die geschweiften Klammern).

=item linkId => $str (memoize)

Berechneter SHA1-Hash, unter dem der Knoten von einem
Verweis aus referenziert wird.

=item name => $name

Name der Grafik. Ein Name muss angegeben sein, wenn die Grafik von
einem G-Segment referenziert wird. Ist ein Name gesetzt, ist der
Default für das Attribut C<definition> 1, sonst 0.

=item indentation => $bool

Rücke die Grafik ein. Das Attribut ist nur bei C<< align =>
'left' >> oder bei Inline-Grafiken von Bedeutung.

=item referenced => $n (Default: 0)

Die Grafik ist $n Mal Ziel eines Link. Zeigt an,
ob für die Grafik ein Anker erzeugt werden muss.

=item scale => $factor

Skalierungsfaktor. Der Skalierungsfaktor hat bei LaTeX
Priorität gegenüber der Angabe von C<width> und C<height>.

=item show => $bool (Default: undef)

Wenn auf 1 gesetzt, wird die Grafik an Ort und Stelle angezeigt,
wenn 0, nicht. Sie nicht anzuzeigen macht Sinn, wenn sie lediglich
von G-Segmenten (Inline Grafik) genutzt werden soll. Der Default
für das Attribut ist 0, wenn C<< useCount > 0 >> (d.h. die Grafik wird
als Inline-Grafik genutzt), andernfalls 1.

=item useCount => $n

Die Anzahl der G-Segmente im Text, die diesen Grafik-Knoten
nutzen. Nach dem Parsen kann anhand dieses Zählers geprüft werden,
ob und wie oft ein Grafik-Knoten von G-Segmenten referenziert wird
(siehe auch Attribut C<show>).

=item width => $width

Breite in Pixeln (ohne Angabe einer Einheit), auf die das Bild
skaliert wird.

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
        file => undef,
        formulaA => [],
        graphicA => [],
        height => undef,
        indentation => undef,
        latexOptions => undef,
        link => undef,
        linkN => undef,
        linkA => [],
        name => undef,
        referenced => 0,
        scale => undef,
        show => undef,
        useCount => 0,
        width => undef,
        # memoize
        anchorA => undef,
        linkId => undef,
    );
    $self->setAttributes(%$attribH);

    # Bild-Link registrieren

    if (my $val = $self->link) {
        my $linkA = $self->linkA;
        push @$linkA,[$val,undef];
        $self->set(linkN=>$#$linkA);
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

=head3 linkText() - Verweis-Text

=head4 Synopsis

    $linkText = $gph->linkText($gen);

=head4 Returns

Text (String)

=head4 Description

Liefere den Verweis-Text als fertigen Zielcode. Dies ist der Text
für einen Verweis, I<der die Abbildung referenziert>.

=cut

# -----------------------------------------------------------------------------

sub linkText {
    my ($self,$gen) = @_;
    return $self->expandText($gen,'captionS');
}

# -----------------------------------------------------------------------------

=head3 latexLinkCode() - LaTeX-Code für einen Verweis

=head4 Synopsis

    $latex = $gph->latexLinkCode($l);

=head4 Returns

LaTeX-Code

=head4 Description

Liefere den LaTeX-Code, wenn die Abbildung mit einem Verweis
hinterlegt ist (Attribut C<link> ist gesetzt). An der Stelle,
wo der LaTeX-Code für die Abbildung eingesetzt wird,
enthält der Code das Formatelement %s.

=head4 Examples

LaTeX-Code für einen internen Verweis:

    \hyperref[LINKID]{%s}

LaTeX-Code für einen externen Verweis:

    \href[URL]{%s}

=cut

# -----------------------------------------------------------------------------

sub latexLinkCode {
    my ($self,$l) = @_;

    my $code;
    my $n = $self->linkN;
    if (defined $n) {
        my $h = $self->linkA->[$n]->[1];
        my $type = $h->type;
        if ($type eq 'external') {
            $code = $l->ci('\href{%s}{%%s}',$l->protect($h->destText));
        }
        elsif ($type eq 'internal') {
            $code = $l->ci('\hyperref[%s]{%%s}',$h->destNode->linkId);
        }
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 generateHtml() - Generiere HTML-Code

=head4 Synopsis

    $code = $gph->generateHtml($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateHtml {
    my ($self,$h) = @_;

    my $root = $self->root;

    if (!defined($self->show) && $self->useCount > 0) {
        return '';
    }

    # HTML-Code erzeugen

    # FIXME: analog zu latexLinkCode() in Methode auslagern

    my ($href,$linkText);
    my $n = $self->linkN;
    if (defined $n) {
        my $h = $self->linkA->[$n]->[1];
        my $type = $h->type;
        if ($type eq 'external') {
            $href = $h->destText;
            $linkText = $h->text;
        }
        elsif ($type eq 'internal') {
            $href = sprintf '#'.$h->destNode->linkId;
            $linkText = $h->text;
        }
    }

    return $h->tag('div',
        style => substr($self->align,0,1) eq 'c'? 'text-align: center': undef,
        $h->tag('a',
            -ignoreTagIf => !$href,
            href => $href,
            $h->tag('img',
                -nl=>0,
                class => 'sdoc-graphic',
                src => $root->expandPath($self->file),
                alt => $self->name || $linkText,
                width => $self->width,
                height => $self->height,
            ),
        ),
    );
}

# -----------------------------------------------------------------------------

=head3 generateLatex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $gph->generateLatex($gen);

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

    my $root = $self->root;

    if (!defined($self->show) && $self->useCount > 0) {
        return '';
    }

    # LaTeX-Code erzeugen

    return Sdoc::Core::LaTeX::Figure->latex($l,
        align => substr($self->align,0,1),
        border => $self->border,
        borderMargin => $self->borderMargin,
        caption => $self->expandText($l,'captionS'),
        file => $root->expandPath($self->file),
        height => $self->height,
        indent => $self->indentation // 1? $root->indentation.'em': undef,
        label => $self->referenced? $self->linkId: undef,
        link => $self->latexLinkCode($l),
        options => $self->latexOptions,
        postVSpace => $l->modifyLength($root->latexParSkip,'*-2'),
        scale => $self->scale,
        width => $self->width,
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
