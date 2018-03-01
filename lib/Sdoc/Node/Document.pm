package Sdoc::Node::Document;
use base qw/Sdoc::Node/;

use strict;
use warnings;

our $VERSION = 3.00;

use Sdoc::Core::Hash;
use Digest::SHA ();
use Sdoc::Core::Process;
use Sdoc::Core::LaTeX::Document;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node::Document - Dokument-Knoten

=head1 BASE CLASS

L<Sdoc::Node>

=head1 DESCRIPTION

Der Dokument-Knoten ist der Wurzelknoten des Sdoc-Parsingbaums.

=head1 ATTRIBUTES

Über die Attribute der Basisklasse hinaus besitzt ein
Dokument-Knoten folgende zusätzliche Attribute:

=over 4

=item anchor => undef

Anker des Dokuments.

=item author => $author

Der Autor des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt.

=item authorS => $str

Autor des Dokuments nach Parsing der Segmente.

=item childA => \@childs

Array der direkten Kind-Knoten.

=item copyComments => $bool (Default: 1)

Kopiere Sdoc-Kommentare in den Quelltext des Zielformats. Dies
ist z.B. nützlich, um eine Stelle im Quelltext des Zielformats zu
finden, die aus einem bestimmten Sdoc-Konstrukt hervorgegangen
ist.

=item date => $date

Das Datum des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt. Formatelemente von strftime werden
expandiert. Spezielle Werte:

=over 4

=item today

YYYY-MM-DD

=item now

YYYY-MM-DD HH:MI:SS

=back

=item dateS => $str

Datum des Dokuments nach Parsing der Segmente.

=item formulaA => \@formulas

Array mit den vorkommenden Formeln aus M-Segmenten der Attribute
C<title>, C<author>, C<date>.

=item graphicA => \@graphics

Array mit den vorkommenden Grafiken aus G-Segmenten der Attribute
C<title>, C<author>, C<date>.

=item graphicH => \%nodes

Hash der Grafik-Knoten. Schlüssel des Hash ist der Name des
Grafik-Knotens.

=item indentation => $x (Default: 1.3)

Einrückung für List-, Graphic-, Code-, Table-Blöcke vom linken
Rand. Einheit ist C<em>, die aber nicht angegeben wird.

=item language => $language (Default: 'german')

Sprache, in der das Dokument verfasst ist.

=item latexDocumentClass => $documentClass (Default: 'scrartcl')

LaTeX-Dokumentklasse. Werte: 'scrartcl', 'scrreprt', 'scrbook',
'article', 'report', 'book', ...

=item latexDocumentOptions => $str | \@arr

Optionen der Dokumentklasse. Z.B. 'twoside'.

=item latexFontSize => $fontSize (Default: '10pt')

Größe des LaTeX-Font. Mögliche Werte: '10pt', '11pt', '12pt'.

=item latexGeometry => $str

Einstellungen des LaTeX-Pakets C<geometry>.

=item latexHeadings => $bool (Default: 1)

Erzeuge Kopf- und Fußzeilen.

=item latexPaperSize => $paperSize (Default: 'a4paper')

Papiergröße für LaTeX.

=item latexParSkip => $length (Default: '1ex')

Vertikaler Abstand zwischen Absätzen.

=item latexShowFrames => $bool (Default: 0)

Zeichne den Text-, Kopfzeilen-, Fußzeilen- und Kommentarbereich
in die Seiten ein. Dies ist eine Debugging-Option.

=item linkA => \@links

Array mit den vorkommenden Links aus L-Segmenten der Attribute
C<title>, C<author>, C<date>.

=item linkH => \%nodes

Hash der Link-Knoten. Schlüssel des Hash ist der Name des
Link-Knotens.

=item linkId => $linkId

Der Dokumentanfang ist Ziel eines Link. Dies ist der Anker für
das Zielformat.

=item nodeA => \@nodes (memoize)

Liste aller Knoten des Dokument-Baums.

=item pathNodeA => \@nodes (memoize)

Liste aller Knoten des Dokument-Baums, die einen Pfad besitzen.

=item quiet => $bool (Default: 0)

Gib keine Warnungen aus.

=item sectionNumberDepth => $n (Default: 3)

Tiefe, bis zu welcher Abschnitte
Die Abschnittsebene, bis zu welcher Abschnitte numeriert werden.
Mögliche Werte: 0, 1, 2, 3, 4, 5. 0 = keine Abschnittsnumerierung.

=item shellEscape => $bool (Default: 0)

Muss angegeben werden, wenn externe Programme aufgerufen
werden müssen, um das Dokument zu übersetzen.

=item smallerMonospacedFont => $bool (Default: 0)

Wähle einen kleineren Monospaced Font als standardmäßig.

=item tableOfContents => $bool (Default: 1)

