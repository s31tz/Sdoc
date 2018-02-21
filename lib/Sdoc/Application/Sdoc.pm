package Sdoc::Application::Sdoc;
use base qw/Sdoc::Core::Program/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Config;
use Sdoc::Core::Path;
use Sdoc::Core::AnsiColor;
use Sdoc::Document;
use Sdoc::Core::CommandLine;
use Sdoc::Core::Shell;
use Sdoc::Core::FileHandle;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Application::Sdoc

=head1 BASE CLASS

L<Sdoc::Core::Program>

=head1 METHODS

=head2 Objektmethoden

=head3 main() - Hauptprogramm

=head4 Synopsis

    $prg->main;

=head4 Description

Führe das Hauptprogramm aus.

=cut

# -----------------------------------------------------------------------------

sub main {
    my $self = shift;

    # Konfigurationsdatei lesen. Wir erzeugen eine
    # Default-Konfiguration, wenn die Konfigurationsdatei nicht
    # existiert.

    my $ansiColorDefault = 1;
    my $pdfViewerDefault = 'evince';
    my $shellEscapeDefault = 0;
    my $textViewerDefault = 'less -R',
    my $verboseDefault = 0;
    my $workDirDefault = '/tmp/sdoc/%U/%D';

    my $conf = Sdoc::Core::Config->new('~/.sdoc.conf',
        -create => qq|
            # Sdoc configuration

            ansiColor => $ansiColorDefault,
            pdfViewer => $pdfViewerDefault,
            shellEscape => $shellEscapeDefault,
            textViewer => $textViewerDefault,
            workDir => $workDirDefault,

            # eof
        |,
    );

    # Optionen und Argumente

    my ($error,$opt,$argA) = $self->options(
        -ansiColor => $conf->try('ansiColor') // $ansiColorDefault,
        -pdfViewer => $conf->try('pdfViewer') // $pdfViewerDefault,
        -shellEscape => $conf->try('shellEscape') // $shellEscapeDefault,
        -textViewer => $conf->try('textViewer') // $textViewerDefault,
        -verbose => $conf->try('verbose') // $verboseDefault,
        -workDir => $conf->try('workDir') // $workDirDefault,
        -help => 0,
    );
    if ($error) {
        $self->help(10,"ERROR: $error");
    }
    elsif ($opt->help) {
        $self->help;
    }
    elsif (!@$argA) {
        $self->help(11,'ERROR: Wrong number of arguments');
    }

    my $op = 'pdf';
    if ($argA->[0] =~ /^(anchors|latex|links|pdf|tree|validate)$/) {
        $op = shift @$argA;
    }
    my $sdocFile = shift @$argA;
    my $basename = Sdoc::Core::Path->basename($sdocFile);

    # Ausgabedatei

    my $output = shift @$argA;
    if (defined($output) && $output ne '-') {
        $output = Sdoc::Core::Path->absolute($output);
    }

    # Ausgabe in ANSI Farben
    my $a = Sdoc::Core::AnsiColor->new($opt->ansiColor);

    # Parse Sdoc-Datei

    my $doc = Sdoc::Document->parse($sdocFile,
        -quiet => 0, # Sdoc-Warnings zeigen wir immer an
        -shellEscape => $opt->shellEscape,
    );

    if ($op eq 'validate') {
        # Wir begnügen uns mit dem Parsen des Dokuments
    }
    elsif ($op eq 'anchors') {
        my $maxNumLen = 0;
        for my $node ($doc->anchorNodes) {
            my @path = $node->anchorPathAsArray;
            my $anchor = pop @path;
            printf "%s +%s %s%s\n",
                $a->str('red',ref($node)),
                $a->str('green',sprintf '%-*s',$maxNumLen,$node->lineNum),
                @path? join('/',@path).'/': '',
                $a->str('magenta',$anchor);
        }
    }
    elsif ($op eq 'links') {
        my $maxNumLen = 0;
        for my $node ($doc->linkContainingNodes) {
            for my $e (@{$node->linkA}) {
                my ($linkText,$h) = @$e;

                my $dest = $h->destText;
                if ($h->type eq 'internal') {
                    $dest = $a->str('magenta',
                        $h->destNode->anchorPathAsString);
                }
                elsif ($h->type eq 'unresolved') {
                    $dest = $a->str('reverse','UNRESOLVED');
                }
                elsif ($h->destText ne $h->text) {
                    $dest = $a->str('cyan',$h->destText);
                }
                printf "%s +%s %s %s %s\n",
                    $a->str('red',ref($node)),
                    $a->str('green',sprintf '%-*s',$maxNumLen,$node->lineNum),
                    $linkText,
                    $a->str('green',$h->linkNode? 'Link=>': '=>'),
                    $dest;
            }
        }
    }
    elsif ($op eq 'tree') {
        my $str = $doc->generate('tree',$opt->ansiColor);
        if (-t STDOUT) {
            my $workDir = $self->workDir($opt,$basename);
            my $treeFile = sprintf '%s/tree.txt',$workDir;
            Sdoc::Core::Path->write($treeFile,$str,-encode=>'utf-8');
            
            my $c = Sdoc::Core::CommandLine->new($opt->textViewer);
            $c->addArgument($treeFile);
            Sdoc::Core::Shell->exec($c->command);
        }
        else {
            print $str;
        }
    }
    elsif ($op eq 'latex' || $op eq 'pdf') {
        # Ermittele/erzeuge Arbeitsverzeichnis
        my $workDir = $self->workDir($opt,$basename);

        # Erzeuge LaTeX-Datei

        my $latexFile = sprintf '%s/%s.tex',$workDir,$basename;
        my $fh = Sdoc::Core::FileHandle->new('>',$latexFile);
        $fh->setEncoding('utf-8');
        $fh->print($doc->generate('latex'));
        $fh->close;

        my $sh = Sdoc::Core::Shell->new(quiet=>!$opt->verbose);
        $sh->cd($workDir);

        if ($op eq 'latex') {
            $self->showResult("$basename.tex",$output,$opt->textViewer);
        }
        else {
            # Übersetze LaTeX-Datei nach PDF

            my $c = Sdoc::Core::CommandLine->new('latexmk -pdf');
            $c->addLongOption($opt->shellEscape?
                (-pdflatex => 'pdflatex --shell-escape %O %S'):
                (-pdflatex => 'pdflatex %O %S')
            );
            $c->addArgument($latexFile);
            $c->addString('</dev/null');

            $sh->exec($c->command);

            $self->showResult("$basename.pdf",$output,$opt->pdfViewer);
        }
    }

    # Prüfe, ob alle Knoten destrukturiert werden, wenn der
    # Dokumentknoten nicht mehr referenziert wird. Wenn nicht,
    # generiere eine Warnung.

    $doc = undef;

    my $instantiated = $Sdoc::Node::InstantiatedNodes;
    my $destroyed = $Sdoc::Node::DestroyedNodes;
    if ($instantiated != $destroyed) {
        warn "WARNING: $instantiated nodes instantiated,".
            "only $destroyed nodes destroyed!\n";
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 workDir() - Liefere Arbeitsverzeichnis

=head4 Synopsis

    $workDir = $prg->workDir($opt,$name);

=head4 Description

Liefere das Arbeitsverzeichnis für die Generierung der erzeugten
Formate. Existiert das Verzeichnis nicht, erzeuge es.

=cut

# -----------------------------------------------------------------------------

sub workDir {
    my ($self,$opt,$name) = @_;

    my $workDir = $opt->workDir;
    $workDir =~ s/%U/$self->user/eg;
    $workDir =~ s/%D/$name/g;
    $workDir = Sdoc::Core::Path->expandTilde($workDir);
    Sdoc::Core::Path->mkdir($workDir,-recursive=>1);

    return $workDir;
}

# -----------------------------------------------------------------------------

=head3 showResult() - Zeige Resultat an

=head4 Synopsis

    $prg->showResult($srcFile,$destFile,$pager);

=cut

# -----------------------------------------------------------------------------

sub showResult {
    my ($self,$srcFile,$destFile,$pager) = @_;

    if ($destFile) {
        if ($destFile eq '-') {
            # Gib Datei auf stdout aus

            my $c = Sdoc::Core::CommandLine->new('cat');
            $c->addArgument($srcFile);
            Sdoc::Core::Shell->exec($c->command); # nach stdout
        }
        else {
            # Kopiere Datei
            Sdoc::Core::Path->copy($srcFile,$destFile,-createDir=>1);
        }
    }
    else {
        # Zeige Datei an
        Sdoc::Core::Shell->exec(sprintf('%s %s',$pager,$srcFile),
            -quiet => $pager eq 'evince'? 1: 0,
        );
    }

    return;
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
