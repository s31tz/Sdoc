package Sdoc::Node::Code;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Unindent;
use Sdoc::Core::Path;
use Sdoc::Core::Shell;
use Sdoc::Core::Ipc;
use Sdoc::Core::Html::Pygments;
use Sdoc::Core::Css;
use Sdoc::Core::Html::Verbatim;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Code - Code-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Code-Block.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Code-Knoten folgende zusätzliche Attribute:

=over 4

=item exec => $command

Führe das Kommando $command aus und verwende dessen Ausgabe nach
stdout und stderr als Text des Code-Blocks. Der Code Block hat in
diesem Fall keinen Text-Body. Beginnt das Kommando mit C<+/>, wird
das Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=item extract => $regex

Reduziere den Text auf einen Teil. Der Reguläre Ausdruck $regex
hat Perl-Mächtigkeit und wird unter den Modifiern C<s> (C<.>
matcht Zeilenumbrüche) und C<m> (C<^> und C<$> matchen
Zeilenanfang und -ende) interpretiert. Der Reguläre Ausdruck
muss einen eingebetteten Klammerausdruck C<(...)> enthalten.
Dieser "captured" den gewünschten Teil.

=item filter => $command

Schicke den Text des Code-Blocks an Kommando $command und ersetze
ihn durch dessen Ausgabe. Das Kommando arbeitet als Filter, liest
also von stdin und schreibt nach stdout. Beginnt das Kommando mit
C<+/>, wird das Pluszeichen zum Pfad des Dokumentverzeichnisses
expandiert.

=item indent => $bool (Default: I<kontextabhängig>)

Rücke den Text ein. Im Falle von Zeilennummern (C<ln=N>) oder
wird I<nicht> eingerückt. Sonst wird eingerückt. Durch explizite
Setzung des Attributs kann der jeweilige Default überschrieben
werden.

=item load => $file

Lade Datei $file und verwende dessen Inhalt als Text des
Code-Blocks.  Der Code Block hat in diesem Fall keinen
Text-Body. Beginnt der Pfad der Datei mit C<+/>, wird das
Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=item lang => $lang

Der Code ist Quelltext der Sprache $lang. Mit dieser Option wird
das Syntax-Highlighting aktiviert. Dies verfügbaren Sprachen
("Lexer") liefert das Kommando

    $ pygmentize -L lexers

=item ln => $n (Default: 0)

Wenn $n > 0, wird der Code mit Zeilennummern
versehen. Start-Zeilennummer ist $n.

=item number => $n

Nummer des Codeblocks. Wird automatisch hochgezählt.

=item text => $text

Text des Code-Blocks.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Code-Knoten

=head4 Synopsis

    $cod = $class->new($par,$variant,$root,$parent);

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

Code-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Allgemeine Information
    my $markup = $par->markup;

    # Quelltext verarbeiten

    my $attribH;
    if ($variant == 0) {
        # %Code:
        #   KEY=VAL
        # TEXT
        # .
        $attribH = $par->readBlock('text',['load','exec']);
    }
    elsif ($markup eq 'sdoc') {
        # " TEXT"

        my $lineA = $par->lines;
        my $input = $lineA->[0]->input;
        my $lineNum = $lineA->[0]->number;

        my $text = '';
        while (@$lineA) {
            my $str = $lineA->[0]->text;
            if (substr($str,0,1) ne ' ') {
                last;
            }
            $text .= "$str\n";
            shift @$lineA;
        }
        $text = Sdoc::Core::Unindent->trim($text);

        $attribH = {
            input => $input,
            lineNum => $lineNum,
            text => $text,
        };
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new('Code',$variant,$root,$parent,
        exec => undef,
        extract => undef,
        filter => undef,
        load => undef,
        lang => undef,
        ln => 0,
        indent => undef,
        number => $root->increment('countCode'),
        text => undef,
    );
    $self->setAttributes(%$attribH);

    # Lies den Text aus einer Datei oder von einem Programm

    my $text;
    if (my $file = $root->expandPath($self->load)) {
        $text = Sdoc::Core::Path->read($file,-decode=>'utf-8');
    }
    elsif (my $cmd = $root->expandPath($self->exec)) {
        $text = Sdoc::Core::Shell->exec($cmd,
            -capture => 'stdout+stderr',
        );
    }
    if (defined $text) {
        chomp $text;
        $self->set(text=>$text);
    }

    # Filtere den Text

    if (my $cmd = $root->expandPath($self->filter)) {
        my ($text) = Sdoc::Core::Ipc->filter($cmd,$self->text);
        chomp $text;
        $self->set(text=>$text);
    }

    # Reduziere den Text auf einen Teil

    if (my $regex = $self->extract) {
        if ($self->text =~ /$regex/sm) {
            my $text = $1;
            chomp $text;
            $self->set(text=>$text);
        }
    }

    # Konsistenzbedingungen prüfen

    if (($self->lang || $self->exec || $self->filter)
            && !$root->shellEscape) {
        $self->throw(
            q~SDOC-00006: Option shellEscape (--shell-escape) must be set~,
            file => $self->input,
            line => $self->lineNum,
            -stacktrace => 0,
        );
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 generateHtml() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $cod->generateHtml($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateHtml {
    my ($self,$h) = @_;

    my $doc = $self->root;

    my $indent = $self->indent;
    my $ln = $self->ln;
    my $id = sprintf 'cod%02d',$self->number;

    my $text;
    if (my $lang = $self->lang) {
        $text = Sdoc::Core::Html::Pygments->html($lang,$self->text);
    }
    else {
        $text = $h->protect($self->text);
    }

    my $marginLeft;
    if ($self->indent || $doc->indentStyle && !defined $self->indent) {
        $marginLeft = sprintf('%spx',$doc->htmlIndentation);
    }

    # HTML-Code erzeugen

    return $h->cat(
        $h->tag('style',
            Sdoc::Core::Css->new('flat')->restrictedRules("#$id",
                '' => [
                    marginTop => '16px',
                    marginBottom => '16px',
                    marginLeft => $marginLeft,
                ],
                'td pre' => [
                    margin => 0,
                ],
            )
        ),
        Sdoc::Core::Html::Verbatim->html($h,
            class => 'sdoc-code',
            id => $id,
            ln => $self->ln,
            text => $text,
        ),
    );
}

# -----------------------------------------------------------------------------

=head3 generateLatex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $cod->generateLatex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub generateLatex {
    my ($self,$l) = @_;

    my $root = $self->root;
    my $text = $self->text;

    my @opt;
    my $indent = $self->indent;
    if (my $ln = $self->ln) {
        my $c = chr(length($ln + $text =~ tr/\n// - 1) + 96); # a, b, c, d
        my $i = $indent? 'i': '';
        push @opt,'linenos',"firstnumber=$ln","xleftmargin=\\lnwidth$c$i";
    }
    elsif ($indent) {
        push @opt,sprintf 'xleftmargin=%sem',$root->latexIndentation;
    }

    if (my $lang = $self->lang) {
        # Minted-Umgebung

        return $l->env('minted',$text,
            -o => \@opt,
            -p => lc $lang,
            -indent => 0,
            -nl=>2,
        );
    }

    # Verbatim-Umgebung

    return $l->env('Verbatim',$text,
        -o => \@opt,
        -indent => 0,
        -nl => 2,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

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
