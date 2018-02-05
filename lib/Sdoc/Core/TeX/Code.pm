package Sdoc::Core::TeX::Code;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.124;

use Sdoc::Core::Option;
use Scalar::Util ();
use Sdoc::Core::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::TeX::Code - Generator für TeX Code

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen TeX Code-Generator. Mit
den Methoden der Klasse kann aus einem Perl-Programm heraus
TeX-Code erzeugt werden.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere TeX Code-Generator

=head4 Synopsis

    $t = $class->new;

=head4 Description

Instantiiere einen TeX Code-Generator und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    return shift->SUPER::new;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 c() - Erzeuge TeX Codezeile

=head4 Synopsis

    $code = $t->c($fmt,@args,@opts);

=head4 Arguments

=over 4

=item $fmt

Codezeile mit sprintf Formatelementen.

=item @args

Argumente, die in den Formatstring eingesetzt werden. Kommt unter
den Argumenten eine Arrayreferenz vor, wird diese zu einem
kommaseparierten String expandiert.

=back

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Beende den Code mit $n Zeilenumbrüchen.

=back

=head4 Returns

TeX Code (String)

=head4 Description

Erzeuge eine TeX Codezeile und liefere das Resultat zurück.

=head4 Example

B<Makro mit Option und Parameter>

    $documentClass = 'article';
    $fontSize = '12pt';
    ...
    $t->c('\documentclass[%s]{%s}',$fontSize,$documentClass);

produziert

    \documentclass[12pt]{article}\n

B<Expansion von Array-Parameter>

    my @opt;
    push @opt,'labelsep=colon';
    push @opt,'labelfont=bf';
    push @opt,'skip=1.5ex';
    $t->c('\usepackage[%s]{caption}',\@opt);

produziert

    \usepackage[labelsep=colon,labelfont=bf,skip=1.5ex]{caption}

=cut

# -----------------------------------------------------------------------------

sub c {
    my $self = shift;
    my $fmt = shift;
    # @_: @args,@opts

    if (!defined $fmt) {
        warn "WARNING: Format undefined: @_\n";
    }

    # Optionen

    my $nl = 1;

    Sdoc::Core::Option->extract(\@_,
        -nl => \$nl,
    );

    # Arrayreferenz zu kommasepariertem String expandieren

    for (@_) {
        if (!defined) {
            warn "WARNING: Macro with undefined argument: @_\n";
        }

        my $type = Scalar::Util::reftype($_);
        if (defined($type) && $type eq 'ARRAY') {
            $_ = join ',',@$_;
        }
    }

    # Codezeile erzeugen

    if ($fmt =~ tr/%// > @_) {
        warn "WARNING: Missing argument: $fmt | @_\n";
    }

    my $cmd = sprintf $fmt,@_;
    $cmd .= ("\n" x $nl);

    return $cmd;
}

# -----------------------------------------------------------------------------

=head3 ci() - Erzeuge TeX Code inline

=head4 Synopsis

    $code = $t->ci($fmt,@args,@opts);

=head4 Arguments

=over 4

=item $fmt

Codezeile mit sprintf Formatelementen.

=item @args

Argumente, die in den Formatstring eingesetzt werden. Kommt unter
den Argumenten eine Arrayreferenz vor, wird diese zu einem
kommaseparierten String expandiert.

=back

=head4 Options

=over 4

=item -nl => $n (Default: 0)

Beende den Code mit $n Zeilenumbrüchen.

=back

=head4 Returns

TeX Code (String)

=head4 Description

Erzeuge TeX Code und liefere das Resultat zurück. Die Methode
ist identisch zu Methode $t->c(), nur dass per Default kein
Newline am Ende des Code hinzugefügt wird. Das C<i> im
Methodennamen steht für "inline".

=head4 Example

B<< Vergleich von $t->ci(), sprintf(), $t->c() >>

    $t->ci('\thead[%sb]{%s}','c','Ein Text');

ist identisch zu

    sprintf '\thead[%sb]{%s}','c','Ein Text';

ist identisch zu

    $t->c('\thead[%sb]{%s}','c','Ein Text',-nl=>0);

und produziert

    \thead[cb]{Ein Text}

=cut

# -----------------------------------------------------------------------------

sub ci {
    my $self = shift;
    my $fmt = shift;
    # @_: @args,@opts
    return $self->c($fmt,-nl=>0,@_);
}

