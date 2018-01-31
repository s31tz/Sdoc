package Sdoc::Core::LaTeX::Generator;
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

Sdoc::Core::LaTeX::Generator - LaTeX-Generator

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen LaTeX-Generator. Mit den
Methoden der Klasse kann aus einem Perl-Programm heraus LaTeX-Code
erzeugt werden.

=head2 LaTeX Pakete

=head3 babel - Sprachspezifische Einstellungen vornehmen

    \usepackage[ngerman]{babel}

=over 2

=item *

L<https://ctan.org/pkg/babel>

=item *

L<https://www.namsu.de/Extra/pakete/Babel_V2017.html>

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX-Generator

=head4 Synopsis

    $l = $class->new;

=head4 Description

Instantiiere einen LaTeX-Generator und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return $class->SUPER::new;
}

# -----------------------------------------------------------------------------

=head2 Elementare Konstruktion

=head3 cn() - Erzeuge LaTeX Codezeile

=head4 Synopsis

    $code = $l->cn($fmt,@args,@opts);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Beende den Code mit $n Zeilenumbrüchen.

=back

=head4 Description

Erzeuge eine LaTeX Codezeile und liefere das Resultat zurück.

=head4 Example

B<Makro mit Option und Parameter>

    $l->cn('\documentclass[%s]{%s}','12pt','article');

produziert

    \documentclass[12pt]{article}\n

=cut

# -----------------------------------------------------------------------------

sub cn {
    my $self = shift;
    my $fmt = shift;
    # @_: @args,@opts

    # Optionen

    my $nl = 1;

    Sdoc::Core::Option->extract(\@_,
        -nl => \$nl,
    );

    # Codezeile erstellen

    my $cmd = sprintf $fmt,@_;
    $cmd .= ("\n" x $nl);

    return $cmd;
}

# -----------------------------------------------------------------------------

=head3 cx() - Erzeuge LaTeX Code ohne NL

=head4 Synopsis

    $code = $l->cx($fmt,@args,@opts);

=head4 Options

=over 4

=item -nl => $n (Default: 0)

Beende den Code mit $n Zeilenumbrüchen.

=back

=head4 Description

Erzeuge eine LaTeX Codezeile ohne Newline am Ende und liefere das
Resultat zurück.

=head4 Example

B<Makro mit Option und Parameter>

    $l->cx('\thead[%sb]{%s}','c','Ein Text');

produziert

    \thead[cb]{Ein Text}

=cut

# -----------------------------------------------------------------------------

sub cx {
    my $self = shift;
    my $fmt = shift;
    # @_: @args,@opts
    return $self->cn($fmt,-nl=>0,@_);
}

# -----------------------------------------------------------------------------

=head3 cmd() - Erzeuge LaTeX-Kommando

=head4 Synopsis

    $code = $l->cmd($name,@args);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Füge $n Zeilenumbrüche am Ende hinzu.

=item -o => $options

=item -o => \@options

Füge eine Optionsliste [...] hinzu.

=item -p => $parameters

=item -p => \@parameters

Füge eine Parameterliste {...} hinzu.

=item -preNl => $n (Default: 0)

Setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge ein LaTeX-Kommando und liefere den resultierenden Code
zurück.

=head4 Examples

B<Kommando ohne Parameter oder Optionen>

    $l->cmd('LaTeX');

produziert

    \LaTeX

B<Kommando mit leerer Parameterliste>

    $l->cmd('LaTeX',-p=>'');

produziert

    \LaTeX{}

B<Kommando mit Parameter>

    $l->cmd('documentclass',
        -p => 'article',
    );

produziert

    \documentclass{article}

B<Kommando mit Parameter und Option>

    $l->cmd('documentclass',
        -o => '12pt',
        -p => 'article',
    );

produziert

    \documentclass[12pt]{article}

