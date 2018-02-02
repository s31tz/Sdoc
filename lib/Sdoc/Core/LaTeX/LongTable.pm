package Sdoc::Core::LaTeX::LongTable;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.124;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::LaTeX::LongTable - Erzeuge LaTeX longtable

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 SYNOPSIS

Der Code

    use Sdoc::Core::LaTeX::LongTable;
    use Sdoc::Core::LaTeX::Generator;
    
    my $tab = Sdoc::Core::LaTeX::LongTable->new(
        alignments => ['l','r','c'],
        caption => 'Ein Test',
        titles => ['Links','Rechts','Zentriert'],
        rows => [
            ['A',1,'AB'],
            ['AB',2,'CD'],
            ['ABC',3,'EF'],
            ['ABCD',4,'GH'],
        ],
    );
    
    my $l = Sdoc::Core::LaTeX::Generator->new;
    my $code = $tab->latex($l);

produziert

    \begin{longtable}{|lrc|}
    \hline
    Links & Rechts & Zentriert \\ \hline
    \endfirsthead
    \multicolumn{3}{r}{\emph{Fortsetzung}} \
    \hline
    Links & Rechts & Zentriert \\ \hline
    \endhead
    \hline
    \multicolumn{3}{r}{\emph{weiter}} \
    \endfoot
    \captionsetup{skip=1ex}
    \caption{Ein Test}
    \endlastfoot
    A & 1 & AB \\ \hline
    AB & 2 & CD \\ \hline
    ABC & 3 & EF \\ \hline
    ABCD & 4 & GH \\ \hline
    \end{longtable}

was im LaTeX-Dokument in etwa so aussieht

    +--------------------------+
    | Links  Rechts  Zentriert |
    +--------------------------+
    | A           1     AB     |
    +--------------------------+
    | AB         12     CD     |
    +--------------------------+
    | ABC       123     EF     |
    +--------------------------+
    | ABCD     1234     GH     |
    +--------------------------+
    
        Tabelle 1: Ein Test

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX LongTable-Objekt

=head4 Synopsis

    $tab = $class->new(@keyVal);

=head4 Arguments

=over 4

=item align => $align

Horizontale Ausrichtung der Tabelle auf der Seite. Mögliche Werte:
'l', 'r', 'c'.

=item alignments => \@alignments (Default: [])

Liste der Kolumnen-Ausrichtungen. Mögliche Werte je Kolumne: 'l',
'r', 'c'.

=item border => $border (Default: 'hHV' oder 'hvHV' bei multiLine)

Linien in und um die Tabelle. Der Wert ist eine Zeichenkette, die
sich aus den Zeichen 't', 'h', 'v', 'H', 'V' zusammensetzt.

=item callbackArguments => \@arr (Default: [])

Liste von zusätzlichen Argumenten, die an die Funktionen
C<rowCallback> und C<titleCallback> übergeben werden.

=item caption => $str

Unterschrift zur Tabelle.

=item label => $str

Label der Tabelle, über welches sie referenziert werden kann.

=item language => 'german'|'english'

Die Sprache des LaTeX-Dokuments.

=item multiLine => $bool (Default: undef)

Wende C<\makecell> auf alle Kolumnen an. Diese Option
muss aktiviert werden, wenn mehrzeilige Zellen mehrzeilig
dargestellt werden sollen, denn dies kann LaTeX nicht. Wird die
Option aktiviert, muss das Package C<makecell> geladen werden.

=item rows => \@rows (Default: [])

Liste der Tabellenzeilen.

=item rowCallback => sub {} (Default: I<siehe unten>)

Subroutine, die für jede Zeile in @rows die Zeileninformation
liefert, die in den LaTeX-Code eingesetzt wird. Default:

    sub {
        my ($self,$l,$row,$n) = @_;
    
        my @row;
        for my $val (@$row) {
            push @row,$l->protect($val);
        }
    
        return @row;
    }

=item titleColor => $rgb

Farbe der Titelzeile.

=item titleWrapper => $code

Zeichenkette, die um jeden Kolumnentitel gelegt wird. Für C<%s>
wird der Titel eingesetzt. Auf diesem Weg kann ein Makro
auf jeden Titel angewendet werden. Z.B. serifenlosen, fetten Font
einstellen:

    titleWrapper => '\textsf{\textbf{%s}}'

=item titles => \@titles (Default: [])

Liste der Kolumnentitel.

=item titleCallback => sub {} (Default: I<siehe unten>)

Subroutine, die die Titelinformation liefert, die in den
LaTeX-Code eingesetzt wird. Default:

    sub {
        my ($self,$l,$title,$n) = @_;
        return $l->protect($title);
    }

=back

=head4 Returns

LongTable-Objekt

=head4 Description

