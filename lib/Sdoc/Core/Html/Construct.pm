# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Html::Construct - Generierung von einfachen Tag-Konstrukten

=head1 BASE CLASS

L<Sdoc::Core::Html::Tag>

=head1 DESCRIPTION

Die Klasse erweitert ihre Basisklasse Sdoc::Core::Html::Tag um die
Generierung von einfachen HTML-Konstrukten, die einerseits
über Einzeltags hinausgehen, andererseits aber nicht die Implementierung
einer eigenen Klasse rechtfertigen.

=cut

# -----------------------------------------------------------------------------

package Sdoc::Core::Html::Construct;
use base qw/Sdoc::Core::Html::Tag/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.221';

use Sdoc::Core::Css;
use Sdoc::Core::JavaScript;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Objektmethoden

=head3 loadFiles() - Lade CSS- und JavaScript-Dateien

=head4 Synopsis

  $html = $class->loadFiles(@spec);

=cut

# -----------------------------------------------------------------------------

sub loadFiles {
    my $self = shift;
    # @_: @spec

    my (%seen,@css,@js);
    for (my $i = 0; $i < @_; $i++) {
        my $arg = $_[$i];
        if ($arg eq 'css' || $arg =~ /\.css$/) {
            if ($arg eq 'css') {
                $i++;
            }
            my $url = $_[$i];
            if ($seen{"css|$url"}++) {
                next;
            }
            push @css,Sdoc::Core::Css->style($self,$url);
        }
        elsif ($arg eq 'js' || $arg =~ /\.js$/) {
            if ($arg eq 'js') {
                $i++;
            }
            my $url = $_[$i];
            if ($seen{"js|$url"}++) {
                next;
            }
            push @js,Sdoc::Core::JavaScript->script($self,$url);
        }
        else {
            $self->throw(
                'HTML-00099: Unexpected argument',
                Argument => $arg,
            );
        }
    }

    return join '',@css,@js;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.221

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2024 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