Erzeuge ein Inhaltsverzeichnis, auch wenn kein
Inhaltsverzeichnis-Knoten vorhanden ist.

=item title => $str

Der Titel des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt.

=item titleS => $str

Titel des Dokuments nach Parsing der Segmente.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Dokument-Knoten

=head4 Synopsis

    $doc = $class->new($variant,$par,$root,$parent);

=head4 Arguments

=over 4

=item $par

Parser-Objekt.

=item $variant

Markup-Variante.

=item $root

Wurzelknoten des Parsingbaums.

=item $parent

Eltern-Knoten.

=back

=head4 Returns

Dokument-Knoten (Object)

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$variant,$par,$root,$parent) = @_;

    # Der Dokument-Knoten ist ein Sigleton, das die Wurzel des
    # Parsingbaums bildet. Bei wiederholtem Konstruktoraufruf
    # setzen wir nur die Attribute und liefern kein Objekt.

    if (defined($variant) && $root) {
        # Quelltext verarbeiten

        my $attribH = {};
        if ($variant == 0) {
            # %Document:
            #   KEY=VAL

            $attribH = $par->readBlock;
        }
        else {
            $class->throw;
        }

        $root->setAttributes(variant=>$variant,%$attribH);
        $par->parseSegments($root,'title');
        $par->parseSegments($root,'author');
        $par->parseSegments($root,'date');

        return; # Wir liefern kein Objekt
    }

    # Objekt instantiieren. Da der Dokument-Knoten vorab instantiiert
    # wird, werden Zeilennummer, Variante, Root-Knoten und
    # Parent-Knoten später gesetzt (falls es einen %Document:-Block
    # im Dokument gibt).

    my $self = $class->SUPER::new('Document',$variant,$root,$parent,
        anchor => undef,
        author => undef,
        authorS => undef,
        childA => [],
        copyComments => 1,
        date => undef,
        dateS => undef,
        formulaA => [],
        graphicA => [],
        indentation => 1.3,
        language => 'german',
        latexDocumentClass => 'scrartcl',
        latexDocumentOptions => undef,
        latexFontSize => '10pt',
        latexGeometry => undef,
        latexHeadings => 1,
        latexPaperSize => 'a4paper',
        latexParSkip => '1ex',
        latexShowFrames => 0,
        linkA => [],
        linkId => undef,
        sectionNumberDepth => 3,
        tableOfContents => 1,
        title => undef,
        titleS => undef,
        # memoize
        anchorA => undef,
        graphicH => undef,
        linkH => undef,
        nodeA => undef,
        pathNodeA => undef,
        quiet => 0,
        shellEscape => 0,
        smallerMonospacedFont => 0,
        tocNode => undef,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Analyse

=head3 analyze() - Information über Dokument-Baum

=head4 Synopsis

    $h = $doc->analyze;

=head4 Returns

Hash mit Information über den Dokument-Baum

=head4 Description

Analysiere den Dokument-Baum und liefere das Ergebnis der Analyse
zurück. Die Information wird u.a. genutzt um zu entscheiden,
welche LaTeX-Pakete benötigt werden.

=cut

# -----------------------------------------------------------------------------

sub analyze {
    my $self = shift;

    my $h = Sdoc::Core::Hash->new(
        sections => 0,
        lists => 0,
        tables =>0,
        captions => 0,
        graphics => 0,
        sourceCode => 0,
        verbatim => 0,
        lineNumbers => 0,
        links => 0,
        section4 => 0,
    );

    # Dokument-Eigenschaften ermitteln

    for my $node ($self->nodes) {
        if ($node->type eq 'Section') {
            $h->{'sections'}++;
            if ($node->level == 4) { # LaTeX: \paragraph
                $h->{'section4'}++;
            }
        }
        elsif ($node->type eq 'List') {
            $h->{'lists'}++;
        }
        elsif ($node->type eq 'Table') {
            $h->{'tables'}++;
            if ($node->caption) {
                $h->{'captions'}++;
            }
        }
        elsif ($node->type eq 'Graphic') {
            $h->{'graphics'}++;
            if ($node->caption) {
                $h->{'captions'}++;
            }
        }
        elsif ($node->type eq 'Code') {
            if ($node->lang) {
                $h->{'sourceCode'}++;
            }
            else {
                $h->{'verbatim'}++;
            }
            if ($node->ln) {
                $h->{'lineNumbers'}++;
            }
        }
        if ($node->exists('linkA') && @{$node->linkA}) {
            $h->{'links'}++;
        }
        if ($node->exists('graphicA') && @{$node->graphicA}) {
            $h->{'graphics'}++;
        }
    }

    return $h;
}

# -----------------------------------------------------------------------------

=head2 Knoten

=head3 nodes() - Liste aller Knoten (memoized)

=head4 Synopsis

    @nodes | $nodeA = $doc->nodes;

=head4 Returns

Liste von Knoten. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Knoten des Dokument-Baums.

=cut

# -----------------------------------------------------------------------------

sub nodes {
    my $self = shift;

    my $arr = $self->memoize('nodeA',sub {
        my ($self,$key) = @_;

        my @arr = $self->allNodes;

        # Dokument-Knoten im Array finden und die Referenz zu einer
        # schwachen Referenz machen
        $self->weakenSelfReference(\@arr);

        return \@arr;
    });

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 graphicNode() - Lookup Grafik-Knoten (memoized)

=head4 Synopsis

    $gph = $doc->graphicNode($name);

=head4 Arguments

=over 4

=item $name

Name des Grafik-Knotens.

=back

=head4 Returns

Grafik-Knoten (Sdoc::Node::Graphic) oder C<undef>

=head4 Description

Liefere den Grafik-Knoten mit dem Name $name. Existiert kein
Grafik-Knoten mit diesem Namen, liefere C<undef>.

=cut

# -----------------------------------------------------------------------------

sub graphicNode {
    my ($self,$name) = @_;

    my $h = $self->memoize('graphicH',sub {
        my ($self,$key) = @_;

        my %h;
        for my $node ($self->nodes) {
            # Der Name eines Grafik-Knotens ist optional
            if ($node->type eq 'Graphic' && (my $name = $node->name)) {
                $h{$name} = $node;
            }
        }

        return \%h;
    });

    return $h->{$name};
}

# -----------------------------------------------------------------------------

=head3 linkNode() - Lookup Link-Knoten (memoized)

=head4 Synopsis

    $lnk = $doc->linkNode($name);

=head4 Arguments

=over 4

=item $name

Name des Link-Knotens.

=back

=head4 Returns

Link-Knoten (Sdoc::Node::Link) oder C<undef>

=head4 Description

Liefere den Link-Knoten mit dem Name $name. Existiert kein
Link-Knoten mit diesem Namen, liefere C<undef>.

=cut

# -----------------------------------------------------------------------------

sub linkNode {
    my ($self,$name) = @_;

    my $h = $self->memoize('linkH',sub {
        my ($self,$key) = @_;

        my %h;
        for my $node ($self->nodes) {
            if ($node->type eq 'Link') {
                # Das Namens-Attribut kann mehrere Namen mit |
                # getrennt definieren
                for my $name (split /\|/,$node->name) {
                    $h{$name} = $node;
                }
            }
        }

        return \%h;
    });

    return $h->{$name};
}

# -----------------------------------------------------------------------------

=head3 anchorNodes() - Liste aller Knoten mit Anker (memoized)

=head4 Synopsis

    @nodes | $nodeA = $doc->anchorNodes;

=head4 Returns

Liste von Knoten. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Knoten, die einen Anker besitzen, also das
Ziel eines Link sein können. Diese Knoten sind dadurch
gekennzeichnet, dass sie a) das Attribut C<anchor> besitzen und b)
dieses einen Wert hat.

