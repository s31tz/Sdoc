package Sdoc::Core::LaTeX::Figure;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.124;

use Sdoc::Core::Reference;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::LaTeX::Figure - Erzeuge LaTeX Figure

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 SYNOPSIS

Der Code

    use Sdoc::Core::LaTeX::Figure;
    use Sdoc::Core::LaTeX::Code;
    
    my $doc = Sdoc::Core::LaTeX::Figure->new(
        FIXME
    );
    
    my $l = Sdoc::Core::LaTeX::Code->new;
    my $code = $tab->latex($l);

produziert

    FIXME

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX Figure-Objekt

=head4 Synopsis

    $doc = $class->new(@keyVal);

=head4 Arguments

=over 4

=item align => 'l' | 'c' (Default: 'c')

Ausrichtung der Abbildung auf der Seite: l=links, c=zentriert.

=item border => $bool (Default: 0)

Zeichne einen Rahmen um die Abbildung.

=item borderMargin => $length (Default: '0mm')

Zeichne den Rahmen (Attribut C<border>) mit dem angegebenen
Abstand um die Abbildung.

=item caption => $text

Beschriftung der Abbldung. Diese erscheint unter der Abbildung.

=item file => $path

Pfad der Bilddatei.

=item indent => $length

Länge, mit der die Abbildung vom linken Rand eingerückt wird,
wenn sie links (Attribut C<align>) gesetzt wird.

=item label => $str

Anker der Abbildung.

=item options => $str | \@arr

Optionen, die an das Makro C<\includegraphics> übergeben werden.

=item position => 'H','h','t','b','p' (Default: 'H')

Positioniergspräferenz für das Gleitobjekt. Details siehe
LaTeX-Package C<float>, das geladen werden muss.

=item postVSpace => $length

Vertikaler Leerraum, der nach der Abbildung hinzugefügt (positiver
Wert) oder abgezogen (negativer Wert) wird.

=item scale => $factor

Skalierungsfaktor.

=back

=head4 Returns

Figure-Objekt

=head4 Description

Instantiiere ein LaTeX Figure-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyval

    my $self = $class->SUPER::new(
        align => 'c',
        border => 0,
        borderMargin => '0mm',
        caption => undef,
        file => undef,
        indent => undef,
        label => undef,
        options => undef, # $str | \@opt
        position => 'H',
        postVSpace => undef,
        scale => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $fig->latex($l);
    $code = $class->latex($l,@keyVal);

=head4 Description

Generiere den LaTeX-Code des Objekts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub latex {
    my $this = shift;
    my $l = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($align,$border,$borderMargin,$caption,$file,$indent,$label,$options,
        $position,$postVSpace,$scale) = $self->get(qw/align border
        borderMargin caption file indent label options position postVSpace
        scale/);

    if (!$file) {
        return '';
    }

    my @opt;
    if (defined $options) {
        if (Sdoc::Core::Reference->isArrayRef($options)) {
            @opt = @$options;
        }
        else {
            @opt = split /,/,$options;
        }
    }
    if ($scale) {
        push @opt,"scale=$scale";
    }

    my $body;
    if ($align eq 'c') {
        $body .= $l->c('\centering');
    }
    elsif ($indent) {
        $body .= $l->ci('\hspace*{%s}',$indent);
    }
    my $tmp = $l->macro('\includegraphics',
        -o => \@opt,
        -p => $file,
        -nl => 0,
    );
    if ($border) {
        $body .= $l->c('{\fboxsep%s\fbox{%s}}',$borderMargin,$tmp);
    }
    else {
        $body .= "$tmp\n";
    }

    if ($caption) {
        my @opt;
        if ($align ne 'c') {
            push @opt,'singlelinecheck=off';
            if ($indent) {
                push @opt,"margin=$indent";
            }
        }
        if (@opt) {
            $body .= $l->c('\captionsetup{%s}',\@opt);
        }
        $body .= $l->c('\caption{%s}',$caption);
    }
    if ($label) {
        $body .= $l->c('\label{%s}',$label);
    }

    my $code = $l->env('figure',$body,
        -o => $position,
    );

    if (my $postVSpace = $self->postVSpace) {
        $code .= $l->c('\vspace{%s}','--',$postVSpace);
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.124

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
