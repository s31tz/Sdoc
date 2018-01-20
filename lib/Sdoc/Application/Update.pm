package Sdoc::Application::Update;
use base qw/Sdoc::Core::Program/;

use strict;
use warnings;

our $VERSION = 0.01;

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

    my $srcFile = 'doc/sdoc-example.sdoc';
    my $destFile = 'doc/sdoc-example.pdf';
    if (Sdoc::Core::Path->newer($srcFile,$destFile)) {
        $sh->exec("sdoc pdf $srcFile --output=$destFile");
        $sh->exec("mv $destFile $destFile.tmp");
        $sh->exec("pdfcrop $destFile.tmp $destFile");
        $sh->exec("rm $destFile.tmp");
        $createManual++;
    }

    $srcFile = 'doc/sdoc-manual.sdoc';
    $destFile = 'doc/sdoc-manual.pdf';
    if (Sdoc::Core::Path->newer($srcFile,$destFile) || $createManual) {
        $sh->exec("sdoc pdf $srcFile --output=$destFile");
    }

    return;
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
