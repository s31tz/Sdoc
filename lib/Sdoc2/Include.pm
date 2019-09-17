package Sdoc2::Include;
use base qw/Sdoc2::Node/;

use v5.10.0;
use strict;
use warnings;

our $VERSION = '1';

use Sdoc::Core::Ipc;
use Sdoc::Core::LineProcessor;
use Sdoc::Core::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc2::Include - Einbinden von externen Inhalten

=head1 BASE CLASS

L<Sdoc2::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine extrene Quelle,
die einen Teil des Dokuments liefert.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf übergeordneten Knoten.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $node = $class->new($doc,$parent);

=head4 Description

Lies Include-Spezifikation aus Textdokument $doc und liefere
eine Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    my $self = $class->SUPER::new(
        parent=>undef,
        type=>'Include',
        file=>undef,
        exec=>undef,
        formatInclude=>0,
    );
    $self->parent($parent);
    # $self->lockKeys;
    $self->set(@$att);

    # Inhalt aus Datei oder Kommando inkludieren. Wenn der Datei-
    # oder das Kommando den String "%FORMAT% enthalten,
    # die Inklusion erst bei dump() durchführen. 

    my $inp = $self->get('file') || '';
    my $execCmd = $self->get('exec') || '';
    if ($inp =~ /%FORMAT%/ || $execCmd =~ /%FORMAT%/) {
        $self->set(formatInclude=>1);
    }
    else {
        if ($execCmd) {
            my ($text) = Sdoc::Core::Ipc->filter($execCmd);
            $inp = \$text;
        }
        my $incDoc = Sdoc::Core::LineProcessor->new($inp,
            -lineClass=>'Sdoc2::Line',
            -lineContinuation=>'backslash',
            -skip=>qr/^#/,
        );
        unshift @{$doc->lines},@{$incDoc->lines};
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Methods

=head3 dump() - Includiere Quelle

=head4 Synopsis

  $str = $node->dump($format);

=head4 Description

Erzeuge eine externe Repräsentation des Code-Abschnitts
und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub dump {
    my $self = shift;
    my $format = shift;
    # @_: @args

    unless ($self->get('formatInclude')) {
        return '';
    }

    my ($file,$exec) = $self->get(qw/file exec/);

    if ($format eq 'debug') {
        my $attr;
        if ($file) {
            $attr = qq|file="$file"|;
        }
        else {
            $attr = qq|exec="$exec"|;
        }
        return "INCLUDE $attr\n";
    }

    $format = 'html' if $format eq 'ehtml';
    my $str = '';
    if ($file) {
        $file =~ s/%FORMAT%/$format/;
        $str = Sdoc::Core::Path->read($file);
    }
    elsif ($exec) {
        $exec =~ s/%FORMAT%/$format/;
        ($str) = Sdoc::Core::Ipc->filter($exec);
    }

    if ($format eq 'pod') {
        $str =~ s/\n+$/\n\n/;
    }
    elsif ($format eq 'man') {
        $self->notImplemented;
    }

    return $str;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
