package Sdoc::Core::LaTeX::Document;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.124;

use Sdoc::Core::Reference;
use POSIX ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::LaTeX::Document - Erzeuge LaTeX Dokument

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 SYNOPSIS

Der Code

    use Sdoc::Core::LaTeX::Document;
    use Sdoc::Core::LaTeX::Code;
    
    my $doc = Sdoc::Core::LaTeX::Document->new(
        body => 'Hallo Welt',
    );
    
    my $l = Sdoc::Core::LaTeX::Code->new;
    my $code = $tab->latex($l);

produziert

    \documentclass[ngerman,a4paper]{scrartcl}
    \usepackage[T1]{fontenc}
    \usepackage[utf8]{inputenc}
    \usepackage{lmodern}
    \usepackage{babel}
    \usepackage{geometry}
    \setlength{\parindent}{0em}
    \setlength{\parskip}{0.5ex}
    \begin{document}
    Hallo Welt!
    \end{document}

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX Dokument-Objekt

=head4 Synopsis

    $doc = $class->new(@keyVal);

=head4 Arguments

=over 4

=item author => $str

Der Autor des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt.

=item body => $str | \@arr (Default: '')

Der Rumpf des Dokuments.

=item compactCode => $bool (Default: 1)

Erzeuge den LaTeX Code ohne zusätzliche Leerzeilen und Kommentare.

=item date => $str

Das Datum des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt. Formatelemente von strftime werden
expandiert. Spezielle Werte:

=over 4

=item today

Wird ersetzt zu C<\today>.

=item now

Wird expandiert zu C<YYYY-MM-DD HH:MI:SS>.

=back

=item documentClass => $documentClass (Default: 'scrartcl')

Die Dokumentklasse.

=item encoding => $encoding (Default: 'utf8')

Das Input-Encoding.

=item fontSize => $fontSize (Default: undef)

Die Größe des Hauptfont. Mogliche Werte für die Standard LaTeX
Dokumentklassen article etc.: '10pt', '11pt', '12pt'. Die
KOMA-Script Klassen 'scrartcl' etc. erlauben weitere Fontgrößen.

=item geometry => $str

Seitenmaße.

=item language => $language (Default: 'ngerman')

Die Sprache, in der das Dokument verfasst ist.

=item packages => \@arr (Default: [])

Liste der Packages, die zusätzlich geladen werden sollen.
Die Elemente sind Schlüssel/Wert-Paare der Art:

    $package => \@options

=item paperSize => $paperSize (Default: 'a4paper')

Die Größe des Papiers, die die das Dokument gesetzt wird.

=item parIndent => $length (Default: undef)

Tiefe der Absatzeinrückung.

=item parSkip => $length (Default: undef)

Vertikaler Abstand zwischen Absätzen.

=item preamble => $str | \@arr (Default: '')

Dokumentvorspann mit Definitionen.

=item preComment => $str

Kommentar am Dokumentanfang. Wir mit einer Leerzeile vom folgenden
Code abgesetzt.

=item secNumDepth => $n

Tiefe, bis zu der Abschnitte numeriert werden. Default seitens
LaTeX: 3. -2 schaltet die Numerierung ab.

=item title => $str

Der Titel des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt.

=item tocDepth => $n

Tiefe, bis zu der Abschnitte in das Inhaltsverzeichnis aufgenommen
werden. Default seitens LaTeX: 3.

=back

=head4 Returns

Dokument-Objekt

=head4 Description