=cut

# -----------------------------------------------------------------------------

sub anchorNodes {
    my $self = shift;

    my $arr = $self->memoize('pathNodeA',sub {
        my ($self,$key) = @_;

        my @arr;
        for my $node ($self->nodes) {
            if ($node->exists('anchor') && defined $node->anchor) {
                push @arr,$node;
            }
        }

        # Dokument-Knoten im Array finden und die Referenz zu einer
        # schwachen Referenz machen
        $self->weakenSelfReference(\@arr);

        return \@arr;
    });

    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 graphicContainingNodes() - Liste aller Knoten mit G-Segmenten

=head4 Synopsis

    @nodes | $nodeA = $doc->graphicContainingNodes;

=head4 Returns

Liste von Knoten. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Knoten, die mindestens ein G-Segment
enthalten, also auf mindestens einen Grafik-Knoten
verweisen. Diese Knoten sind dadurch gekennzeichnet, dass sie a)
das Attribut C<graphicA> besitzen und b) dieses Array mindestens
einen Eintrag hat.

=cut

# -----------------------------------------------------------------------------

sub graphicContainingNodes {
    my $self = shift;

    my @arr;
    for my $node ($self->nodes) {
        if ($node->exists('graphicA') && @{$node->graphicA}) {
            push @arr,$node;
        }
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 linkContainingNodes() - Liste aller Knoten mit Links

=head4 Synopsis

    @nodes | $nodeA = $doc->linkContainingNodes;

=head4 Returns

Liste von Knoten. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Knoten, die mindestens einen Link
enthalten, also auf mindestens einen anderen Knoten
verweisen. Diese Knoten sind dadurch gekennzeichnet, dass sie a)
das Attribut C<linkA> besitzen und b) dieses Array mindestens
einen Eintrag hat.

=cut

# -----------------------------------------------------------------------------

