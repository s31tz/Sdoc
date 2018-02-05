package Sdoc::Node::Item;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

use Sdoc::Node::List;
use Sdoc::LineProcessor;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Item - Listenelement-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Listenelement.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Listenelement-Knoten folgende zusätzliche Attribute:

=over 4

=item childA => \@childs

Liste der Subknoten.

=item formulaA => \@formulas

Array mit den im Key vorkommenden Formeln aus
M-Segmenten.

=item key => $key

Schlüssel im Falle einer Definitionsliste.

=item keyS => $keyS

Schlüssel mit geparsten Segmenten.

=item linkA => \@links

Array mit Informationen über die im Key vorkommenden Links.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Listenelement-Knoten

=head4 Synopsis

    $itm = $class->new($par,$variant,$root,$parent);

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

Listenelement-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Falls der Parent kein List-Knoten ist, erzeugen wir ihn.
    # Der Listentyp wird vom erstn (diesem) Item gesetzt.

    if ($parent->type ne 'List') {
        my $lineA = $par->lines;
        # Wir geben der Liste die Eingabe/Zeilennummer des Item
        my $lineNum = $lineA->[0]->number;
        my $inputR = $lineA->[0]->inputR;
        unshift @$lineA,$par->lineClass->new('%List:',$lineNum,$inputR);
        return Sdoc::Node::List->new(0,$par,$root,$parent);
    }

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my ($attribH,$firstLine);
    if ($variant == 0) {
        # %Item:
        #   KEY=VAL
        $attribH = $par->readBlock;
    }
    elsif ($markup eq 'sdoc') {
        # [...]:
        # *, o, +
        # N.

        my $line = $par->shiftLine;

        my ($listType,$key,$text);
        if ($variant == 1) {
            $listType = 'description';
            $line->text =~ /^\[(.*?)\]:(.*)/;
            $key = $1;
            $text = $2;
        }
        elsif ($variant == 2) {
            $listType = 'unordered';
            $line->text =~ /^([*o+]) (.*)/;
            $key = $1;
            $text = $2;
        }
        elsif ($variant == 3) {
            $listType = 'ordered';
            $line->text =~ /^(\d+)\. (.*)/;
            $key = $1;
            $text = $2;
        }
        if (!defined $parent->listType) {
            $parent->listType($listType);
        }

        # Falls auf der Zeile des ersten Item ein Text angegeben ist,
        # fügen wir diesen als erste Zeile des Subdokumentes unten
        # hinzu.

        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
        if ($text ne '') {
            $line->text($text);
            $firstLine = $line;
        }

        $attribH = {
            input => $line->input,
            lineNum => $line->number,
            key => $key,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Item',$variant,$root,$parent,
        childA => [],
        formulaA => [],
        graphicA => [],
        key => undef,
        keyS => undef,
        linkA => [],
    );
    $self->setAttributes(%$attribH);
    $par->parseSegments($self,'key');

    # Eingerücktes Subdokument einlesen

    $par->removeEmptyLines;
    my $lineA = $par->lines;
    my (@lines,$indent);
    while (@$lineA) {
        my $line = $lineA->[0];
        if (!defined $indent) {
            # Die Einrücktiefe des Subdokuments ist die Einrücktiefe
            # der ersten Zeile (diese ist nichtleer, da wir oben
            # Leerzeilen überlesen haben). Sonderfall: Wenn die
            # Einrücktiefe 0 ist, brechen wir unmittelbar ab, da das
            # dann kein Subdokument gibt.

            $indent = $line->indentation;
            if ($indent == 0) {
                last;
            }
        }
        if (!$line->isEmpty) {
            if ($line->indentation < $indent) {
                # Wir haben das Ende des Subdokuments erreicht, wenn
                # die Einrücktiefe sich verringert.
                last;
            }

            # Wir entfernen die Einrückung von der eingerückten Zeile
            $line->unindent($indent);
        }
        push @lines,$par->shiftLine;
    }
    if ($firstLine) {
        unshift @lines,$firstLine;
    }

    # Child-Objekte aus dem Subdokument verarbeiten

    $par = Sdoc::LineProcessor->new(\@lines,
        -encoding => 'utf-8',
        -lineContinuation => 'backslash',
    );

    $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant) = $par->nextType(1);
        $self->push(childA=>$nodeClass->new($variant,$par,$root,$self));
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $itm->latex($gen);

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

    my $code;
    
    my $listType = $self->parent->listType;
    if ($listType eq 'description') {
        # [{}] weil sonst Probleme bei Macros mit Optionen (\includegraphics)
        $code .= $l->c('\item[{%s}]',$self->latexText($l,'keyS'));
    }
    else {
        $code .= $l->c('\item');
    }

    $code .= $self->generateChilds('latex',$l);
    
    return $code;
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
