package Sdoc::Core::Html::Producer;
use base qw/Sdoc::Core::Html::Construct/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.156';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Html::Producer - Generierung von HTML-Code

=head1 BASE CLASS

L<Sdoc::Core::Html::Construct>

=head1 DESCRIPTION

Die Klasse vereinigt die Funktionalität der Klassen Sdoc::Core::Html::Tag
und Sdoc::Core::Html::Construct und erlaubt somit die Generierung von
einzelnen HTML-Tags und einfachen Tag-Konstrukten. Sie
implementiert keine eigene Funktionalität, sondern erbt diese von
ihren Basisklassen. Der Konstruktor ist in der Basisklasse
Sdoc::Core::Html::Tag implementiert.

Vererbungshierarchie:

    Sdoc::Core::Html::Tag        (einzelne HTML-Tags)
        |
    Sdoc::Core::Html::Construct  (einfache Konstrukte aus HTML-Tags)
        |
    Sdoc::Core::Html::Producer   (vereinigte Funktionalität)

Einfacher Anwendungsfall:

    my $h = Sdoc::Core::Html::Producer->new;
    print Sdoc::Core::Html::Page->html($h,
        ...
    );

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
