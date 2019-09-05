package Sdoc::Core::Html::Construct;
use base qw/Sdoc::Core::Html::Tag/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.156';

use Sdoc::Core::Css;
use Sdoc::Core::JavaScript;

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

=head1 METHODS

=head2 Objektmethoden

=head3 loadFiles()

=head4 Synopsis

    $html = $class->loadFiles(@spec);

=head4 Description

Siehe Basisklasse Sdoc::Core::Html::Tag.

=cut

# -----------------------------------------------------------------------------

sub loadFiles {
    my $self = shift;
    # @_: @spec

    my $html = '';
    for (my $i = 0; $i < @_; $i++) {
        my $arg = $_[$i];
        if ($arg eq 'css' || $arg =~ /\.css$/) {
            if ($arg eq 'css') {
                $i++;
            }
            $html .= Sdoc::Core::Css->style($self,$_[$i]);
        }
        elsif ($arg eq 'js' || $arg =~ /\.js$/) {
            if ($arg eq 'js') {
                $i++;
            }
            $html .= Sdoc::Core::JavaScript->script($self,$_[$i]);
        }
        else {
            $self->throw(
                'HTML-00099: Unexpected argument',
                Argument => $arg,
            );
        }
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.156

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