package Sdoc::Node::Graphic;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

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

Anker der Grafik.

=item anchorA => \@anchors (memoize)

Anker-Pfad der Grafik.

=item caption => $text

Beschriftung der Grafik. Diese erscheint unter der Grafik.

=item definition => $bool (Default: I<kontextabhängig>)

Wenn gesetzt, stellt der Grafik-Block lediglich eine Definition dar,
d.h. die Grafik wird nicht an dieser Stelle angezeigt, sondern an
anderer Stelle von einem G-Segment referenziert. Ist Attribut
C<name> definiert, ist der Default 1, andernfalls 0.

=item file => $path

Pfad der Bilddatei. Beginnt der Pfad mit C<+/>, wird das
Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=item latexFloat => $bool (Default: 0)

Setze die Grafik in eine LaTeX C<figure> Umgebung.

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
        caption => undef,
        captionS => undef,
        definition => undef,
        file => undef,
        formulaA => [],
        graphicA => [],
        latexFloat => 0,
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

=head2 Anker

=head3 anchor() - Anker des Abschnitts

=head4 Synopsis

    $anchor = $sec->anchor;

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

    my $code = '';
    if ($self->definition) {
        # Wenn der Grafik-Knoten als Deklaration gekennzeichnet ist
        # (definition=1), generieren wir keinen Code.
        $code = '';
    }
    elsif ($self->latexFloat) {
        $code .= $l->c('\begin{figure}[h]');
        my $align = $self->align;
        if ($align eq 'left') {
            $code .= $l->ci('\hspace*{%sem}',$root->indentation);
        }
        elsif ($align eq 'center') {
            $code .= '\centering';
        }
        $code .= $self->latexIncludeGraphics($l,1);
        if (my $caption = $self->latexText($l,'captionS')) {
            $code .= $l->ci('\captionsetup{skip=1.5ex}');
            $code .= $l->c('\caption{%s}',$caption);
        }
        if (my $linkId = $self->linkId) {
            $code .= $l->c('\label{%s}',$linkId);
        }
        $code .= $l->c('\vspace*{-2ex}');
        $code .= $l->c('\end{figure}');
        $code .= "\n";
    }
    else {
        my $indent = $root->indentation;

        if (my $align = $self->align) {
            $code .= $l->c('\vspace*{-0.5ex}');
            if (my $linkId = $self->linkId) {
                $code .= $l->c('\label{%s}',$linkId);
            }
            if ($align eq 'left') {
                $code .= $l->ci('\hspace*{%sem}',$indent);
            }
            $code .= $self->latexIncludeGraphics($l,1);
            if (my $caption = $self->latexText($l,'captionS')) {
                $code .= $l->c('\vspace*{0.3ex}');
                $code .= $l->c('\captionof{figure}{%s}',$caption);
            }
            $code .= $l->c('\vspace*{-1.3ex}');

            $code = $l->env($align eq 'center'? $align: "flush$align",
                $code,
                -nl=>2,
            );
        }
        else {
            $code = $l->ci('\hspace*{%sem}',$indent).
                $self->latexIncludeGraphics($l,2);
        }
    }
    
    return $code;
}

# -----------------------------------------------------------------------------

=head3 latexIncludeGraphics() - Generiere LaTeX-Code für \includegraphics

=head4 Synopsis

    $code = $gph->latexIncludeGraphics($gen,$n);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=item $n

Anzahl der Zeilenumbrüche am Ende des Konstrukts.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latexIncludeGraphics {
    my ($self,$l,$n) = @_;

    # Optionen. Wir fügen scale=$scale zu den includegraphics-Optionen
    # hinzu, wenn dort noch kein Skalierungsfaktor angegeben ist.

    my @opt = split /,/,$self->latexOptions // '';
    if ((my $scale = $self->scale) && !grep(/scale/,@opt)) {
        push @opt,"scale=$scale";
    }

    return $l->c('\includegraphics[%s]{%s}',
        \@opt,
        $self->root->expandPlus($self->file),
        -nl => $n,
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