B<Kommando mit Parameter und mehreren Optionen (Variante 1)>

    $l->cmd('documentclass',
        -o => 'a4wide,12pt',
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

B<Kommando mit Parameter und mehreren Optionen (Variante 2)>

    $l->cmd('documentclass',
        -o => ['a4wide','12pt'],
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

=cut

# -----------------------------------------------------------------------------

sub cmd {
    my $self = shift;
    my $name = shift;
    # @_: @args

    my $nl = 1;
    my $preNl = 0;

    my $cmd = "\\$name";
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

=head3 comment() - Erzeuge LaTeX-Kommentar

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

Erzeuge einen LaTex-Kommentar und liefere den resultierenden
Code zurück.

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

=head3 protect() - Schütze LaTeX Metazeichen

=head4 Synopsis

    $code = $l->protect($text);

=head4 Description

Schütze LaTeX-Metazeichen in $text und liefere den resultierenden
Code zurück.

Liste/Erläuterung der LaTeX-Metazeichen:
L<https://www.namsu.de/Extra/strukturen/Sonderzeichen.html>

=head4 Examples

B<Dollarzeichen>

    $l->protect('Der Text $text wird geschützt.');

produziert

    Der Text \$text wird geschützt.

=cut

# -----------------------------------------------------------------------------

sub protect {
    my ($self,$text) = @_;

    # Vorhandene Backslashes kennzeichnen und zum Schluss ersetzen.
    # Dies ist wg. der eventuellen Ersetzung in \textbackslash{}
    # nötig, wobei dann geschweifte Klammern entstehen würden.
    $text =~ s/\\/\\\x1d/g;

    # Reservierte und Sonderzeichen wandeln
    $text =~ s/([\$_%{}#&])/\\$1/g;         # $ _ % { } # &
    $text =~ s/>/\\textgreater{}/g;         # >
    $text =~ s/</\\textless{}/g;            # <
    $text =~ s/~/\\textasciitilde{}/g;      # ~
    $text =~ s/\^/\\textasciicircum{}/g;    # <
    $text =~ s/\|/\\textbar{}/g;            # |
    $text =~ s/LaTeX/\\LaTeX{}/g;           # LaTeX
    $text =~ s/(?<!La)TeX/\\TeX{}/g;        # TeX

    # Gekennzeichnete Backslashes zum Schluss wandeln
    $text =~ s/\\\x1d/\\textbackslash{}/g; # \

    return $text;
}

# -----------------------------------------------------------------------------

=head2 LaTeX-Kommandos

=head3 renewcommand() - Redefiniere LaTeX-Kommando

=head4 Synopsis

    $code = $l->renewcommand($name,@args);

=head4 Options

Siehe Methode $l->cmd().

=head4 Description

Redefiniere LaTeX-Kommando $name und liefere den resultierenden
LaTeX-Code zurück.

=head4 Examples

    $l->renewcommand('cellalign',-p=>'lt');

produziert

    \renewcommand{\cellalign}{lt}

=cut

# -----------------------------------------------------------------------------

sub renewcommand {
    my $self = shift;
    my $name = shift;
    # @_: @args

    return $self->cmd('renewcommand',-p=>"\\$name",@_);
}

# -----------------------------------------------------------------------------

=head3 setlength() - Erzeuge TeX-Längenangabe

=head4 Synopsis

    $code = $l->setlength($name,$length,@args);

=head4 Options

Siehe Methode $l->cmd().

=head4 Description

Erzeuge eine TeX-Längenangabe und liefere den resultierenden
Code zurück.

=head4 Examples

B<Paragraph-Einrückung entfernen>

    $l->setlength('parindent','0em');

produziert

    \setlength{\parindent}{0em}

=cut

# -----------------------------------------------------------------------------

sub setlength {
    my $self = shift;
    my $name = shift;
    my $length = shift;
    # @_: @args

    return $self->cmd('setlength',-p=>"\\$name",-p=>$length,@_);
}

# -----------------------------------------------------------------------------

=head2 Höhere Konstruktionen

=head3 env() - Erzeuge LaTeX-Umgebung

=head4 Synopsis

    $code = $l->env($name,$body,@args);

=head4 Options

Siehe Methode $l->cmd(). Weitere Optionen:

=over 4

=item -indent => $n (Default: 2)

Rücke den Inhalt der Umgebung für eine bessere
Quelltext-Lesbarkeit um $n Leerzeichen ein. Achtung: In einer
Verbatim-Umgebung hat dies Auswirkungen auf die Darstellung
und sollte dort mit C<< -indent => 0 >> abgeschaltet werden.

=back

=head4 Description

Erzeuge eine LaTeX-Umgebung und liefere den resultierenden Code
zurück.

=head4 Examples

B<Document-Umgebung mit Text>

    $l->env('document','Dies ist ein Text.');

produziert

    \begin{document}
      Dies ist ein Text.
    \end{document}

=cut

# -----------------------------------------------------------------------------

sub env {
    my $self = shift;
    my $name = shift;
    my $body = shift;
    # @_: @args

    # Optionen, die hier sonderbehandelt werden

    my $indent = 0;
    my $nl = 1;
    my $preNl = 0;

    Sdoc::Core::Option->extract(-mode=>'sloppy',\@_,
        -nl => \$nl,
        -preNl => \$preNl,
        -indent => \$indent,
    );

    # Umgebung erzeugen

    if (!defined $body) {
        $body = '';
    }
    if ($body ne '' && substr($body,-1) ne "\n") {
        $body .= "\n";
    }
    if ($indent) {
        $indent = ' ' x $indent;
        $body =~ s/^/$indent/gm;
    }
    
    my $code = $self->cmd('begin',-p=>$name,-preNl=>$preNl,@_);
    $code .= $body;
    $code .= $self->cmd('end',-p=>$name,-nl=>$nl);

    return $code;
}

# -----------------------------------------------------------------------------

=head3 section() - Erzeuge LaTeX Section

=head4 Synopsis

    $code = $l->section($sectionName,$title);

=head4 Arguments

=over 4

=item $sectionName

Name des LaTeX-Abschnitts. Mögliche Werte: 'part', 'chapter', 'section',
'subsection', 'susubsection', 'paragraph', 'subparagraph'.

=back

=head4 Options

=over 4

=item -label => $label

Kennzeichne Abschnitt mit Label $label.

=item -toc => $bool (Default: 1)

Nimm die Überschrift nicht ins Inhaltsverzeichnis auf.

=back

=head4 Description

Erzeuge ein LaTeX Section und liefere den resultierenden Code
zurück.

=head4 Examples

B<Ein Abschnitt der Ebene 1>

    $l->section('subsection','Ein Abschnitt');

produziert

    \subsection{Ein Abschnitt}

=cut

# -----------------------------------------------------------------------------

sub section {
    my $self = shift;
    my $sectionName = shift;
    my $title = shift;

    # Optionen

    my $toc = 1;
    my $label = undef;

    Sdoc::Core::Option->extract(\@_,
        -label => \$label,
        -toc => \$toc,
    );

    if (!$toc) {
        $sectionName .= '*';
    }

    my $code = $self->cmd($sectionName,-p=>$title);
    if ($label) {
        $code .= $self->cmd('label',-p=>$label);
    }
    $code .= "\n";

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
