package Sdoc::Node::Document;
use base qw/Sdoc::Node/;

use strict;
use warnings;
use utf8;

our $VERSION = 0.01;

use POSIX ();
use Sdoc::Core::Hash;
use Digest::SHA ();

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

Autor des Dokuments.

=item authorS => $str

Autor des Dokuments nach Parsing der Segmente.

=item childA => \@childs

Array der direkten Kind-Knoten.

=item copyComments => $bool (Default: 0)

Kopiere Sdoc-Kommentare in den Quelltext des Zielformats. Dies
ist z.B. nützlich, um eine Stelle im Quelltext des Zielformats zu
finden, die aus einem bestimmten Sdoc-Konstrukt hervorgegangen
ist.

=item date => $date

Datum des Dokuments. today: YYYY-MM-DD, now: YYYY-MM-DD HH:MI:SS,
strftime-Formatelemente werden expandiert.

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

=item language => $language (Default: 'german')

Sprache, in der das Dokument verfasst ist.

=item latexDocumentClass => $documentClass (Default: 'scrartcl')

LaTeX-Dokumentklasse. Werte: 'scrartcl', 'scrreprt', 'scrbook',
'article', 'report', 'book', ...

=item latexFontSize => $fontSize (Default: '10pt')

Größe des LaTeX-Font. Mögliche Werte: '10pt', '11pt', '12pt'.

=item latexGeometry => $str

Einstellungen des LaTeX-Pakets C<geometry>.

=item latexPaperSize => $paperSize (Default: 'a4paper')

Papiergröße für LaTeX.

=item latexParSkip => $length (Default: '0.5ex')

Vertikaler Abstand zwischen Absätzen.

=item linkA => \@links

Array mit den vorkommenden Links aus L-Segmenten der Attribute
C<title>, C<author>, C<date>.

=item linkH => \%nodes

Hash der Link-Knoten. Schlüssel des Hash ist der Name des
Link-Knotens.

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

