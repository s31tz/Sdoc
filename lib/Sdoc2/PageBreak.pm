# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc2::PageBreak - Seitenumbruch

=head1 BASE CLASS

L<Sdoc2::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Seitenumbruch
im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten.

=back

=cut

# -----------------------------------------------------------------------------

package Sdoc2::PageBreak;
use base qw/Sdoc2::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $node = $class->new($doc,$parent);

=head4 Description

Lies Seitenumbruch-Zeile aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    # Ein Seitenumbruch besteht aus einer Zeile mit mindestens
    # drei Tilden am Zeilenanfang. Wir entfernen diese Zeile.

    $doc->shiftLine;

    # Objekt instantiieren (Child-Objekte gibt es nicht)

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'PageBreak',
    );
    $self->parent($parent);
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Erzeuge externe Repräsentation für Zitatabschnitt

=head4 Synopsis

  $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation für den Seitenumbruch
und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    if ($format eq 'debug') {
        return "PAGEBREAK\n";
    }
    elsif ($format =~ /^e?html$/) {
        my $h = shift;

        return $h->tag('span',
            -nl=>1,
            style=>'page-break-before:always;',
            undef, # kein Content
        );
    }
    elsif ($format eq 'pod') {
        return '';
    }
    elsif ($format eq 'man') {
        $self->notImplemented;
    }

    $self->throw(
        'SDOC-00001: Unbekanntes Format',
        Format=>$format,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2021 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
