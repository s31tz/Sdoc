package Sdoc::Node::PostProcessor;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::PostProcessor - PostProcessor-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Postprocessor.
Der Postprocessor definiert Perl-Code, der nach der Erzeugung
des Dokumentcodes im Zielformat auf dieses angewendet wird.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
PostProcessor-Knoten folgende zusätzliche Attribute:

=over 4

=item code => $code

Perl-Code im Postprocessor-Block.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'ppr';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Postprocessor-Knoten

=head4 Synopsis

  $ppr = $class->new($par,$variant,$root,$parent);

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

Seitenumbruch-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %PostProcessor:
        #   KEY=VAL
        # CODE
        # .
        $attribH = $par->readBlock('code');
    }
    elsif ($markup eq 'sdoc') {
        # kommt nicht vor 
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('PostProcessor',$variant,$root,$parent,
        code => '',
    );
    $self->setAttributes(%$attribH);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Ausführung

=head3 execute() - Postprozessiere generiertes Dokument

=head4 Synopsis

  $code = $ppr->execute($format,$code);

=head4 Arguments

=over 4

=item $format

Das Format des generierten Dokument-Codes.

=item $code

Der Code des generierten Dokuments.

=back

=head4 Returns

Dokument-Code (String)

=head4 Description

Wende den PostProcessor-Code auf den Dokument-Code $code im Format
$format an und liefere den resultierenden Dokumentcode zurück.

=cut

# -----------------------------------------------------------------------------

sub execute {
    my ($self,$format,$code) = @_;

    @_ = ($self->root,$format,$code);
    $code = eval "no warnings 'all'; ".$self->code.'; $code;';
    if ($@) {
        $self->throw(
            'SDOC-00001: Execution of PostProcessor code failed',
            Error => $@,
            Code => $self->code,
            Input => $self->input,
            Line => $self->lineNum,
            -stacktrace => 0,
        );
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $ppr->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein PostProcessor-Knoten hat keine Darstellung, daher liefert die Methode
konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub htmlCode {
    my ($self,$h) = @_;
    return '';
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $ppr->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

Leerstring ('')

=head4 Description

Ein PostProcessor-Knoten hat keine Darstellung, daher liefert die Methode
konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub latexCode {
    my ($self,$l) = @_;
    return '';
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $ppr->mediawikiCode($gen);

=head4 Returns

Leerstring ('')

=head4 Description

Ein PostProcessor-Knoten hat keine Darstellung, daher liefert die Methode
konstant einen Leersting.

=cut

# -----------------------------------------------------------------------------

sub mediawikiCode {
    my ($self,$m) = @_;
    return '';
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
