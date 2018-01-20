package Sdoc::Document;
use base qw/Sdoc::Core::Object/;

use strict;
use warnings;

our $VERSION = 0.01;

use Sdoc::Node::BridgeHead;
use Sdoc::Node::Code;
use Sdoc::Node::Comment;
use Sdoc::Node::Document;
use Sdoc::Node::Graphic;
use Sdoc::Node::Item;
use Sdoc::Node::Link;
use Sdoc::Node::List;
use Sdoc::Node::PageBreak;
use Sdoc::Node::Paragraph;
use Sdoc::Node::Section;
use Sdoc::Node::TableOfContents;
use Sdoc::Core::Option;
use Sdoc::Core::Path;
use Sdoc::LineProcessor;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Document - Sdoc-Dokument

=head1 BASE CLASS

L<Sdoc::Core::Object>

=head1 SYNOPSIS

    use Sdoc::Document;
    
    my $doc = Sdoc::Document->parse($file);
    print $doc->generate('latex');

=head1 DESCRIPTION

Diese Klasse implementiert die Klassenmethode parse(), mit der ein
Sdoc-Dokument in einen Parsingbaum überführt wird. Die Methode
liefert den Wurzelknoten auf diesen Parsingbaum zurück. Der
Wurzelknoten ist vom Typ Sdoc::Node::Document. Alle weiteren
Methoden, um auf dem Parsingbaum zu operieren, implementiert die
Klasse Sdoc::Node::Document oder deren Basisklasse Sdoc::Node.

=head1 METHODS

=head2 Klassenmethoden

=head3 parse() - Parse Sdoc-Dokument

=head4 Synopsis

    $doc = $class->parse($file,@opt);
    $doc = $class->parse(\$str,@opt);
    $doc = $class->parse(\@lines,@opt);

=head4 Arguments

=over 4

=item $file

Pfad einer Sdoc-Datei.

=item $str

Sdoc-Quelltext als Zeichenkette.

=item @lines

Sdoc-Quelltest als Array von Zeilen.

=item @opt

Liste von Optionen.

=back

=head4 Options

=over 4

=item -markup => $markup (Default: 'sdoc')

Markup-Variante. Mögliche Werte: 'sdoc'.

=item -quiet => $bool (Default: 0)

Gib keine Warnungen aus.

=back

=head4 Returns

Referenz auf Dokument-Knoten (Typ: Sdoc::Node::Document)

=head4 Description

Parse ein Sdoc-Dokument und liefere eine Referenz auf
den Wurzelknoten des Parsingbaums zurück.

=cut

# -----------------------------------------------------------------------------

sub parse {
    my $class = shift;
    my $input = shift;
    # @_: @opt

    # Optionen

    my $markup = 'sdoc';
    my $quiet = 0;

    Sdoc::Core::Option->extract(\@_,
        -markup => \$markup,
        -quiet => \$quiet,
    );

    # Relativen Pfad in absoluten Pfad wandeln
    
    if (!ref $input) {
        $input = Sdoc::Core::Path->absolute($input);
    }

    # Instantiiere LineProcessor

    my $par = Sdoc::LineProcessor->new($input,
        -encoding => 'utf-8',
        -lineContinuation => 'backslash',
    );

    # Instantiiere den Dokument-Knoten. Dieser bildet die
    # Wurzel des Sdoc-Parsingbaums.

    my $doc = Sdoc::Node::Document->new(undef,$par,undef,undef);
    $doc->set(
        input => $input,
        quiet => $quiet,
    );
    $doc->weaken(root=>$doc); # Verweis auf sich selbst

    # Sdoc-Quelltext in Parsingbaum überführen

    my $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant) = $par->nextType(1);
        $doc->push(childA=>$nodeClass->new($variant,$par,$doc,$doc));
    }

    # L-Segmente (Links) auflösen
    $doc->resolveLinks;

    # G-Segmente (Inline-Grafiken) auflösen
    $doc->resolveGraphics;

    return $doc;
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
