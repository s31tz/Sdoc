package Sdoc::Document;
use base qw/Sdoc::Core::Object/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Node::BridgeHead;
use Sdoc::Node::Code;
use Sdoc::Node::Comment;
use Sdoc::Node::Document;
use Sdoc::Node::Graphic;
use Sdoc::Node::Include;
use Sdoc::Node::Item;
use Sdoc::Node::Link;
use Sdoc::Node::List;
use Sdoc::Node::PageBreak;
use Sdoc::Node::Paragraph;
use Sdoc::Node::Section;
use Sdoc::Node::Table;
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

=item -shellEscape => $bool (Default: 0)

Muss als Option angegeben werden, wenn externe Programme aufgerufen
werden müssen, um das Dokument zu übersetzen.

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
    my $shellEscape = 0;

    Sdoc::Core::Option->extract(\@_,
        -markup => \$markup,
        -quiet => \$quiet,
        -shellEscape => \$shellEscape,
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
        shellEscape => $shellEscape,
    );
    $doc->weaken(root=>$doc); # Verweis auf sich selbst

    # Sdoc-Quelltext in Parsingbaum überführen

    my $lineA = $par->lines;
    while (@$lineA) {
        my ($nodeClass,$variant) = $par->nextType(1);
        $doc->push(childA=>$nodeClass->new($variant,$par,$doc,$doc));
    }

    # Erzeuge TableOfContens-Knoten, wenn 1) Dokument-Option tableOfContents
    # gesetzt ist, 2) kein TableOfContents-Knoten im Baum existiert und
    # 3) es mindestens ein Abschnitt gibt.

    if ($doc->tableOfContents && !$doc->tableOfContentsNode) {
        my $h = $doc->analyze;
        if ($h->sections) {
            my $toc = Sdoc::Node::TableOfContents->Sdoc::Node::new(
                'TableOfContents',0,$doc,$doc,
                maxDepth=>3,
            );
            $doc->unshift(childA=>$toc);
            $doc->set(nodeA=>undef); # forciere neue Knotenliste
        }
    }

    # L-Segmente (Links) auflösen
    $doc->resolveLinks;

    # G-Segmente (Inline-Grafiken) auflösen
    $doc->resolveGraphics;

    return $doc;
}

# -----------------------------------------------------------------------------

=head3 sdoc2ToSdoc3() - Konvertiere Sdoc2-Code in Sdoc3-Code

=head4 Synopsis

    $code = $class->sdoc2ToSdoc3($code);

=head4 Arguments

=over 4

=item $code (String)

Sdoc2-Code

=back

=head4 Returns

Sdoc3-Code (String)

=head4 Description

Wandele Sdoc2-Code in Sdoc3-Code und liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub sdoc2ToSdoc3 {
    my ($class,$code) = @_;

    # %Document
    
    $code =~ s|^( +)utf8=.*\n||m;
    $code =~ s|^( +)generateAnchors=.*\n||m;

    # %Figure

    $code =~ s|%Figure:|%Graphic:|m;
    

    return $code;
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