Dokument-Titel.

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

        if (my $date = $attribH->{'date'}) {
            # Spezielle Datumswerte:
            # * today
            # * now
            # * strftime-Formate werden expandiert

            if ($date eq 'today') {
                # $date = '%d. %B %Y';
            }
            elsif ($date eq 'now') {
                $date = '%Y-%m-%d %H:%M:%S';
            }
            $attribH->{'date'} = POSIX::strftime($date,localtime);
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
        copyComments => 0,
        date => undef,
        dateS => undef,
        formulaA => [],
        graphicA => [],
        language => 'german',
        linkA => [],
        latexDocumentClass => 'scrartcl',
        latexFontSize => '10pt',
        latexGeometry => undef,
        latexPaperSize => 'a4paper',
        latexParSkip => '0.5ex',
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
                $h{$node->name} = $node;
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
        my $path = $node->anchorPathAsString;
        if ($path =~ m|($regex)(?!.*/)|) {
            push @hits,[$node,
                0,
                scalar @{$node->anchorPathAsArray},
            ];
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

=head3 expandPlus() - Expandiere +/ zu Dokumentverzeichnis

=head4 Synopsis

    $strExpanded = $doc->expandPlus($str);

=head4 Arguments

=over 4

=item $str

Pfad oder Kommandozeile.

=back

=head4 Returns

Expandierte Zeichenkette (String)

=head4 Description

Prüfe, ob $str die Zeichenkette C<+/> enthält. Wenn ja, ersetze an
allen Stellen das Pluszeichen durch das Dokumentverzeichnis und
liefere das Resultat zurück.

=cut

# -----------------------------------------------------------------------------

sub expandPlus {
    my ($self,$str) = @_;

    if (defined($str) && $str =~ m|\+/|) {
        # Wir setzen den Pfad des Dokumentverzeichnisses
        # an den Anfang

        my $input = $self->root->input;
        # FIXME: Was tun, wenn der Input aus einem
        # String oder einem Array kommt?
        if (!ref $input) {
            my ($dir) = $input =~ m|(.*)/|;
            if ($dir) {
                $str =~ s|\+/|$dir/|g;
            }
        }
    }

    return $str;
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
    my ($self,$gen) = @_;

    # Dokumentklasse mit Optionen

    my $code .= $gen->comment(-nl=>2,q|
        Generated by Sdoc - DO NOT EDIT!
    |);
    my $documentClass = $self->latexDocumentClass;
    my $fontSize = $self->latexFontSize;
    my $paperSize = $self->latexPaperSize;
    $code .= $gen->cmd('documentclass',
        -o => "$fontSize,$paperSize",
        -p => $documentClass,
        -nl => 2,
    );

    # Packages
    
    $code .= $gen->comment(-nl=>2,q|
        ### inputenc: Zeichensatz der LaTeX-Quelldatei ###
    |);
    $code .= $gen->cmd('usepackage',
        -o => 'utf8',
        -p => 'inputenc',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### babel: Sprache, in der der Text verfasst ist ###
        + Trennregeln
        + Spachspezifische Bezeichnungen wie "Inhaltsverzeichnis" etc.
    |);
    my $language = $self->language;
    if ($language eq 'german') {
        $language = 'ngerman';
    }
    $code .= $gen->cmd('usepackage',
        -o => $language,
        -p => 'babel',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### geometry: Einstellen der Seitenmaße ###
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'geometry',
    );
    if (my $geometry = $self->latexGeometry) {
        $code .= $gen->cmd('geometry',
            -p => $geometry,
        );
    }
    $code .= "\n";
    $code .= $gen->comment(-nl=>2,q|
        ### graphicx: Inkludieren von Grafikdateien ###
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'graphicx',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### longtable: Darstellen von Tabellen ###
        + \LTleft - Default-Linkseinrückung von Tabellen
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'longtable',
    );
    $code .= $gen->cmd('setlength',
        -p => '\LTleft',
        -p => '1.3em',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### array:  Erweiterungen für array- und tabular-Umgebung ###
        * Zusätzliche Höhe für Tabellenzeilen
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'array',
    );
    $code .= $gen->cmd('setlength',
        -p => '\extrarowheight',
        -p => '2pt',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### makecell: Spezielle Tabellenköpfe und mehrzeilige Zellen ###
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'makecell',
        -nl => 2,
    );
    $code .= $gen->cmd('newcommand',
        -p => '\mlCell',
        -o => 3,
        -p => '{\setlength{\fboxsep}{0pt}\colorbox{#1}{\makecell[#2]{#3}}}',
        -nl => 2,
    );
    # Funktioniert nicht. Warum?
    # $code .= $gen->renewcommand('theadfont',
    #     -p => '\itshape\small',
    # );
    # $code .= $gen->renewcommand('theadalign',
    #     -p => 'lb',
    # );
    # $code .= $gen->renewcommand('cellalign',
    #     -p => 'lt',
    # );
    
    $code .= $gen->comment(-nl=>2,q|
        ### etoolbox: Einstellen der Abstände der Verbatim-Umgebung ###
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'etoolbox',
    );
    $code .= $gen->cmd('makeatletter');
    $code .= $gen->cmd('preto',
        -p => '\@verbatim',
        -p => '\topsep=0.5ex \partopsep=1ex',
    );
    $code .= $gen->cmd('makeatother',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### caption: Verbesserte Beschriftungen ###
        + hypcap: Setzt Anker auf *Anfang* der Gleitumgebung
        + singlelinecheck=off,margin=1.3em: Linksbndig, unsere Einrücktiefe
    |);
    $code .= $gen->cmd('usepackage',
        -o => 'hypcap,singlelinecheck=off,margin=1.3em,font={sf,small}'.
            ',labelsep=colon,labelfont=bf,skip=1ex',
        -p => 'caption',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### enumitem: Layout von enumerate, itemize, description ###
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'enumitem',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        ### minted: Syntax-Highlighting von Quellcode ###
    |);
    $code .= $gen->cmd('usepackage',
        -p => 'minted',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        Style für das Highlighting von Perl. Für andere Sprachen kann ein
        anderer Style eingestellt werden. Erweiterung hier.
    |);
    $code .= $gen->cmd('usemintedstyle',
        -o => 'perl',
        -p => 'default',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        Globale Einstellungen für das Paket minted:
        + Größe des Font in Verbatim- und minted-Umgebungen
        + Breite des Leerraums zwischen Zeilennummer und Quelltext
    |);
    $code .= $gen->cmd('fvset',
        -p => 'numbersep=0.8em'.
            ($self->smallerMonospacedFont? ',fontsize=\small': ''),
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        Anpassung des Aussehens der Zeilennummer:
        + Größe des Zeilennummer-Font
        + Formatierung des Zähler-Werts (diese ändern wir nicht, müssen
          diese aber angeben, da sonst keine Zeilennummer ausgegeben wird)
    |);
    $code .= $gen->renewcommand('theFancyVerbLine',
        -p => '\scriptsize\arabic{FancyVerbLine}',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        Wir definieren 8 Längen für die Zeilennummern-Breiten 1 bis 4
        mit und ohne Einrückung.  Eine dieser Längen wählen wir, wenn
        wir einen Code-Abschnitt mit Zeilennummern generieren.
    |);
    for my $c ('a','b','c','d') { # Längen für Verbatim-Einrückung generieren
        my $n = '9' x (ord($c)-96);
        for my $i ('','i') {
            my $name = sprintf('\lnwidth%s%s',$c,$i);
            my $indent = $i? '2.1em': '0.8em';

            $code .= $gen->cmd('newlength',
                -p => $name,
            );
            $code .= $gen->cmd('settowidth',
                -p => $name,
                -p => sprintf('\texttt{\scriptsize %s}',$n),
            );
            $code .= $gen->cmd('addtolength',
                -p => $name,
                -p => $indent,
            );
        }
    }
    $code .= $gen->comment(-preNl=>1,-nl=>2,q|
        ### xcolor: Erweiterte Farbangaben ###
        +  mehr Farbnamen (durch Option dvipsnames)
        + Angabe von RGB-Werten
        Wir nutzen diese Möglichkeiten in Paket hyperref.
    |);
    $code .= $gen->cmd('usepackage',
        -o => 'dvipsnames,table',
        -p => 'xcolor',
    );
    $code .= $gen->cmd('definecolor',
        -p => 'titleColor',
        -p => 'HTML',
        -p => 'e5e5e5',
    );
    $code .= $gen->cmd('definecolor',
        -p => 'dataColor',
        -p => 'HTML',
        -p => 'ffffff',
    );
    $code .= $gen->comment(-nl=>2,q|
        ### hyperref: Hyperlinks in PDF ###
        Dieses Paket soll laut Doku als letztes Paket geladen werden.
        Wir aktivieren farbigen Text (colorlinks=true) anstelle von
        farbigen Boxen.
    |);
    $code .= $gen->cmd('usepackage', # Als letztes Package inkludieren
        -p => 'hyperref',
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        Wir aktivieren farbigen Text (colorlinks=true) anstelle
        von farbigen Boxen. Treten weiter Linktypen auf, erweitern
        wird dies hier.
    |);
    $code .= $gen->cmd('hypersetup',
        -p => 'colorlinks=true,linkcolor=NavyBlue,urlcolor=NavyBlue',
        -nl => 2,
    );

    # Sonstiges

    $code .= $gen->comment(-nl=>2,q|
        ### secNumDepth: Tiefe der Abschnittsnumerierung ###
    |);
    $code .= $gen->comment(-nl=>2,q|
        Tiefe, bis zu der Abschnitte numeriert werden. Default seitens
        LaTeX: 3. -2 schaltet die Numerierung ab.
    |);
    my $secNumDepth = $self->sectionNumberDepth;
    if ($documentClass =~ /book/) {
        $secNumDepth -= 2;
    }
    elsif ($documentClass =~ /rep/) {
        $secNumDepth -= 1;
    }
    $code .= $gen->cmd('setcounter',
        -p => 'secnumdepth',
        -p => $secNumDepth,
        -nl => 2,
    );
    $code .= $gen->comment(-nl=>2,q|
        Tiefe, bis zu der Abschnitte in das Inhaltsverzeichnis
        aufgenommen werden. Default seitens LaTeX: 3.
    |);
    my $toc = $self->tableOfContentsNode;
    if ($toc) {
        $code .= $gen->comment(-nl=>2,q|
            ### tocDepth: Tiefe des Inhaltsverzeichnisses ###
        |);
        my $tocDepth = $toc->maxDepth;
        if ($documentClass =~ /book/) {
            $tocDepth -= 2;
        }
        elsif ($documentClass =~ /rep/) {
            $tocDepth -= 1;
        }
        $code .= $gen->cmd('setcounter',
            -p => 'tocdepth',
            -p => $tocDepth,
        );
    }
    $code .= $gen->comment(-nl=>2,q|
        + Keine Absatz-Einrückung
        + Vertikaler Absatzabstand
        + nachlässiges Spacing erlaubt
    |);
    $code .= $gen->setlength('parindent','0em');
    $code .= $gen->setlength('parskip',$self->latexParSkip);
    $code .= $gen->cmd('sloppy',
        -nl => 2,
    );

    if ($documentClass =~ /^scr/) {
        $code .= $gen->comment(-nl=>2,q|
            Umdefinition des Spacing von \paragraph
        |);
        $code .= $gen->cmd('RedeclareSectionCommand',
            -o => 'afterskip=0.5ex,beforeskip=-1.5ex',
            -p => 'paragraph',
            -nl => 2,
        );
    }

    # Titelseite

    my $title = $self->latexText($gen,'titleS');
    my $author = $self->latexText($gen,'authorS');
    my $date = $self->latexText($gen,'dateS');
    if ($date && $date eq 'today') {
        $date = '\today';
    }

    my $body;
    if ($title || $author || $date) {
        $body .= $gen->comment(-nl=>2,q|
            ### Titel ###
        |);
        $body .= $gen->cmd('title',-p=>$title);
        $body .= $gen->cmd('author',-p=>$author);
        $body .= $gen->cmd('date',-p=>$date);
        $body .= $gen->cmd('maketitle',
            -nl => 2,
        );
    }

    if (!$toc && $self->tableOfContents) {
        # Erzeuge automatisch ein Inhaltsverzeichnis, wenn kein
        # Inhaltsverzeichnis-Knoten vorhanden, aber das
        # Dokument-Attribut tableOfContents gesetzt ist
        $body .= $self->latexTableOfContents($gen);
    }

    # Code der untergeordneten Knoten generieren

    my $childs = $self->generateChilds('latex',$gen);
    if ($childs) {
        $body .= $childs;
    }

    # Beginn des Texts durch Kommentar kennzeichnen. Entweder nach
    # Inhaltsverzeichnis oder nach Titel oder am Anfang.

    if ($body !~ s/^(\{\\hypersetup.*\n\n)/$1% ### Text ###\n\n/m) {
        if ($body !~ s/^(\\maketitle.*\n\n)/$1% ### Text ###\n\n/m) {
            $body =~ s/^(\\begin\{document\}\n\n)/$1% ### Text ###\n\n/m;
        }
    }

    # Document-Umgebung erzeugen
    $code .= $gen->env('document',$body,-nl=>2);

    # Eof-Kennzeichen
    $code .= $gen->comment('eof');

    return $code;
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