Instantiiere ein LaTeX Dokument-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyval

    my $self = $class->SUPER::new(
        author => undef,
        body => '', # kann Skalar oder Array-Referenz sein
        compactCode => 1,
        date => undef,
        documentClass => 'scrartcl',
        encoding => 'utf8',
        fontSize => undef,
        geometry => undef,
        language => 'ngerman',
        packages => [],
        paperSize => 'a4paper',
        parIndent => '0em',
        parSkip => '0.5ex',
        preamble => '', # kann Skalar oder Array-Referenz sein
        preComment => undef,
        secNumDepth => undef,
        title => undef,
        tocDepth => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $doc->latex($l);
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

    my ($author,$body,$compactCode,$date,$documentClass,$encoding,$fontSize,
        $geometry,$language,$packageA,$paperSize,$parIndent,$parSkip,
        $preamble,$preComment,$secNumDepth,$title,$tocDepth) =
        $self->get(qw/author body compactCode date documentClass encoding
        fontSize geometry language packages paperSize parIndent parSkip
        preamble preComment secNumDepth title tocDepth/);

    my @pnl = $compactCode? (): (-pnl=>1);

    my $code;

    # Anfangskommentar

    if ($preComment) {
        $code .= $l->comment($preComment,-nl=>2);
    }

    # \documentclass

    my @opt;
    if ($language) {
        push @opt,$language;
    }
    if ($paperSize) {
        push @opt,$paperSize;
    }
    if ($fontSize) {
        push @opt,$fontSize;
    }
    $code .= $l->macro('\documentclass',
        -o => \@opt,
        -p => $documentClass,
    );

    # Packages

    # Font encoding
    $code .= $l->c('\usepackage[T1]{fontenc}',@pnl);
    $code .= $l->c('\usepackage{lmodern}',@pnl);

    # Input encoding

    if ($encoding) {
        $code .= $l->c('\usepackage[%s]{inputenc}',$encoding,@pnl);
    }

    # Dokumentsprache

    if ($language) {
        $code .= $l->c('\usepackage{babel}',@pnl);
    }

    # Papiergröße

    if ($paperSize || $geometry) {
        $code .= $l->c('\usepackage{geometry}',@pnl);
        if ($geometry) {
            $code .= $l->c('\geometry{%s}',$geometry);
        }
    }

    # Pakete

    for (my $i = 0; $i < @$packageA; $i += 2) {
        my $name = $packageA->[$i];
        my $opts = $packageA->[$i+1];

        if (!ref $opts) {
            if (!$opts) {
                # false -> Package übergehen
                next;
            }
            # Keine Optionen
            $opts = undef;
        }

        $code .= $l->macro('\usepackage',
            -o => $opts, # String oder Array-Referenz oder undef
            -p => $name,
            @pnl,
        );
    }

    # Dokument-Vorspann

    if (Sdoc::Core::Reference->isArrayRef($preamble)) {
        $preamble = join '',@$preamble;
    }
    $code .= $preamble;

    # Abschnittskonfiguration

    if (defined $secNumDepth) {
        $code .= $l->c('\setcounter{secnumdepth}{%s}',$secNumDepth);
    }
    if (defined $tocDepth) {
        $code .= $l->c('\setcounter{tocdepth}{%s}',$tocDepth);
    }

    # Paragraph-Eigenschaften

    if ($parIndent) {
        $code .= $l->c('\setlength{\parindent}{%s}',$parIndent,@pnl);
    }
    if ($parSkip) {
        $code .= $l->c('\setlength{\parskip}{%s}',$parSkip);
    }

    # Dokument-Rumpf

    if (Sdoc::Core::Reference->isArrayRef($body)) {
        $body = join '',@$body;
    }

    # Titelseite (an den Anfrang des Rumpfes)

    if ($title || $author || $date) {
        if ($date) {
            # Spezielle Datumswerte:
            # * today
            # * now
            # * strftime-Formate werden expandiert

            if ($date eq 'today') {
                $date = '\today';
            }
            elsif ($date eq 'now') {
                $date = '%Y-%m-%d %H:%M:%S';
            }
            $date = POSIX::strftime($date,localtime);
        }
        my $tmp .= $l->c('\title{%s}',$title);
        $tmp .= $l->c('\author{%s}',$author);
        $tmp .= $l->c('\date{%s}',$date);
        $tmp .= $l->c('\maketitle');
        # Keine Zeilennummer auf Titelseite
        $tmp .= $l->c('\thispagestyle{empty}');
        $body = $tmp.$body;
    }

    # Umgebung
    $code .= $l->env('document',$body,@pnl);

    # Abschließender EOF-Kommentar

    if (!$compactCode) {
        $code .= $l->comment('eof',-pnl=>1);
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