sub linkContainingNodes {
    my $self = shift;

    my @arr;
    for my $node ($self->nodes) {
        if ($node->exists('linkA') && @{$node->linkA}) {
            push @arr,$node;
        }
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 tableOfContentsNode() - Lookup TableOfContents-Knoten

=head4 Synopsis

    $toc = $doc->tableOfContentsNode;

=head4 Returns

TableOfContents-Knoten (Sdoc::Node::TableOfContents) oder
C<undef>

=head4 Description

Liefere den TableOfContents-Knoten, falls vorhanden, oder
C<undef>.

=cut

# -----------------------------------------------------------------------------

sub tableOfContentsNode {
    my $self = shift;

    for my $node ($self->nodes) {
        if ($node->type eq 'TableOfContents') {
            return $node;
        }
    }

    return undef;
}

# -----------------------------------------------------------------------------

=head2 Anker

=head3 anchor() - Anker des Dokuments

=head4 Synopsis

    $anchor = $sec->anchor;

=head4 Returns

Anker (String)

=head4 Description

Liefere den Wert des Attributs C<anchor>. Falls dies keinen Wert
hat, liefere den Wert des Attributs C<title>.

=cut

# -----------------------------------------------------------------------------

sub anchor {
    my $self = shift;
    return $self->get('anchor') || $self->title;
}

# -----------------------------------------------------------------------------

=head2 Links

=head3 resolveLinks() - Löse alle Links im Dokument auf

=head4 Synopsis

    $doc->resolveLinks;

=head4 Description

Die Methode wird automatisch gerufen, wenn der Parsingbaum
vollständig aufgebaut ist. Erst dann können die (internen) Links
des Dokuments aufgelöst werden. Die Link-Auflösung erledigt diese
Methode für alle Links des Dokuments.

Für jeden Link wird als Resultat der Link-Auflösung ein Objekt
in das Link-Array C<linkA> des Knotens, in dem sich der Link befindet,
eingetragen. Das Objekt besitzt die Attribute:

=over 4

=item type

Festgestellter Typ des Links als Resultat der Linkanalyse.
Mögliche Werte: 'internal', 'external', 'unresolved'.

=item destText

Im Falle eines externen Link das Linkziel als Text (URL).

=item destNode

Im Falle eines internen Link eine Referenz auf den Zielknoten.

=item text

Der Link-Text, der dem Leser angezeigt wird.

=item attribute

Optionales Linkattribut. Linkattribute stehen im Quelltext am
Anfang des Link-Textes, werden intern entfernt. Einziger
aktuell möglicher Wert: '+'.

=item linkNode

Findet die Linkauflösung über einen Link-Knoten statt, wird hier
eine Referenz auf den Link-Knoten eingetragen.

=item subType

Weg, auf dem der Link über den Link-Knoten aufgelöst wurde.
Mögliche Werte: 'regex', 'file', 'url'.

=back

Das Link-Array C<linkA> des Knotens wird während des Parsings von
der Methode $par->parseSegments() aufgebaut.

=cut

# -----------------------------------------------------------------------------

sub resolveLinks {
    my $self = shift;

    for my $srcNode ($self->linkContainingNodes) {
        for my $e (@{$srcNode->linkA}) {
            my $linkText = $e->[0];
            $linkText =~ s/[\n\t]/ /g;
            $linkText =~ s/  +/ /g;

            # Ein etwaiges Link-Attribut entfernen wir hier
            (my $text = $linkText) =~ s/^([+])?//;
            my $attribute = $1 // '';

            if ($text =~ m{^(https?://|mailto:)}) {
                # Unmittelbare Referenz auf eine externe Resource

                $e->[1] = Sdoc::Core::Hash->new(
                    type => 'external',
                    destText => $text,
                    destNode => undef,
                    text => $text,
                    attribute => $attribute,
                    linkNode => undef,
                    subType => undef,
                );

                next;
            }

            # Lookup des (optionalen) Link-Knotens 
            my $lnk = $self->linkNode($text);
            
            my @nodes;
            if (!$lnk) {
                # Es gibt keinen Link-Knoten mit dem Namen $text.
                # Wir nutzen $text als Regex zur Suche des
                # Zielknotens. Der Regex wird auf die Anker der
                # Blattknoten angewendet, nicht auf den gesamten
                # Pfad, wenn er keinen Slash (/) enthält.
                @nodes = $self->findDestNodes($srcNode,qr/\Q$text/);
            }
            else {
                if (my $regex = $lnk->regex) {
                    @nodes = $self->findDestNodes($srcNode,qr/$regex/);
                }
            }
            if (@nodes > 1) {
                $srcNode->warn("Can't resolve link uniquely: L{%s}",$linkText);
                for my $node (@nodes) {
                    $node->warn('>> %s',$node->anchorPathAsString);
                }
            }
            my $node = $nodes[0]; # ein oder kein Zielknoten
            if (!$lnk) {
                if (!$node) {
                    $srcNode->warn("Can't resolve link: L{%s}",$linkText);
                    $e->[1] = Sdoc::Core::Hash->new(
                        type => 'unresolved',
                        destText => undef,
                        destNode => undef,
                        text => undef,
                        attribute => $attribute,
                        linkNode => undef,
                        subType => undef,
                    );
                }
                else {
                    $e->[1] = Sdoc::Core::Hash->new(
                        type => 'internal',
                        destText => undef,
                        destNode => $node,
                        text => $text,
                        attribute => $attribute,
                        linkNode => undef,
                        subType => undef,
                    );
                    $e->[1]->weaken('destNode');
                    $node->set(linkId=>Digest::SHA::sha1_base64(
                        $node->anchorPathAsString));
                }
                next;
            }

            # Es gibt einen Link-Knoten. Wir kennzeichnen den
            # Link-Knoten als genutzt und probieren die verschiedenen
            # Link-Ziele durch.

            $lnk->increment('useCount');

            if ($node) {
                $e->[1] = Sdoc::Core::Hash->new(
                    type => 'internal',
                    destText => undef,
                    destNode => $node,
                    text => $text,
                    attribute => $attribute,
                    linkNode => $lnk,
                    subType => 'regex',
                );
                $e->[1]->weaken('destNode');
                $node->set(linkId=>Digest::SHA::sha1_base64(
                    $node->anchorPathAsString));
                next;
            }
            if (my $file = $lnk->file) {
                # FIXME: Existenz der Datei prüfen
                $e->[1] = Sdoc::Core::Hash->new(
                    type => 'external',
                    destText => $file,
                    destNode => undef,
                    text => $text,
                    attribute => $attribute,
                    linkNode => $lnk,
                    subType => 'file',
                );
                next;
            }
            if (my $url = $lnk->url) {
                # FIXME: Existenz des URL prüfen
                $e->[1] = Sdoc::Core::Hash->new(
                    type => 'external',
                    destText => $url,
                    destNode => undef,
                    text => $text,
                    attribute => $attribute,
                    linkNode => $lnk,
                    subType => 'url',
                );
                next;
            }

            # Der Link konnte über den Link-Knoten intern nicht
            # aufgelöst werden und externe Resourcen sind bei dem
            # Link-Knoten nicht angegeben. Also ist die
            # Link-Auflösung fehlgeschlagen.

            $srcNode->warn("Can't resolve link: L{%s}",$linkText);
            $e->[1] = Sdoc::Core::Hash->new(
                type => 'unresolved',
                destText => undef,
                destNode => undef,
                text => undef,
                attribute => $attribute,
                linkNode => undef,
                subType => undef,
            );
        }
    }

    # Prüfe, ob alle Link-Knoten genutzt wurden. Warne ungenutzte Knoten an.

    for my $node ($self->nodes) {
        if ($node->type eq 'Link' && $node->useCount == 0) {
            $node->warn('Link node not used: name="%s"',$node->name);
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 resolveGraphics() - Löse alle G-Segmente im Dokument auf

=head4 Synopsis

    $doc->resolveGraphics;

=head4 Description

Die Methode wird automatisch gerufen, wenn der Parsingbaum
vollständig aufgebaut ist. Erst dann können die Verweise von
G-Segmenten auf Grafik-Knoten aufgelöst werden. Diese Auflösung
erledigt diese Methode für alle G-Segmente des Dokuments.

=cut

# -----------------------------------------------------------------------------

sub resolveGraphics {
    my $self = shift;

    # Finde die Grafik-Knoten zu den G-Segmenten

    for my $srcNode ($self->graphicContainingNodes) {
        for my $e (@{$srcNode->graphicA}) {
            my $name = $e->[0];
            my $gph = $self->graphicNode($name);
            if (!$gph) {
                $srcNode->warn("Graphic not found: G{%s}",$name);
                next;
            }
            $e->[1] = $gph;
            $gph->increment('useCount');
        }
    }

    # Prüfe, ob alle Grafik-Knoten, die mit definition=1 deklariert
    # sind, genutzt wurden. Warne ungenutzte Knoten an.

    for my $node ($self->nodes) {
        if ($node->type eq 'Graphic' && $node->definition &&
                $node->useCount == 0) {
            $node->warn('Graphic node not used: name="%s"',$node->name // '');
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 findDestNodes() - Suche Zielknoten zu internem Link

=head4 Synopsis

    @nodes | $nodeA = $doc->findDestNodes($srcNode,$regex);

=head4 Arguments

=over 4

=item $srcNode

Ausgangsknoten, der den Link enthält

=item $regex

Regulärer Ausdruck, der den Zielknoten (nicht notwendigerweise
eindeutig) identifiziert.

=back

=head4 Returns

Liste von Knoten. Im Skalarkontext wird eine Referenz auf die Liste
geliefert.

=head4 Description

Suche unter allen Knoten des Syntaxbaums, die einen Anker-Pfad
besitzen, die nächstgelegenen passenden Knoten nach folgendem
Verfahren:

=over 4

=item 1.

Bestimme die Menge aller Knoten, deren Anker-Pfad (als String)
den Regex $regex matcht.

=item 2.

Schränke die Menge aus Schritt 1. auf die Knoten ein, die den
längsten gemeinsamen Pfadanfang (gemessen in der Anzahl
Pfad-Komponenten) mit Ausgangsknoten $node besitzen.

=item 3.

Schränke die Mange aus Schritt 2. weiter auf die Knoten ein,
deren Anker-Pfad die kürzeste Gesamtlänge (ebenfalls gemessen
in der Anzahl Pfad-Komponenten) besitzt.

=back

Im Normalfall bleibt genau ein Knoten übrig. Dies ist aber nicht
garantiert, daher liefert die Methode eine Liste von Knoten.
Der Aufrufer muss entscheiden, wie er mit dieser Mehrdeutigkeit
umgeht.

=cut

# -----------------------------------------------------------------------------

sub findDestNodes {
    my ($self,$srcNode,$regex) = @_;

    # Trefferliste @hits besteht aus Elementen der Art
    #
    #     [$node,$matchCount,$pathLength]
    #
    # $node       [0] Potentieller Zielknoten
    # $matchCount [1] Anzahl der Übereinstimmenden Komponenenten am Pfadanfang
    # $pathLength [2] Gesamtzahl der Komponenten des Pfads

    my @hits;
    for my $node ($self->anchorNodes) {
        if ($node == $srcNode) {
            next;
        }

        # (*) Wir stellen sicher, dass der Regex wenigstens
        # einen Teil des terminalen Knotens matcht

        my @arr = split /$regex/,$node->anchorPathAsString,-1;
        if (@arr >= 2) {
            my $pathA = $node->anchorPathAsArray;
            if (length($arr[-1]) < length($pathA->[-1])) { # (*)
                push @hits,[$node,
                    0,
                    scalar @$pathA,
                ];
            }
        }
    }

    # Trefferliste auswerten

    if (!@hits) {
        # Kein Knoten gefunden: Wir liefern undef.
        return undef;
    }
    elsif (@hits > 1) {
        # Mehr als einen Knoten gefunden

        # Wenn der Ausgangsknoten keinen Anker-Pfad besitzt, wie dies
        # bei einem Paragraph typischerweise der Fall ist, nehmen wir den
        # Anker-Pfad des ersten Eltern-Knotens, der einen Anker-Pfad
        # besitzt.

        my $anchor1A;
        my $node = $srcNode;
        while ($node) {
            $anchor1A = $node->anchorPathAsArray;
            if (@$anchor1A) {
                last;
            }
            $node = $node->parent;
        }

        # Wir ermitteln den am "dichtesten" liegenden Knoten

        for my $e (@hits) {
            my $anchor2A = $e->[0]->anchorPathAsArray;
            for (my $i = 0; $i < @$anchor1A; $i++) {
                my $anchor1 = $anchor1A->[$i];
                my $anchor2 = $anchor2A->[$i];
                if (!defined($anchor2) || $anchor2 ne $anchor1) {
                    # Differenz oder eine weitere Ankerpfad-Komponente
                    last;
                }
                $e->[1]++; # Anzahl Übereinstimmungen erhöhen
            }
        }

        # Trefferliste so sortieren, dass die besten Treffer oben
        # stehen. Die besten Treffer haben die größte Anzahl an
        # Übereinstimmungen am Pfadanfang und die kürzeste Gesamtlänge.
        # Alle anderen Trefferlisten-Elemente entfernen wir.

        @hits = sort {$b->[1] <=> $a->[1] || $a->[2] <=> $b->[2]} @hits;
        for (my $i = 1; $i < @hits; $i++) {
            if ($hits[0][1] != $hits[$i][1] || $hits[0][2] != $hits[$i][2]) {
                $#hits = $i-1; # Array auf beste gleichwertige Knoten kürzen
            }
        }
    }
    
    my @nodes = map {$_->[0]} @hits;
    return wantarray? @nodes: \@nodes;
}

# -----------------------------------------------------------------------------

=head2 Pfade

=head3 expandPath() - Expandiere Pfad

=head4 Synopsis

    $absPath = $doc->expandPath($path);

=head4 Arguments

=over 4

=item $path

Pfad oder Kommandozeile.

=back

=head4 Returns

Expandierte Zeichenkette (String)

=head4 Description

Prüfe, ob $path die Zeichenkette C<+/> enthält. Wenn ja, ersetze an
allen Stellen das Pluszeichen durch das Dokumentverzeichnis.

=cut

# -----------------------------------------------------------------------------

sub expandPath {
    my ($self,$path) = @_;

    if (!defined $path) {
        return undef;
    }

    if ($path =~ m|\+/|) {
        # Setze den Pfad des Dokumentverzeichnisses an den Anfang

        my $input = $self->root->input;
        # FIXME: Was tun, wenn der Input aus einem
        # String oder einem Array kommt?
        if (!ref $input) {
            my ($dir) = $input =~ m|(.*)/|;
            if ($dir) {
                $path =~ s|\+/|$dir/|g;
            }
        }
    }
    # FIXME: Funktioniert nicht, wenn ein Programm wie grep
    #        aufgerufen wird
    # if (substr($path,0,1) ne '/') {
    #     # Mache Pfad zu absolutem Pfad
    #     $path = sprintf '%s/%s',Sdoc::Core::Process->cwd,$path;
    # }

    return $path;
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 latex() - Generiere LaTeX-Code

=head4 Synopsis

    $code = $doc->latex($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latex {
    my ($self,$l) = @_;

    my $documentClass = $self->latexDocumentClass;
    my $headings = $self->latexHeadings;
    my $smallerMonospacedFont = $self->smallerMonospacedFont;
    my $showFrames = $self->latexShowFrames;

    my $secNumDepth = $self->sectionNumberDepth;
    if ($documentClass =~ /book/) {
        $secNumDepth -= 2;
    }
    elsif ($documentClass =~ /rep/) {
        $secNumDepth -= 1;
    }

    my $tocDepth;
    my $toc = $self->tableOfContentsNode;
    if ($toc) {
        $tocDepth = $toc->maxDepth;
        if ($documentClass =~ /book/) {
            $tocDepth -= 2;
        }
        elsif ($documentClass =~ /rep/) {
            $tocDepth -= 1;
        }
    }

    # Dokumenteigenschaften ermitteln
    my $h = $self->analyze;

    # Pakete laden und Einstellungen vornehmen

    my (@packages,@preamble);
    if ($h->sections && $headings) {
        push @packages,
            lastpage => 1, # für Seitenangabe
        ; 
        push @preamble,
            # Hilfsmakro \nolink zur Unterdrückung eines Link
            $l->comment('no link'),
            $l->c('\newcommand*{\nolink}[1]{'.
                '{\protect\NoHyper#1\protect\endNoHyper}}'),
        ;

        # MEMO: Für eine Trennlinie über der Fußzeile die Zeilen
        # unten einkommentieren.

        if (1) {
            # Für Kopf- und Fußzeilen scrlayer-scrpage nutzen

            push @packages,
                'scrlayer-scrpage' => 1, # KOMA headings
            ; 
            push @preamble,
                # Für eine Linie über der Fußzeile zu den KOMAoptions
                # 'footsepline' hinzufügen und '\ModifyLayer[addvoffset=
                # -LENGTH]{scrheadings.foot.above.line}'

                $l->comment('scrlayer-scrpage'),
                $l->c('\KOMAoptions{automark,autooneside=false,headsepline}'),
                $l->c('\pagestyle{scrheadings}'),
                $l->c('\automark[subsection]{section}'),
                $l->c('\ihead{\MakeUppercase{\leftfirstmark}}'),
                $l->c('\chead{}'),
                $l->c('\ohead{\ifstr{\leftfirstmark}{\rightfirstmark}{}'.
                    '{\rightfirstmark}}'),
                #$l->c('\KOMAoptions{footsepline}'),
                #$l->c('\ModifyLayer[addvoffset=-0.5ex]'.
                #    '{scrheadings.foot.above.line}'),
                $l->c('\cfoot{\emph{\thepage/\nolink{\pageref{LastPage}}}}'),
            ;
        }
        else {
            # Für Kopf- und Fußzeilen fancyhdr nutzen

            push @packages,
                fancyhdr => 1, # bessere Kopf- und Fußzeilen
                scrbase => 1, # KOMA-Script Hilfsklasse mit \ifstr (s.u.)
            ; 
            push @preamble,
                $l->comment('fancyhdr'),
                $l->c('\pagestyle{fancy}'),
                $l->c('\lhead{\MakeUppercase{\textit{\leftmark}}}'),
                $l->c('\rhead{\ifstr{\leftmark}'.
                    '{\rightmark}{}{\textit{\rightmark}}}'),
                # $l->c('\renewcommand{\footrulewidth}{0.4pt}'),
                $l->c('\cfoot{\thepage/\nolink{\pageref{LastPage}}}'),
            ;
        }
    }
    if ($h->lists) {
        push @packages,
            enumitem => 1, # Ersatz für itemize, enumerate, description
        ;
    }
    if ($h->tables) {
        push @packages,
            longtable => 1, # umbrechbare Tabellen
            array => 1, # Erweiterung array-Umgebung
            makecell => 1, # mehrzeilige Kolumnen in Tabellen
        ;
        push @preamble,        
            $l->comment('longtable/array'),
            # * zusätzliche Höhe für Tabellenzellen
            $l->c('\setlength{\extrarowheight}{2pt}'),
        ;
    }
    if ($h->graphics) {
        push @packages,
            graphicx => 1, # Grafiken
            float => 1, # besseres Float Environment
        ;
    }
    if ($h->tables || $h->links || $toc) {
       push @packages,
            xcolor => [ # Farben
                'table',
                'dvipsnames',
            ],
       ;       
    }
    if ($h->captions) {
        push @packages,
            caption => 1,
        ;
        push @preamble,        
            $l->comment('caption'),
            # * Fonteinstellungen
            # * Abstand zw. Objekt und Beschriftung
            $l->c('\captionsetup{%s}',[
                'font={sf,small}',
                'labelsep=colon',
                'labelfont=bf',
                'skip=1.5ex',
            ]),
        ;
    }
    if ($h->sourceCode) {
        push @packages,
            minted => 1, # Syntax Highligheting
        ;
        push @preamble,
            $l->comment('languages syntax highlighting'),
            # Style für das Highlighting von Perl. Für andere Sprachen
            # kann ein anderer Style eingestellt werden. Erweiterung hier.
            $l->c('\usemintedstyle[perl]{default}'),
        ;
    }
    elsif ($h->verbatim) {
        push @packages,
            fancyvrb => 1, # Literaler Text
        ;
    }
    if ($smallerMonospacedFont && ($h->sourceCode || $h->verbatim)) {
        push @preamble,
            $l->comment('smaller monospaced font'),
            # * Größe des Font in Verbatim- und minted-Umgebungen (optional)
            $l->c('\fvset{fontsize=\small}');
        ;
    }

    if ($h->lineNumbers) {
        push @preamble,
            $l->comment('line numbers'),
            # * Breite des Leerraums zw. Zeilennummer und Quelltext
            $l->c('\fvset{numbersep=0.8em}'),
            # * Größe des Zeilennummer-Font
            # * Formatierung des Zähler-Werts (diese ändern wir nicht,
            #   müssen sie aber mit angeben, da sonst keine Zeilennummer
            #   ausgegeben wird)
            $l->c('\renewcommand{%s}{%s}','\theFancyVerbLine',
                '\scriptsize\arabic{FancyVerbLine}'),
            # * 8 Längen für die Zeilennummern-Breiten 1 bis 4,
            #   mit und ohne Einrückung.
            do {
                my $code;
                for my $c ('a','b','c','d') {
                    my $n = '9' x (ord($c)-96);
                    for my $i ('','i') {
                        my $name = sprintf('\lnwidth%s%s',$c,$i);
                        my $indent = $i? '2.1em': '0.8em';

                        $code .= $l->c('\newlength{%s}',$name);
                        $code .= $l->c('\settowidth{%s}'.
                            '{\texttt{\scriptsize %s}}',$name,$n);
                        $code .= $l->c('\addtolength{%s}{%s}',$name,$indent);
                    }
                }
                $code;
            },
        ;
    }
    if ($toc || $h->links) {
        push @packages,
            varioref => 1, # intelligente Verweise
            hyperref => 1, # Verlinkung (laut Doku als letztes Paket laden)
        ;
        push @preamble,
            $l->comment('hyperref'),
            $l->c('\hypersetup{%s}',[
                'colorlinks=true',
                'linkcolor=NavyBlue',
                'urlcolor=NavyBlue',
            ]),
        ;
    }
    if ($showFrames) {
        push @packages,
            showframe => 1, # Kennzeichnung Seitenbereiche
        ;
    }
    if ($documentClass =~ /^scr/ && $h->section4) {
        push @preamble,
            # * \paragraph umdefinieren
            $l->c('\RedeclareSectionCommand[%s]{paragraph}',[
                'afterskip=0.5ex',
                'beforeskip=-1.5ex',
            ]);
        ;
    }

    return Sdoc::Core::LaTeX::Document->latex($l,
        documentClass => $documentClass,
        options => $self->latexDocumentOptions,
        paperSize => $self->latexPaperSize,
        geometry => $self->latexGeometry,
        fontSize => $self->latexFontSize,
        title => $self->latexText($l,'titleS') // '',
        author => $self->latexText($l,'authorS') // '',
        date => $self->latexText($l,'dateS') // '',
        secNumDepth => $h->sections? $secNumDepth: undef,
        tocDepth => $tocDepth,
        parSkip => $self->latexParSkip,
        preComment => 'Generated by Sdoc - DO NOT EDIT!',
        packages => \@packages,
        preamble => \@preamble,
        body => $self->generateChilds('latex',$l),
    );
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
