package Sdoc::Application::Sdoc;
use base qw/Sdoc::Core::Program/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Config;
use Sdoc::Core::Path;
use Sdoc::Document;
use Sdoc::Core::FileHandle;
use Sdoc::Core::Shell;
use Sdoc::Core::CommandLine;

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

    my $pdfViewerDefault = 'evince';
    my $shellEscapeDefault = 0;
    my $workDirDefault = '/tmp/sdoc/%U/%D';

    my $conf = Sdoc::Core::Config->new('~/.sdoc.conf',
        -create => q|
            # Sdoc configuration

            pdfViewer => $pdfViewerDefault,
            shellEscape => $shellEscapeDefault,
            workDir => $workDirDefault,

            # eof
        |,
    );

    # Optionen und Argumente

    my ($error,$opt,$argA) = $self->options(
        -pdfViewer => $conf->try('pdfViewer') // $pdfViewerDefault,
        -shellEscape => $conf->try('shellEscape') // $shellEscapeDefault,
        -workDir => $conf->try('workDir') // $workDirDefault,
        -verbose => 0,
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

    # Sdoc-Datei in PDF wandeln und anzeigen

    my $file = shift @$argA;
    my $basename = Sdoc::Core::Path->basename($file);

    # Übersetze Sdoc-Datei in LaTeX-Datei

    my $doc = Sdoc::Document->parse($file,
        -quiet => 0, # Sdoc-Warnings zeigen wir immer an
        -shellEscape => $opt->shellEscape,
    );

    # Erzeuge Arbeitsverzeichnis

    my $workDir = $opt->workDir;
    $workDir =~ s/%U/$self->user/eg;
    $workDir =~ s/%D/$basename/g;
    $workDir = Sdoc::Core::Path->expandTilde($workDir);
    Sdoc::Core::Path->mkdir($workDir,-recursive=>1);

    # Erzeuge LaTeX-Datei

    my $latexFile = sprintf '%s/%s.tex',$workDir,$basename;
    my $fh = Sdoc::Core::FileHandle->new('>',$latexFile);
    $fh->setEncoding('utf-8');
    $fh->print($doc->generate('latex'));
    $fh->close;

    # Übersetze LaTeX-Datei nach PDF

    my $sh = Sdoc::Core::Shell->new(quiet=>!$opt->verbose);
    $sh->cd($workDir);

    my $c = Sdoc::Core::CommandLine->new('latexmk -pdf');
    $c->addLongOption(
        $opt->shellEscape? (-pdflatex => 'pdflatex --shell-escape %O %S'):
            (-pdflatex => 'pdflatex %O %S')
    );
    $c->addArgument($latexFile);

    $sh->exec($c->command);

    # Zeige PDF-Datei an
    $sh->exec(sprintf '%s %s.pdf',$opt->pdfViewer,$basename);

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
