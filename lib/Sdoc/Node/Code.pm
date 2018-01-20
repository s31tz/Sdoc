package Sdoc::Node::Code;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 0.01;

use Sdoc::Core::Unindent;
use Sdoc::Core::Path;
use Sdoc::Core::Shell;
use Sdoc::Core::Ipc;

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
Syntax-Highlighting (C<lang=LANGUAGE>) wird per Default I<nicht>
eingerückt. Sonst wird per Default eingerückt. Durch explizite
Setzung des Attributs kann der jeweilige Default überschrieben
werden.

=item load => $file

Lade Datei $file und verwende dessen Inhalt als Text des
Code-Blocks.  Der Code Block hat in diesem Fall keinen
Text-Body. Beginnt der Pfad der Datei mit C<+/>, wird das
Pluszeichen zum Pfad des Dokumentverzeichnisses expandiert.

=item lang => $lang

Die Sprache des Code. Aktiviert Syntax-Highlighting. Einrückung wird
auf Default 0 gesetzt.

=item ln => $n (Default: 0)

Wenn $n > 0, wird der Code mit Zeilennummern
versehen. Start-Zeilennummer ist $n.

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
        indent => $attribH->{'lang'} || $attribH->{'ln'}? 0: 1,
        text => undef,
    );
    $self->setAttributes(%$attribH);

    # Lies den Text aus einer Datei oder von einem Programm

    my $text;
    if (my $file = $root->expandPlus($self->load)) {
        $text = Sdoc::Core::Path->read($file,-decode=>'utf-8');
    }
    elsif (my $cmd = $root->expandPlus($self->exec)) {
        $text = Sdoc::Core::Shell->exec($cmd,
            -capture => 'stdout+stderr',
        );
    }
    if (defined $text) {
        chomp $text;
        $self->set(text=>$text);
    }

    # Filtere den Text

    if (my $cmd = $root->expandPlus($self->filter)) {
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

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $cod->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latex {
    my ($self,$gen) = @_;

    my $text = $self->text;

    my @opt;
    my $indent = $self->indent;
    if (my $ln = $self->ln) {
        my $c = chr(length($ln + $text =~ tr/\n//) + 96); # a, b, c, d
        my $i = $indent? 'i': '';
        push @opt,'linenos',"firstnumber=$ln","xleftmargin=\\lnwidth$c$i";
    }
    elsif ($indent) {
        push @opt,'xleftmargin=1.3em';
    }

    if (my $lang = $self->lang) {
        # Minted-Umgebung

        return $gen->env('minted',$text,
            -o => \@opt,
            -p => lc $lang,
            -indent => 0,
            -nl=>2,
        );
    }

    # Verbatim-Umgebung

    return $gen->env('Verbatim',$text,
        -o => \@opt,
        -indent => 0,
        -nl => 2,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

0.01

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
