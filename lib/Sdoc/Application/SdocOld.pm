package Sdoc::Application::SdocOld;
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
use Sdoc::Core::AnsiColor;
use File::Temp ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Application::SdocOld

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
        -cleanup => 1,
        -output => undef,
        -preview => 0,
        -quiet => 1,
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

    if (@$argA == 1) {
        # Sdoc-Datei in PDF wandeln und anzeigen

        my $file = shift @$argA;
        my $basename = Sdoc::Core::Path->basename($file);

        # Übersetze Sdoc-Datei in LaTeX-Datei

        my $doc = Sdoc::Document->parse($file,
            -quiet => $opt->quiet,
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

        my $sh = Sdoc::Core::Shell->new(quiet=>$opt->quiet);
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

        return;
    }

    my $format = shift @$argA;
    my $file = shift @$argA;

    my $output = $opt->output;

    if ($format eq 'convert') {
        my $str = Sdoc::Core::Path->read($file,-decode=>'utf-8');

        # Quelltext entfernen
        $str =~ s|^= SOURCE.*|# eof\n|ms;

        # utf8_attribut entfernen
        $str =~ s|^( +)utf8=.*|$1sectionNumberDepth=0|m;

        # Links umschreiben
        $str =~ s|U\{"([^"]+)",target=.*\}|L{$1}|sg;
        $str =~ s|U\{"[^"]+",text="(.+?)".*?\}
            |L{https://metacpan.org/pod/$1}|sxg;
        $str =~ s/l\{(.*?)\}/L{$1}/sg;

        $str =~ s/highlight=(\S+)/lang=$1 indent=0/g;

        $str =~ s/K\{(.*?)\}/$1/sg;

        $str =~ s/\s*M\{(.*?)\}//sg;

        $str =~ s|^ +(%Code:.*?)^ +\.$|$1.|smg;

        $str =~ s| "([^"]+)"| Q{$1}|mg;

        if ($output) {
            Sdoc::Core::Path->write($output,$str);
        }
        else {
            print $str;
        }

        return;
    }

    my $a = Sdoc::Core::AnsiColor->new(1);
    my $doc = Sdoc::Document->parse($file,
        -quiet => $opt->quiet,
        -shellEscape => $opt->shellEscape,
    );

    my $str = '';
    if ($format eq 'validate') {
        # Wir begnügen uns mit dem Parsen des Dokuments
    }
    elsif ($format eq 'anchors') {
        my $maxNumLen = 0;
        for my $node ($doc->anchorNodes) {
            my @path = $node->anchorPathAsArray;
            my $anchor = pop @path;
            $str .= sprintf "%s +%s %s%s\n",
                $a->str('red',ref($node)),
                $a->str('green',sprintf '%-*s',$maxNumLen,$node->lineNum),
                @path? join('/',@path).'/': '',
                $a->str('magenta',$anchor);
        }
    }
    elsif ($format eq 'links') {
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
                $str .= sprintf "%s +%s %s %s %s\n",
                    $a->str('red',ref($node)),
                    $a->str('green',sprintf '%-*s',$maxNumLen,$node->lineNum),
                    $linkText,
                    $a->str('green',$h->linkNode? 'Link=>': '=>'),
                    $dest;
            }
        }
    }
    elsif ($format eq 'tree') {
        $str = $doc->generate($format);
    }
    elsif ($format eq 'latex' && !$opt->preview) {
        $str = $doc->generate($format);
    }
    elsif ($format eq 'pdf' || $format eq 'latex') { # latex+preview
        my $tmpDir = File::Temp::tempdir(CLEANUP=>$opt->cleanup);
        my $texFile = sprintf '%s/%s.tex',
            $tmpDir,Sdoc::Core::Path->basename($file);

        my $fh = Sdoc::Core::FileHandle->new('>',$texFile);
        $fh->setEncoding('utf-8');
        $fh->print($doc->generate('latex'));
        $fh->close;

        my $sh = Sdoc::Core::Shell->new;
        if ($format eq 'latex') { # preview
            $sh->exec("less $texFile");
        }
        else {
            $sh->cd($tmpDir);
            my $cmd = "pdflatex --shell-escape $texFile";
            my $logFile;
            if (!$opt->verbose) {
                $logFile = sprintf '%s/pdflatex.log',$tmpDir;
                $cmd .= " >>$logFile";
            }
            for (1..3) {
                my $r = $sh->exec("$cmd </dev/null",-sloppy=>1);
                if ($r) {
                   if (!$opt->verbose) {
                       $sh->exec("cat 1>&2 $logFile");
                   }
                   $self->exit($r);
                }
            }
            $sh->back;        

            (my $pdfFile = $texFile) =~ s/\.tex$/.pdf/;
            if ($opt->preview) {
                $sh->exec("evince $pdfFile 2>/dev/null");
            }
            $str = Sdoc::Core::Path->read($pdfFile);
        }
    }
    else {
        $self->throw(
            q~SDOC-00001: Unknown command~,
            Command => $format,
            -stacktrace => 0,
        );
    }

    # Gib das Ergebnis aus

    if ($output) {
        Sdoc::Core::Path->write($output,$str);
    }
    elsif (($format ne 'latex' && $format ne 'pdf') || !$opt->preview) {
        print $str;
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
