# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc2::Format - Format-Abschnitt

=head1 BASE CLASS

L<Sdoc2::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Format-Abschnitt
im Sdoc-Parsingbaum.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf den Elternknoten.

=item content => $content

Der vollständige Inhalt des Format-Blocks.

=item formatH => \%format

Code der Zielformate. Schlüssel des Hashs ist der Name des jeweiligen
Zielformats (kleingeschrieben).

=back

=cut

# -----------------------------------------------------------------------------

package Sdoc2::Format;
use base qw/Sdoc2::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1';

use Sdoc::Core::FileHandle;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $node = $class->new($doc,$parent);

=head4 Description

Lies Format-Abschnitt aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent) = @_;

    my $text = '';
    while (@{$doc->lines}) {
        my $line = $doc->lines->[0];
        my $str = $line->text;

        if ($str eq '.') {
            $doc->shiftLine;
            last;
        }

        $text .= "$str\n";
        $doc->shiftLine;
    }
    $text =~ s/\s+$//;

    # Objekt instantiieren (Child-Objekte gibt es nicht)

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Quote',
        content=>$text,
        formatH=>{},
    );
    $self->parent($parent);
    # $self->lockKeys;

    # Wir zerlegen den Inhalt des Blocks in seine Bestandteile
    # und weisen diese an den Format-Hash zu.

    my $key;
    my $fh = Sdoc::Core::FileHandle->new('<',\$text);
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

=head2 Methods

=head3 dump() - Liefere Zielformat-Code

=head4 Synopsis

  $str = $node->dump($format);

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    if ($format eq 'debug') {
        return sprintf "FORMAT\n%s\n",$self->content;
    }
    elsif ($format eq 'ehtml') {
        $format = 'html';
    }

    return $self->formatH->{$format};
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