Instantiiere ein LaTeX LongTable-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyval

    my $self = $class->SUPER::new(
        align => undef,
        alignments => [],
        border => undef,
        callbackArguments => [],
        caption => undef,
        label => undef,
        language => 'german',
        multiLine => undef,
        rows => [],
        rowCallback => sub {
            my ($self,$l,$row,$n) = @_;

            my @row;
            for my $val (@$row) {
                push @row,$l->protect($val);
            }

            return @row;
        },
        titleColor => undef,
        titleWrapper => undef,
        titles => [],
        titleCallback => sub {
            my ($self,$l,$title,$n) = @_;
            return $l->protect($title);
        },
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $tab->latex($l);
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

    my ($align,$alignA,$border,$cbArguments,$caption,$label,$language,
        $multiLine,$rowA,$rowCb,$titleColor,$titleWrapper,$titleA,$titleCb) =
        $self->get(qw/align alignments border callbackArguments caption label
        language multiLine rows rowCallback titleColor titleWrapper titles
        titleCallback/);

    if (!@$titleA && !@$rowA) {
        return '';
    }

    my $body;

    # Anzahl Kolumnen
    my $width = @$alignA;

    # Default-Umrandung

    if (!defined $border) {
        $border = $multiLine? 'hvHV': 'hHV';
    }

    # Linien
    
    my $tBorder = $border =~ tr/th//? 1: 0;
    my $hBorder = $border =~ tr/h//? 1: 0;
    my $HBorder = $border =~ tr/H//? 1: 0;
    my $vBorder = $border =~ tr/v//? 1: 0;
    my $VBorder = $border =~ tr/V//? 1: 0;

    # Head

    my $titleLine = '';
    if (@$titleA) {
        my @arr;
        for (my $i = 0; $i < @$titleA; $i++) {
             my $val = $titleCb->($self,$l,$titleA->[$i],$i,@$cbArguments);
             if ($multiLine) {
                 $val =~ s|\n|\\\\|g;
                 $val = $l->cx('\makecell[%sb]{%s}',$alignA->[$i],$val);
                 if ($titleColor) {
                     # Hack, damit der gesamte Hintergrund farbig wird.
                     # Ist nur bei \makecell nötig.
                     $val = $l->cx('{\setlength{\fboxsep}{0pt}'.
                         '\colorbox[HTML]{%s}{%s}}',$titleColor,$val);
                 }
             }
             if ($titleWrapper) {
                 $val = $l->cx($titleWrapper,$val);
             }
             push @arr,$val;
        }
        if ($titleColor) {
            $titleLine .= $l->cx('\rowcolor[HTML]{%s} ',$titleColor);
        }
        $titleLine .= join(' & ',@arr).' \\\\';
        $titleLine .= $tBorder? ' \hline': '';
        $titleLine .= "\n";
    }
    
    # \firsthead

    $body .= $HBorder? $l->cn('\hline'): '';
    $body .= $titleLine; # Leer, wenn kein Titel
    if ($label) {
        $body .= $l->cn('\label{%s}',$label);
    }
    $body .= $l->cn('\endfirsthead');
    
    # \endhead
        
    my $msg = $language eq 'german'? 'Fortsetzung': 'Continuation';
    $body .= $l->cn('\multicolumn{%s}{r}{\\emph{%s}} \\\\',$width,$msg);
    $body .= $HBorder? $l->cn('\hline'): '';
    $body .= $titleLine; # leer, wenn kein Titel
    $body .= $l->cn('\endhead');

    # \endfoot

    $body .= $HBorder? $l->cn('\hline'): '';
    $msg = $language eq 'german'? 'weiter': 'next';
    $body .= $l->cn('\multicolumn{%s}{r}{\\emph{%s}} \\\\',$width,$msg);
    $body .= $l->cn('\endfoot');

    # \endlastfoot

    if ($caption) {
        $body .= $l->cn('\captionsetup{skip=1ex}');
        $body .= $l->cn('\caption{%s}',$caption);
    }
    $body .= "\\endlastfoot\n";

    # Body

    for (my $i = 0; $i < @$rowA; $i++) {
        my @arr = $rowCb->($self,$l,$rowA->[$i],$i,@$cbArguments);
        if ($multiLine) {
            for (my $j = 0; $j < @arr; $j++) {
                 if ($arr[$j] =~ s|\n|\\\\|g) {
                     $arr[$j] = $l->cx('\makecell[%st]{%s}',
                         $alignA->[$j],$arr[$j]);
                 }
            }
        }
        my $line .= join(' & ',@arr).' \\\\';
        $line .= $i < @$rowA-1? $hBorder? ' \hline': '':
            $HBorder? ' \hline': '';
        $line .= "\n";
        $body .= $line;
    }

    # Environment

    my $colSpec = join $vBorder? '|': '',@$alignA;
    if ($VBorder) {
        $colSpec = "|$colSpec|";
    }

    return $l->env('longtable',$body,
        -o => $align,
        -p => $colSpec,
    );
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
