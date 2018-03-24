package Sdoc::Application::Update;
use base qw/Sdoc::Core::Program/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Shell;
use Sdoc::Core::Path;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Application::Update

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

    # Optionen und Argumente

    my ($error,$opt,$argA) = $self->options(
        -force => 0,
        -help => 0,
    );
    if ($error) {
        $self->help(10,"ERROR: $error");
    }
    elsif ($opt->help) {
        $self->help;
    }
    elsif (@$argA != 1) {
        $self->help(11,'ERROR: Wrong number of arguments');
    }
    my $dir = shift @$argA;

    my $sh = Sdoc::Core::Shell->new;
    $sh->cd($dir);
    $sh->set(log=>1);

    my $createExample = 0;

    my $createManual = 0;

    # Sdoc-Beispielseite erzeugen und croppen

    my $path = 'doc/sdoc-example';
    if ($opt->force || Sdoc::Core::Path->newer("$path.sdoc","$path.pdf")) {
        # Erzeuge PDF-Version
        
        $sh->exec("sdoc pdf $path.sdoc $path.pdf --shell-escape");
        #$sh->exec("mv $path.pdf $path.pdf.tmp");
        #$sh->exec("pdfcrop $path.pdf.tmp $path.pdf");
        #$sh->exec("rm $path.pdf.tmp");
        $sh->exec("pdftoppm $path.pdf $path -png");
        $sh->exec("mv $path-1.png $path.png");

        # Erzeuge HTML-Version
        
        $sh->exec("sdoc html $path.sdoc $path.html --shell-escape");
        $sh->exec("sed -ie 's/100/125/g' $path.html");
        $sh->exec("wkhtmltopdf -T 1.5cm -B 1.5cm -L 1.5cm -R 1.5cm $path.html $path-html.pdf",-sloppy=>1);
        # $sh->exec("wkhtmltopdf $path.html $path-html.pdf",-sloppy=>1);
        # $sh->exec("chromium --headless --disable-gpu --print-to-pdf=$path-html.pdf file:///home/fs2/exp/Sdoc/$path.html");
        $sh->exec("pdftoppm $path-html.pdf $path-html -png");
        $sh->exec("mv $path-html-1.png $path-html.png");

        #$sh->exec("pdfcrop $path-html.pdf $path-html-crop.pdf");
        #$sh->exec("pdftoppm $path-html-crop.pdf $path-html-crop -png");
        #$sh->exec("mv $path-html-crop-1.png $path-html-crop.png");
        
        $createManual++;
    }

    my $srcFile = 'doc/sdoc-manual.sdoc';
    my $destFile = 'doc/sdoc-manual.pdf';
    if (Sdoc::Core::Path->newer($srcFile,$destFile) || $createManual) {
        $sh->exec("sdoc pdf $srcFile $destFile --shell-escape");
    }

    $srcFile = 'doc/sdoc-test.sdoc';
    $destFile = 'doc/sdoc-test.pdf';
    if ($opt->force || Sdoc::Core::Path->newer($srcFile,$destFile)) {
        $sh->exec("sdoc pdf $srcFile $destFile --shell-escape");
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
