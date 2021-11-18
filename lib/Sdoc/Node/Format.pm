# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Format - Format-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Bereich innerhalb des
Dokuments, der direkt in dem oder den Zielformaten formatiert
ist und bei Erzeugung des Zielformats direkt eingebunden wird.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Format-Knoten folgende zusätzliche Attribute:

=over 4

=item content => $content

Der vollständige Inhalt des Format-Blocks.

=item formatH => \%format

Code der Zielformate. Schlüssel des Hashs ist der Name des jeweiligen
Zielformats (kleingeschrieben).

=back

=cut

# -----------------------------------------------------------------------------

package Sdoc::Node::Format;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Core::FileHandle;

# -----------------------------------------------------------------------------

our $Abbrev = 'fmt';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Format-Knoten

=head4 Synopsis

  $fmt = $class->new($par,$variant,$root,$parent);

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

Format-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Format:
        # @FORMAT1@
        # CODE1
        # @FORMAT2@
        # CODE2
        # ...
        # .
        $attribH = $par->readBlock('content',undef,1);
    }
    elsif ($markup eq 'sdoc') {
        # kommt nicht vor
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Format',$variant,$root,$parent,
        content => undef,
        formatH => {},
    );
    $self->setAttributes(%$attribH);

    # Wir zerlegen den Inhalt des Blocks in seine Bestandteile
    # und weisen diese an den Format-Hash zu.

    my $key;
    my $fh = Sdoc::Core::FileHandle->new('<',\$self->content);
    while (<$fh>) {
        if (/^\@\@(.*)\@\@$/) {
            $key = lc $1;
            $self->{'formatH'}->{$key} = '';
            next;
        }
        $self->{'formatH'}->{$key} .= $_;
    }
    $fh->close;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $par->htmlCode($gen);

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

    if (!exists $self->{'formatH'}->{'html'}) {
        $self->throw(
            'SDOC-00099: No content defined for format HTML',
            File => $self->input,
            Line => $self->lineNum,
            -stacktrace => 0,
        );
    }

    return $self->{'formatH'}->{'html'};
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $par->latexCode($gen);

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

    if (!exists $self->{'formatH'}->{'latex'}) {
        $self->throw(
            'SDOC-00099: No content defined for format LaTeX',
            File => $self->input,
            Line => $self->lineNum,
            -stacktrace => 0,
        );
    }

    return $self->{'formatH'}->{'latex'};
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $par->mediawikiCode($gen);

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

    if (!exists $self->{'formatH'}->{'mediawiki'}) {
        $self->throw(
            'SDOC-00099: No content defined for format MediaWiki',
            File => $self->input,
            Line => $self->lineNum,
            -stacktrace => 0,
        );
    }

    return $self->{'formatH'}->{'mediawiki'};
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