# -----------------------------------------------------------------------------

=head3 macro() - Erzeuge ein TeX macro mit Argumenten

=head4 Synopsis

    $code = $t->macro($name,@args);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Füge $n Zeilenumbrüche am Ende hinzu.

=item -o => $options

=item -o => \@options

Füge eine Optionsliste [...] hinzu. Ein Array wird in eine
kommaseparierte Liste von Werten übersetzt.

=item -p => $parameters

=item -p => \@parameters

Füge eine Parameterliste {...} hinzu. Ein Array wird in eine
kommaseparierte Liste von Werten übersetzt.

=item -preNl => $n (Default: 0)

Setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge ein TeX-Kommando und liefere den resultierenden Code
zurück.

=head4 Examples

B<Kommando ohne Parameter oder Optionen>

    $t->macro('\LaTeX');

produziert

    \LaTeX

B<Kommando mit leerer Parameterliste>

    $t->macro('\LaTeX',-p=>'');

produziert

    \LaTeX{}

B<Kommando mit Parameter>

    $t->macro('\documentclass',
        -p => 'article',
    );

produziert

    \documentclass{article}

B<Kommando mit Parameter und Option>

    $t->macro('\documentclass',
        -o => '12pt',
        -p => 'article',
    );

produziert

    \documentclass[12pt]{article}

B<Kommando mit Parameter und mehreren Optionen (Variante 1)>

    $t->macro('\documentclass',
        -o => 'a4wide,12pt',
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

B<Kommando mit Parameter und mehreren Optionen (Variante 2)>

    $t->macro('\documentclass',
        -o => ['a4wide','12pt'],
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

=cut

# -----------------------------------------------------------------------------

sub macro {
    my $self = shift;
    my $name = shift;
    # @_: @args

    my $nl = 1;
    my $preNl = 0;

    if (substr($name,0,1) ne '\\') {
        $self->throw(
            q~TEX-00001: Missing initial backslash~,
            Macro => $name,
        );
    }

    my $cmd = $name;
    while (@_) {
        my $opt = shift;
        my $val = shift;

        # Wandele Array in kommaseparierte Liste von Werten

        if (ref $val) {
            my $refType = Scalar::Util::reftype($val);
            if ($refType eq 'ARRAY') {
                $val = join ',',@$val;
            }
            else {
                $self->throw(
                    q~LATEX-00001: Illegal reference type~,
                    RefType => $refType,
                );
            }
        }

        # Behandele Parameter und Optionen

        if ($opt eq '-p') {
            # Eine Parameter-Angabe wird immer gesetzt, ggf. leer
            $val //= '';
            $cmd .= "{$val}";
        }
        elsif ($opt eq '-preNl') {
            $preNl = $val;
        }
        elsif ($opt eq '-o') {
            # Eine Options-Angabe entfällt, wenn leer
            if (defined $val && $val ne '') {
                $cmd .= "[$val]";
            }
        }
        elsif ($opt eq '-nl') {
            $nl = $val;
        }
        else {
            $self->throw(
                q~LATEX-00001: Unknown Option~,
                Option => $opt,
            );
        }
    }

    # Behandele Zeilenumbruch

    $cmd = ("\n" x $preNl).$cmd;
    $cmd .= ("\n" x $nl);

    return $cmd;
}

# -----------------------------------------------------------------------------

=head3 comment() - Erzeuge TeX-Kommentar

=head4 Synopsis

    $code = $l->comment($text,@opt);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Füge $n Zeilenumbrüche am Ende hinzu.

=item -preNl => $n (Default: 0)

Setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge einen TeX-Kommentar und liefere den resultierenden Code
zurück.

=head4 Examples

B<Kommentar erzeugen>

    $l->comment("Dies ist\nein Kommentar");

produziert

    % Dies ist
    % ein Kommentar

=cut

# -----------------------------------------------------------------------------

sub comment {
    my $self = shift;
    # @_: $text,@opt

    # Optionen

    my $nl = 1;
    my $preNl = 0;

    Sdoc::Core::Option->extract(\@_,
        -nl => \$nl,
        -preNl => \$preNl,
    );

    # Argumente
    my $text = shift;

    # Kommentar erzeugen

    $text = Sdoc::Core::Unindent->trim($text);
    $text =~ s/^/% /mg;
    $text = ("\n" x $preNl).$text;
    $text .= ("\n" x $nl);
    
    return $text;
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
