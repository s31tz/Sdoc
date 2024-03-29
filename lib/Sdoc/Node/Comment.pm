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

=cut

# -----------------------------------------------------------------------------

package Sdoc::Node::Comment;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Core::Unindent;

# -----------------------------------------------------------------------------

our $Abbrev = 'com';

# -----------------------------------------------------------------------------

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

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $com->htmlCode($gen);

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

    my $code = '';
    if ($self->root->copyComments) {
        $code = $h->comment($self->text);
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $com->latexCode($gen);

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

    my $code = '';
    if ($self->root->copyComments) {
        $code = $l->comment($self->text,-nl=>2);
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $com->mediawikiCode($gen);

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

    my $code = '';
    if ($self->root->copyComments) {
        $code = $m->comment($self->text);
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2021 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
