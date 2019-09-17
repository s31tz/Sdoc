package Sdoc::Application::Sdoc;
use base qw/Sdoc::Core::Program/;

use v5.10.0;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Core::Config;
use Sdoc::Core::Path;
use Sdoc::Core::Html::Pygments;
use Sdoc::Core::Html::Tag;
use Sdoc::Core::Terminal;
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
    my $browserDefault = 'chromium --disable-gpu --new-window';
    my $codeStyleDefault = 'default';
    my $cssPrefixDefault = 'sdoc';
    my $cacheDirDefault = '/tmp/sdoc/%U';
    my $pdfViewerDefault = 'evince -s';
    my $shellEscapeDefault = 0;
    my $textViewerDefault = 'less -R',
    my $verboseDefault = 0;

    my $conf = Sdoc::Core::Config->new('~/.sdoc.conf',
        -create => qq|
            # Sdoc configuration

            ansiColor => $ansiColorDefault,
            browser => '$browserDefault',
            codeStyle => '$codeStyleDefault',
            cssPrefix => '$cssPrefixDefault',
            cacheDir => '$cacheDirDefault',
            pdfViewer => '$pdfViewerDefault',
            shellEscape => $shellEscapeDefault,
            textViewer => '$textViewerDefault',
            verbose => $verboseDefault,

            # eof
        |,
    );

    # Optionen und Argumente

    my ($error,$opt,$argA) = $self->options(
        -ansiColor => $conf->try('ansiColor') // $ansiColorDefault,
        -browser => $conf->try('browser') // $browserDefault,
        -cacheDir => $conf->try('cacheDir') // $cacheDirDefault,
        -codeStyle => undef, # Sdoc-Eigenschaft
        -cssPrefix => undef, # Sdoc-Eigenschaft
        -convert => 0,
        -indentMode => undef, # Document.indentMode
        -pdfViewer => $conf->try('pdfViewer') // $pdfViewerDefault,
        -sectionNumberLevel => undef, # Document.sectionNumberLevel
        -selector => '.sdoc-code text',
        -shellEscape => $conf->try('shellEscape') // $shellEscapeDefault,
        -tableOfContents => undef, # Document.tableOfContents
        -textViewer => $conf->try('textViewer') // $textViewerDefault,
        -verbose => $conf->try('verbose') // $verboseDefault,
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
    if ($argA->[0] =~ /^(anchors|cleanup|convert|html|latex|links|pdf|
            mediawiki|code-style-(names|page|file)|tree|validate)$/x) {
        $op = shift @$argA;
    }

    # Operationen ohne Sdoc-Dokument

    if ($op eq 'code-style-file') {
        if (@$argA == 0 || @$argA > 2) {
            $self->help(11,'ERROR: Wrong number of arguments');
        }
        my ($style,$output) = @$argA;
        if (defined($output) && $output ne '-') {
            $output = Sdoc::Core::Path->absolute($output);
        }
        my ($styleCode,$bgColor) = Sdoc::Core::Html::Pygments->css(
            $style,$opt->selector);
        my $styleFile = sprintf '%s/%s/%s.css',
            $self->cacheDir($opt),'style-code',$style;
        Sdoc::Core::Path->write($styleFile,$styleCode,-recursive=>1);
        $self->showResult($styleFile,$output,$opt->textViewer);
        return;
    }
    elsif ($op eq 'code-style-page') {
        if (@$argA < 2) {
            $self->help(11,'ERROR: Wrong number of arguments');
        }
        my ($lang,$file,$output) = @$argA;
        if (defined($output) && $output ne '-') {
            $output = Sdoc::Core::Path->absolute($output);
        }
        my $code = Sdoc::Core::Path->read($file);
        my $h = Sdoc::Core::Html::Tag->new;
        my $html = Sdoc::Core::Html::Pygments->stylesPage($h,$lang,$code);
        my $htmlFile = sprintf '%s/code-style-page/code-style-page.html',
            $self->cacheDir($opt);
        Sdoc::Core::Path->write($htmlFile,$html,-recursive=>1);
        $self->showResult($htmlFile,$output,$opt->browser);
        return;
    }
    elsif ($op eq 'code-style-names') {
        if (@$argA) {
            $self->help(11,'ERROR: Wrong number of arguments');
        }
        print join("\n",Sdoc::Core::Html::Pygments->styles),"\n";
        return;
    }
    elsif ($op eq 'cleanup') {
        if (@$argA) {
            $self->help(11,'ERROR: Wrong number of arguments');
        }
        # Lösche Arbeitsverzeichnis-Baum

        my $cacheDir = $self->cacheDir($opt);
        my $answ = Sdoc::Core::Terminal->askUser(
            "Really delete cache directory $cacheDir?",
            -values => 'y/n',
            -default => 'y',
        );
        if ($answ ne 'y') {
            print "Aborted.\n";
            return;
        }
        Sdoc::Core::Path->delete($cacheDir);
        return;
    }

    # Operationen auf Sdoc-Dokument

    my $sdocFile = shift @$argA;
    my $basename = Sdoc::Core::Path->basename($sdocFile);

    # Ausgabedatei

    my $output = shift @$argA;
    if (defined($output) && $output ne '-') {
        $output = Sdoc::Core::Path->absolute($output);
    }

    # Ausgabe in ANSI Farben
    my $a = Sdoc::Core::AnsiColor->new($opt->ansiColor);

    if ($op eq 'convert') {
        # Wandele Sdoc-Datei von Sdoc2 nach Sdoc3
        
        my $sdoc3File = $self->sdoc2ToSdoc3($sdocFile,$opt);
        $self->showResult($sdoc3File,$output,$opt->textViewer);
        return;
    }

    if ($opt->convert) {
        # Wandelung vor der Weiterverarbeitung
        $sdocFile = $self->sdoc2ToSdoc3($sdocFile,$opt);
    }

    # Parse Sdoc-Datei

    my $doc = Sdoc::Document->parse($sdocFile,
        -quiet => 0, # Sdoc-Warnings zeigen wir immer an
        -shellEscape => $opt->shellEscape,
        -userH => $opt,
        -configH => $conf,
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
            my $docDir = $self->docDir('tree',$basename,$opt);
            my $treeFile = sprintf '%s/tree.txt',$docDir;
            Sdoc::Core::Path->write($treeFile,$str,-encode=>'utf-8');
            
            my $c = Sdoc::Core::CommandLine->new($opt->textViewer);
            $c->addArgument($treeFile);
            Sdoc::Core::Shell->exec($c->command);
        }
        else {
            print $str;
        }
    }
    elsif ($op eq 'html') {
        # Ermittele/erzeuge Arbeitsverzeichnis
        my $docDir = $self->docDir('html',$basename,$opt);

        # Erzeuge HTML-Datei

        my $htmlFile = sprintf '%s/%s.html',$docDir,$basename;
        my $fh = Sdoc::Core::FileHandle->new('>',$htmlFile);
        $fh->setEncoding('utf-8');
        $fh->print($doc->generate('html'));
        $fh->close;

        # Wechsele in Arbeitsverzeichnis

        my $sh = Sdoc::Core::Shell->new(quiet=>!$opt->verbose);
        $sh->cd($docDir);

        # Zeige/kopiere Ergebnis
        $self->showResult("$basename.html",$output,$opt->browser);
    }
    elsif ($op eq 'latex' || $op eq 'pdf') {
        # Ermittele/erzeuge Arbeitsverzeichnis
        my $docDir = $self->docDir('latex',$basename,$opt);

        # Erzeuge LaTeX-Datei

        my $latexFile = sprintf '%s/%s.tex',$docDir,$basename;
        my $fh = Sdoc::Core::FileHandle->new('>',$latexFile);
        $fh->setEncoding('utf-8');
        $fh->print($doc->generate('latex'));
        $fh->close;

        # Wechsele in Arbeitsverzeichnis

        my $sh = Sdoc::Core::Shell->new(quiet=>!$opt->verbose);
        $sh->cd($docDir);

        # Zeige/kopiere Ergebnis
        
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
    elsif ($op eq 'mediawiki') {
        # Ermittele/erzeuge Arbeitsverzeichnis
        my $docDir = $self->docDir('mediawiki',$basename,$opt);

        # Erzeuge MediaWiki-Datei

        my $mediaWikiFile = sprintf '%s/%s.mw',$docDir,$basename;
        my $fh = Sdoc::Core::FileHandle->new('>',$mediaWikiFile);
        $fh->setEncoding('utf-8');
        $fh->print($doc->generate('mediawiki'));
        $fh->close;

        # Wechsele in Arbeitsverzeichnis

        my $sh = Sdoc::Core::Shell->new(quiet=>!$opt->verbose);
        $sh->cd($docDir);

        # Zeige/kopiere Ergebnis
        $self->showResult("$basename.mw",$output,$opt->textViewer);
    }
    else {
        $self->throw(
            'SDOC-00001: Unknown format/operation',
            Operation => $op,
        );
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

=head3 cacheDir() - Liefere Cache-Verzeichnis

=head4 Synopsis

  $cacheDir = $prg->cacheDir($opt);

=head4 Description

Liefere das Cache-Verzeichnis für die
Dokument-Generierung. Existiert das Verzeichnis nicht, wird es erzeugt.

=cut

# -----------------------------------------------------------------------------

sub cacheDir {
    my ($self,$opt) = @_;

    my $cacheDir = $opt->cacheDir;
    if ($cacheDir =~ m|(.*)/%U|) {
        # Das Eltern-Verzeichnis des User-Verzeichnisses
        # muss für alle schreibbar sein
        Sdoc::Core::Path->mkdir($1,-forceMode=>01777);
    }
    $cacheDir =~ s/%U/$self->user/eg;
    $cacheDir = Sdoc::Core::Path->expandTilde($cacheDir);
    Sdoc::Core::Path->mkdir($cacheDir,-recursive=>1);

    return $cacheDir;
}

# -----------------------------------------------------------------------------

=head3 docDir() - Liefere Arbeitsverzeichnis

=head4 Synopsis

  $docDir = $prg->docDir($format,$basename,$opt);

=head4 Description

Liefere das Arbeitsverzeichnis für die Generierung des erzeugten
Formats. Existiert das Verzeichnis nicht, erzeuge es.

=cut

# -----------------------------------------------------------------------------

sub docDir {
    my ($self,$format,$basename,$opt) = @_;

    my $docDir = sprintf '%s/%s/%s',$self->cacheDir($opt),$basename,$format;
    Sdoc::Core::Path->mkdir($docDir,-recursive=>1);

    return $docDir;
}

# -----------------------------------------------------------------------------

=head3 sdoc2ToSdoc3() - Wandele Sdoc2 Datei nach Sdoc3-Datei

=head4 Synopsis

  $sdoc3File = $prg->sdoc2ToSdoc3($sdoc2File,$opt);

=head4 Description

Wandele Sdoc2-Datei $sdoc2File im Arbeitsverzeichnis in eine
Sdoc3-Datei und liefere den Pfad der erzeugten Sdoc3-Datei zurück.

=cut

# -----------------------------------------------------------------------------

sub sdoc2ToSdoc3 {
    my ($self,$sdoc2File,$opt) = @_;

    my $code = Sdoc::Core::Path->read($sdoc2File,-decode=>'utf-8');
    $code = Sdoc::Document->sdoc2ToSdoc3($code);

    my $basename = Sdoc::Core::Path->basename($sdoc2File);
    my $docDir = $self->docDir('sdoc3',$basename,$opt);
    my $sdoc3File = sprintf '%s/%s.sdoc3',$docDir,$basename;
    Sdoc::Core::Path->write($sdoc3File,$code,-encode=>'utf-8');

    return $sdoc3File;
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
            -quiet => $pager =~ /evince|acroread|chrome/? 1: 0,
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

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
