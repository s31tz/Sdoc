package Sdoc::Node::Document;
use base qw/Sdoc::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '3.00';

use Sdoc::Core::Hash;
use Sdoc::Node::TableOfContents;
use Sdoc::Core::Path;
use Sdoc::Core::Process;
use Sdoc::Core::Time;
use Sdoc::Core::Css;
use Sdoc::Core::Html::Page;
use POSIX ();
use Sdoc::Core::LaTeX::Document;
use Sdoc::Core::Record;

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

=item anchor => $str

Anker des Dokuments.

=item firstAppendixSection => $sec

Erster Abschnitt, der zum Appendix gehört. Das Attribut wird
von der Methode $doc->flagSectionsAsAppendix() gesetzt.

=item author => $author

Der Autor des Dokuments. Wenn gesetzt, wird eine Titelseite bzw.
ein Titelabschnitt erzeugt.

=item authorS => $str

Autor des Dokuments nach Parsing der Segmente.

=item childA => \@childs

Array der direkten Kind-Knoten.

=item codeStyle => $style

Der Style, in dem das Syntax-Highlighting erfolgt, wenn in einem
Code-Block das Attribut C<lang> gesetzt ist. Die Liste der
verfügbaren Styles liefert das Kommando

  $ pygmentize -L styles

=item cssPrefix => $prefix

Der Präfix, der den CSS-Klassen des Dokuments vorangestellt wird.

=item configH => $conf

Referenz auf ein Objekt der Klasse Sdoc::Core::Hash, das
die Werte einer Konfigurationsdatei enthält.

=item copyComments => $bool (Default: 1)

Kopiere Sdoc-Kommentare in den Quelltext des Zielformats. Dies
ist z.B. nützlich, um eine Stelle im Quelltext des Zielformats zu
finden, die aus einem bestimmten Sdoc-Konstrukt hervorgegangen
ist.

=item countCode => $n (Default: 0)

Anzahl der Code-Knoten. Der Wert wird während des Parsings
hochgezählt.

=item countGraphic => $n (Default: 0)

Anzahl der Graphic-Knoten. Der Wert wird während des Parsings
hochgezählt.

=item countList => $n (Default: 0)

Anzahl der List-Knoten. Der Wert wird während des Parsings
hochgezählt.

=item countTable => $n (Default: 0)

Anzahl der Tabellen-Knoten. Der Wert wird während des Parsings
hochgezählt.

=item cssPrefix => $name (Default: 'sdoc')

Präfix für die CSS-Klassen des Dokuments.

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

=item doneNumberSections => $bool (memoize)

Kennzeichen, dass alle Abschnitte durchnummeriert wurden. Wird von
der Methode numberSections() gesetzt.

=item formulaA => \@formulas

Array mit den vorkommenden Formeln aus M-Segmenten der Attribute
C<title>, C<author>, C<date>.

=item graphicA => \@graphics

Array mit den vorkommenden Grafiken aus G-Segmenten der Attribute
C<title>, C<author>, C<date>.

=item graphicH => \%nodes

Hash der Grafik-Knoten. Schlüssel des Hash ist der Name des
Grafik-Knotens.

=item highestSectionLevel => $n (memoize)

Die Ebenennummer der höchsten Abschnittsebene des Dokuments.
Wird von der Methode highestSectionLevel() gesetzt.

=item htmlDocumentStyle => $name (Default: 'default')

Der Name des CSS-Stylesheet, das für das Design des HTML-Dokuments
verwendet wird.

=item htmlIndentation => $n (Default: 20)

In HTML die Tiefe der Einrückung für List-, Graphic-, Code-,
Table-Blöcke vom linken Rand, wenn diese eingerückt werden
sollen. Das Maß wird einheitenlos in Pixel angegeben.

=item indentMode=BOOL (Default: 0)

Wenn gesetzt, werden alle Code-, Graphic-, List- und Table-Blöcke,
für die nichts anderes angegeben ist, eingerückt dargestellt.

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

=item latexIndentation => $x (Default: 11.5)

In LaTeX die Tiefe der Einrückung für Code-, Graphic-, List- und
Table-Blöcke vom linken Rand, wenn diese eingerückt werden
sollen. Einheit ist C<pt>, die aber nicht angegeben wird.

=item latexPageStyle => "$titlePage,$otherPages" (Default: "plain,headings")

Definiere den Seitenstil der Titelseite und der sonstigen Seiten.
Der Seitenstil legt fest, was im Kopf und im Fuß der Seite erscheint.
Zur Verfügung stehen die Seitenstil-Bezeichnungen 'empty' (Kopf-
und Fußzeile leer), 'plain' (nur Fuß mit Seitennummer), 'headings'
(Kopf mit Abschnittstiteln, Fuß mit Seitennummer). Ist lediglich ein
Seitenstil angegeben, gilt dieser für alle Seiten. Beispiel:

  latexPageStyle="empty"

ist identisch zu

  latexPageStyle="empty,empty"

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

=item linkId => $str (memoize)

Berechneter SHA1-Hash, unter dem der Knoten von einem
Verweis aus referenziert wird.

=item nodeA => \@nodes (memoize)

Liste aller Knoten des Dokument-Baums.

=item pathNodeA => \@nodes (memoize)

Liste aller Knoten des Dokument-Baums, die einen Pfad besitzen.

=item quiet => $bool (Default: 0)

Gib keine Warnungen aus.

=item referenced => $n (Default: 0)

Das Dokument ist $n Mal Ziel eines Link. Zeigt an,
ob für das Dokument ein Anker erzeugt werden muss.

=item sectionNumberLevel => $n (Default: 3)

Abschnittsebene, bis zu welcher Abschnitte nummeriert werden.
Mögliche Werte: -2, -1, 0, 1, 2, 3, 4, 5, 6,  wobei das Maximum
vom Zielformat abhängt (LaTeX: 4, HTML: 6). -2 = keine
Abschnittsnummerierung.

=item sectionA => \@sections (memoize)

Liste aller Abschnitts-Knoten.

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

=item userH => $opt

Referenz auf ein Objekt der Klasse Sdoc::Core::Hash, das
Aufruf-Optionen des Benutzers enthält.

=back

=cut

# -----------------------------------------------------------------------------

our $Abbrev = 'doc';

# -----------------------------------------------------------------------------

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

        my $pageStyle = $root->latexPageStyle;
        if (index($pageStyle,',') < 0) {
            # Ist nur ein Seitenstil angegeben, übertragen wir
            # ihn auf alle Seiten
            $root->set(latexPageStyle=>"$pageStyle,$pageStyle");
        }

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
        codeStyle => undef, # User, Attribute, Config, Default
        configH => undef,
        copyComments => 1,
        countCode => 0,
        countGraphic => 0,
        countList => 0,
        countTable => 0,
        cssPrefix => 'sdoc3', # User, Attribute, Config, Default
        date => undef,
        dateS => undef,
        firstAppendixSection => undef,
        formulaA => [],
        graphicA => [],
        htmlDocumentStyle => 'default',
        htmlIndentation => 20,
        indentMode => 0,
        language => 'german',
        latexDocumentClass => 'scrartcl',
        latexDocumentOptions => undef,
        latexFontSize => '10pt',
        latexGeometry => undef,
        latexIndentation => 11.5,
        latexPageStyle => "plain,headings",
        latexPaperSize => 'a4paper',
        latexParSkip => '1ex',
        latexShowFrames => 0,
        linkA => [],
        quiet => 0,
        referenced => 0,
        sectionNumberLevel => 3,
        shellEscape => 0,
        smallerMonospacedFont => 0,
        tableOfContents => 1,
        title => undef,
        titleS => undef,
        userH => undef,
        # memoize
        anchorA => undef,
        attributeH => undef,
        doneNumberSections => undef,
        graphicH => undef,
        highestSectionLevel => undef,
        linkH => undef,
        linkId => undef,
        nodeA => undef,
        pathNodeA => undef,
        sectionA => undef,
        segmentH => undef,
        tocNode => undef,
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Analyse

=head3 analyze() - Information über Dokument-Baum (memoize)

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

    my $att = $self->memoize('attributeH',sub {
        my ($self,$key) = @_;

        my $att = Sdoc::Core::Hash->new(
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
            quotes => 0
        );

        # Dokument-Eigenschaften ermitteln

        for my $node ($self->nodes) {
            if ($node->type eq 'Section') {
                $att->{'sections'}++;
                if ($node->level == 4) { # LaTeX: \paragraph
                    $att->{'section4'}++;
                }
            }
            elsif ($node->type eq 'List') {
                $att->{'lists'}++;
            }
            elsif ($node->type eq 'Table') {
                $att->{'tables'}++;
                if ($node->caption) {
                    $att->{'captions'}++;
                }
            }
            elsif ($node->type eq 'Graphic') {
                $att->{'graphics'}++;
                if ($node->caption) {
                    $att->{'captions'}++;
                }
            }
            elsif ($node->type eq 'Quote') {
                $att->{'quotes'}++;
            }
            elsif ($node->type eq 'Code') {
                if ($node->lang) {
                    $att->{'sourceCode'}++;
                }
                else {
                    $att->{'verbatim'}++;
                }
                if ($node->ln) {
                    $att->{'lineNumbers'}++;
                }
            }
            if ($node->exists('linkA') && @{$node->linkA}) {
                $att->{'links'}++;
            }
            if ($node->exists('graphicA') && @{$node->graphicA}) {
                $att->{'graphics'}++;
            }
        }

        return $att;
    });

    return $att;
}

# -----------------------------------------------------------------------------

=head2 Knoten

=head3 nodes() - Liste aller Knoten (memoized)

=head4 Synopsis

  @nodes | $nodeA = $doc->nodes;

=head4 Returns

Liste von Knoten. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste aller Knoten des Dokument-Baums, einschließlich
des Dokument-Knotens.

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

=head3 segmentNode() - Lookup Segment-Knoten (memoized)

=head4 Synopsis

  $seg = $doc->segmentNode($name);

=head4 Arguments

=over 4

=item $name

Name des Segment-Knotens.

=back

=head4 Returns

Link-Knoten (Sdoc::Node::Segment) oder C<undef>

=head4 Description

Liefere den Segment-Knoten mit dem Name $name. Existiert kein
Segment-Knoten mit diesem Namen, liefere C<undef>.

=cut

# -----------------------------------------------------------------------------

sub segmentNode {
    my ($self,$name) = @_;

    my $h = $self->memoize('segmentH',sub {
        my ($self,$key) = @_;

        my %h;
        for my $node ($self->nodes) {
            if ($node->type eq 'Segment') {
                $h{$name} = $node;
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

=head3 sections() - Liste aller Abschnitts-Knoten (memoized)

=head4 Synopsis

  @sections | $sectionA = $doc->sections;

=head4 Returns

Liste von Abschnitts-Knoten. Im Skalarkontext eine Referenz auf
die Liste.

=head4 Description

Liefere die Liste aller Abschnitts-Knoten des Dokument-Baums.

=cut

# -----------------------------------------------------------------------------

sub sections {
    my $self = shift;

    my $arr = $self->memoize('sectionA',sub {
        my ($self,$key) = @_;

        my @arr;
        for my $node ($self->nodes) {
            if ($node->type eq 'Section') {
                push @arr,$node;
            }
        }
        #!! Dokument-Knoten im Array finden und die Referenz zu einer
        #!! schwachen Referenz machen
        #$self->weakenSelfReference(\@arr);

        return \@arr;
    });

    return wantarray? @$arr: $arr;
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

=head2 Verweise

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

            # Ein etwaiges Link-Attribut entfernen wir
            # hier aus dem Linktext
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
                    $node->increment('referenced');
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
                $node->increment('referenced');
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

    # Prüfe, ob alle Grafik-Knoten, die mit show=0 deklariert
    # sind, genutzt wurden. Warne ungenutzte Knoten an.

    for my $node ($self->nodes) {
        if ($node->type eq 'Graphic') {
            my $show = $node->show;
            if (defined($show) && $show == 0 && $node->useCount == 0) {
                $node->warn('Graphic node not used: name="%s"',
                    $node->name // '');
            }
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

=head2 Abschnitte

=head3 createTableOfContentsNode() - Ergänze Inhaltsverzeichnis

=head4 Synopsis

  $doc->createTableOfContentsNode;

=head4 Description

Ergänze das Dokument $doc um ein Inhaltsverzeichnis, wenn

=over 4

=item 1.

Dokument-Option C<tableOfContents=1> gesetzt ist (dies ist per
Default der Fall),

=item 2.

das Dokument keinen TableOfContents-Knoten enthält und

=item 3.

das Dokument mindestens einen Abschnitt enthält.

=back

=cut

# -----------------------------------------------------------------------------

sub createTableOfContentsNode {
    my $self = shift;

    if (!$self->tableOfContentsNode &&
            $self->getUserNodeAttribute('tableOfContents')) {
        my $att = $self->analyze;
        if ($att->sections) {
            my $toc = Sdoc::Node::TableOfContents->Sdoc::Node::new(
                'TableOfContents',0,$self,$self,
                htmlIndent => undef,
                htmlTitle => 1,
                maxLevel => 3,
            );
            $self->unshift(childA=>$toc);
            $self->set(nodeA=>undef); # forciere neue Knotenliste
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 flagSectionsAsAppendix() - Kennzeichne Appendix-Abschnitte

=head4 Synopsis

  $doc->flagSectionsAsAppendix;

=head4 Description

Kennzeichne alle Abschnitte nach dem ersten Abschnitt, der als
zum Appendix gehrig gekennzeichnet ist, ebenfalls als zum
Appendix gehörig. Bei Abschnitten, die zum Appendix gehören,
liefert die Methode $sec->isAppendix() anschließend 1.

=cut

# -----------------------------------------------------------------------------

sub flagSectionsAsAppendix {
    my $self = shift;

    my $appendix = 0;
    for my $sec ($self->sections) {
        # Appendix-Abschnitte kennzeichnen

        if ($appendix) {
            $sec->isAppendix(1);
        }
        elsif ($sec->isAppendix) {
            $appendix = 1;
            # Wir merken uns den ersten Appendix-Abschnitt
            $self->firstAppendixSection($sec);
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 flagSectionsNotToc() - Kennzeichne Abschnitte, die nicht ins Inhaltsverzeichnis sollen

=head4 Synopsis

  $doc->flagSectionsNotToc;

=head4 Description

Kennzeichne alle Abschnitte, für die ein übergeordneter Abschnitt
mit C<notToc=1> existiert, als Abschnitte, die nicht ins
Inhaltsverzeichnis übernommen werden sollen. Bei Abschnitten,
die nicht ins Inhaltsverzeichnis übernommen werden sollen,
liefert die Methode $sec->notToc() anschließend den Wert 1.

=cut

# -----------------------------------------------------------------------------

sub flagSectionsNotToc {
    my $self = shift;

    for my $sec ($self->sections) {
        my $node = $sec;
        while ($node = $node->parent) {
            if ($node->type ne 'Section') {
                last;
            }
            elsif ($node->tocStop) {
                $sec->notToc(1);
                last;
            }
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head3 highestSectionLevel() - Ermittele die höchste Abschnittsebene

=head4 Synopsis

  $n = $doc->highestSectionLevel;

=head4 Returns

Ebenennummer (Integer) oder C<undef>

=head4 Description

Ermittele die höchste Abschnittsebene des Dokuments und liefere
deren Ebenennummer zurück. Die höchste Abschnittsebene ist die
Abschnittsebene mit der I<niedrigsten> Ebenennummer (level). Es
gibt die Ebenennummern: -1, 0, 1, 2, 3, 4, 5, 6, wobei das Maximum
vom Zielformat abhängt (LaTeX: 4, HTML: 6). Enthält das Dokument
keinen Abschnitt, wird C<undef> geliefert.

=cut

# -----------------------------------------------------------------------------

sub highestSectionLevel {
    my $self = shift;

    return $self->memoize('highestSectionLevel',sub {
        my ($self,$key) = @_;

        my $n;
        for my $sec ($self->sections) {
            my $level = $sec->level;
            if (!defined($n) || $level < $n) {
                $n = $level;
            }
        }
        return $n;
    });
}

# -----------------------------------------------------------------------------

=head3 numberSections() - Setze Dokument-Abschnittsnummern (memoize)

=head4 Synopsis

  $doc->numberSections;

=head4 Description

Setze auf allen Abschnitts-Knoten des Dokuments die
Dokument-Abschnittsnummer.

=cut

# -----------------------------------------------------------------------------

sub numberSections {
    my $self = shift;

    return $self->memoize('doneNumberSections',sub {
        my ($self,$key) = @_;

        my @num = (0);        # Array mit den Abschnittsnummer der Ebenen
        my $lastLevel;        # Ebene des vorigen Abschnitts
        my $firstAppendixNum; # Nummer des ersten Appendix-Abschnitts
        for my $sec ($self->sections) {
            my $level = $sec->level;

            # Array aktualisieren

            if (!defined($lastLevel) || $level == $lastLevel) {
                # Anfang oder gleiche Ebene -> Zähler der Ebene inkrementieren
                $num[-1]++;
            }
            elsif ($level > $lastLevel) {
                # Wir steigen eine Ebene tiefer -> Ebene am Ende hinzufügen
                push @num,1;
            }
            elsif ($level < $lastLevel) {
                # Wir steigen n Ebenen hoch -> untergeordnete Ebenen entfernen

                splice @num,-($lastLevel-$level);
                $num[-1]++;
            }
            
            # Abschnittsnummer erzeugen
            my $num = join '.',@num;
            
            if ($sec->isAppendix) {
                # Abschnitt ist ein Appendix -> erste Ebene durch
                # Buchstaben ersetzen

                if (!defined $firstAppendixNum) {
                    $firstAppendixNum = $num[0];
                }
                $num =~ s/^\d+/chr(65+$num[0]-$firstAppendixNum)/e;
            }

            # Abschnittsnummer auf Abschnitts-Objekt setzen
            $sec->set(sectionNumber=>$num);

            # Letzte Ebene merken
            $lastLevel = $level;
        }

        return 1;
    });
}

# -----------------------------------------------------------------------------

=head2 Generierung

=head3 generate() - Generiere Knoten-Code

=head4 Synopsis

  $code = $doc->generate($format,@args);

=head4 Arguments

=over 4

=item $format

Das Zielformat. Mögliche Werte: 'html', 'latex', 'tree'.

=back

=head4 Returns

Code (String)

=head4 Description

Generiere Code im Format $format für Knoten $node und seine
Unterknoten und liefere diesen zurück. Auf den Wurzelknoten des
Parsingbaums angewendet, liefert die Methode den Code für das
gesamte Dokument.

=cut

# -----------------------------------------------------------------------------

sub generate {
    my $self = shift;
    my $format = shift;
    # @_: @args

    my $code = $self->SUPER::generate($format,@_);

    # Wende etwaige Post-Prozessoren auf den generierten Code an

    for my $node ($self->nodes) {
        if ($node->type eq 'PostProcessor') {
            $code = $node->execute($format,$code);
        }
    }

    return $code;
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

Zunächst wird eine Tilde-Expansion durchgeführt, d.h. eine Tilde
am Pfadanfang wird zum Homeverzeichnis des Benutzers expandiert.

Ferner wird geprüft, ob $path die Zeichenkette C<+/> enthält.
Wenn ja, ersetzen wir an allen Stellen das Pluszeichen durch das
Dokumentverzeichnis.

=cut

# -----------------------------------------------------------------------------

sub expandPath {
    my ($self,$path) = @_;

    if (!defined $path) {
        return undef;
    }

    $path = Sdoc::Core::Path->expandTilde($path);
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

=head3 css() - Generiere CSS-Code

=head4 Synopsis

  $code = $doc->css($c,$global);

=head4 Arguments

=over 4

=item $c

Generator für CSS.

=item $global

Wenn gesetzt, werden die globalen CSS-Regeln der Knoten-Klasse
geliefert, sonst die lokalen CSS-Regeln der Knoten-Instanz.

=back

=head4 Returns

CSS-Code (String)

=head4 Description

Generiere den CSS-Code der Knoten-Klasse oder der Knoten-Instanz
und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub css {
    my ($self,$c,$global) = @_;

    if ($global) {
        # Globale CSS-Regeln der Knoten-Klasse

        return $c->restrictedRules('.'.$self->cssClass,
            # * Font Titel, Author, Date vergrößern
            # * Abstand zwischen Titel und Author, Date verkleinern
            h1 => [
                fontSize => '250%',
                marginBottom => '10px',
            ],
            'div.author' => [
            ],
            'div.date' => [
                marginTop => '0.2em',
            ],
            p => [
                fontSize => '115%',
                marginBottom => '10px',
            ],
        );
    }

    # Lokale CSS-Regeln der Knoten-Instanz
    return '';
}

# -----------------------------------------------------------------------------

=head3 htmlCode() - Generiere HTML-Code

=head4 Synopsis

  $code = $doc->htmlCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für HTML.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub htmlCode {
    my ($self,$h) = @_;

    # Code für den Titelbereich generieren

    my $code = '';
    if (my $title = $self->expandText($h,'titleS')) {
        $code = $h->tag('h1',
            $title
        );
    }
    my $info;
    if (my $author = $self->expandText($h,'authorS')) {
        $info .= $h->tag('div',
            class => 'author',
            $author
        );
    }
    if (my $date = $self->expandText($h,'dateS')) {
        # Spezielle Datumswerte:
        # * today
        # * now
        # * strftime-Formate werden expandiert

        if ($date eq 'today') {
            my $t = Sdoc::Core::Time->new(local=>time);
            if ($self->language eq 'german') {
                $date = sprintf '%d. %s %d',
                    $t->day,$t->monthName('german'),$t->year;
            }
            else {
                $date = sprintf '%s %d, %d',
                    $t->monthName('english'),$t->day,$t->year;
            }
        }
        elsif ($date eq 'now') {
            $date = '%Y-%m-%d %H:%M:%S';
        }
        $info .= $h->tag('div',
            class => 'date',
            POSIX::strftime($date,localtime)
        );
    }
    if ($info) {
        #$code .= $h->tag('p',
        #    $info
        #);
        $code .= $info;
    }
    $code = $h->tag('div',
        -ignoreIfNull => 1,
        class => $self->cssClass,
        $code
    );
    $code .= $self->generateChilds('html',$h);
    
    my $style;
    my $c = Sdoc::Core::Css->new('flat');

    # Globale CSS-Regeln aller CSS-Klassen (!= Knoten-Typen,
    # da es mehrere CSS-Klassen für Listen gibt)

    my %seen;
    for my $node ($self->nodes) {
        if (!$seen{$node->cssClass}++) {
            $style .= $node->css($c,1);
        }
    }

    # Knotenspezifische CSS-Regeln

    for my $node ($self->nodes) {
        $style .= $node->css($c,0);
    }

    return Sdoc::Core::Html::Page->html($h,
        comment => 'Generated by Sdoc - DO NOT EDIT!',
        title => $self->title, # FIXME: Keine Sonderkonstrukte zulassen
        styleSheet => $style,
        body => $code,
    );
}

# -----------------------------------------------------------------------------

=head3 latexCode() - Generiere LaTeX-Code

=head4 Synopsis

  $code = $doc->latexCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub latexCode {
    my ($self,$l) = @_;

    # Dokumenteigenschaften ermitteln
    my $att = $self->analyze;

    # Globale Information

    my $documentClass = $self->latexDocumentClass;
    my $toc = $self->tableOfContentsNode; # kann undef sein
    my $pageStyle = $self->latexPageStyle;
    my ($titlePageStyle,$otherPageStyle) = split /,/,$pageStyle;
    my $smallerMonospacedFont = $self->smallerMonospacedFont;
    my $showFrames = $self->latexShowFrames;

    # Pakete laden und Einstellungen vornehmen

    my (@packages,@preamble);
    if ($att->sections && $pageStyle) {
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
                # $l->c('\pagestyle{scrheadings}'),
                $l->c('\pagestyle{%s}',$otherPageStyle),
                $l->c('\automark[subsection]{section}'),
                $l->c('\ihead{\MakeUppercase{\leftfirstmark}}'),
                $l->c('\chead{}'),
                $l->c('\ohead{\ifstr{\leftfirstmark}{\rightfirstmark}{}'.
                    '{\rightfirstmark}}'),
                #$l->c('\KOMAoptions{footsepline}'),
                #$l->c('\ModifyLayer[addvoffset=-0.5ex]'.
                #    '{scrheadings.foot.above.line}'),
                $l->c('\cfoot[\emph{\thepage/\nolink{\pageref{LastPage}}}]'.
                    '{\emph{\thepage/\nolink{\pageref{LastPage}}}}'),
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
    if ($att->lists) {
        push @packages,
            enumitem => 1, # Ersatz für itemize, enumerate, description
        ;
    }
    if ($att->tables) {
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
    if ($att->graphics) {
        push @packages,
            graphicx => 1, # Grafiken
            float => 1, # besseres Float Environment
        ;
    }
    if ($att->quotes) {
        push @packages,
            quoting => ['leftmargin=1.3em','font=itshape','vskip=1ex'],
        ;
    }

    if ($att->tables || $att->links || $toc) {
       push @packages,
            xcolor => [ # Farben
                'table',
                'dvipsnames',
            ],
       ;       
    }
    if ($att->captions) {
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
    if ($att->sourceCode) {
        push @packages,
            minted => 1, # Syntax Highligheting
        ;
        push @preamble,
            $l->comment('languages syntax highlighting'),
            $l->c('\usemintedstyle{%s}',
                $self->getUserNodeConfigAttribute('codeStyle'));
    }
    elsif ($att->verbatim) {
        push @packages,
            fancyvrb => 1, # Literaler Text
        ;
    }
    if ($smallerMonospacedFont && ($att->sourceCode || $att->verbatim)) {
        push @preamble,
            $l->comment('smaller monospaced font'),
            # * Größe des Font in Verbatim- und minted-Umgebungen (optional)
            $l->c('\fvset{fontsize=\small}');
        ;
    }

    if ($att->lineNumbers) {
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
                        my $indent = ($i? $self->latexIndentation+8: 8).'pt';

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
    # Sonst Fehler bei Document.tableOfContents=0
    # if ($toc || $att->links) {
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
    # }
    if ($showFrames) {
        push @packages,
            showframe => 1, # Kennzeichnung Seitenbereiche
        ;
    }
    if ($documentClass =~ /^scr/ && $att->section4) {
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
        language => $self->language,
        paperSize => $self->latexPaperSize,
        geometry => $self->latexGeometry,
        fontSize => $self->latexFontSize,
        title => $self->expandText($l,'titleS') // '',
        author => $self->expandText($l,'authorS') // '',
        date => $self->expandText($l,'dateS') // '',
        secNumDepth => $att->sections?
            $self->getUserNodeAttribute('sectionNumberLevel'): undef,
        tocDepth => $toc? $toc->maxLevel: undef,
        titlePageStyle => $titlePageStyle,
        parSkip => $self->latexParSkip,
        preComment => 'Generated by Sdoc - DO NOT EDIT!',
        packages => \@packages,
        preamble => \@preamble,
        body => $self->generateChilds('latex',$l),
    );
}

# -----------------------------------------------------------------------------

=head3 mediawikiCode() - Generiere MediaWiki-Code

=head4 Synopsis

  $code = $doc->mediawikiCode($gen);

=head4 Arguments

=over 4

=item $gen

Generator für MediaWiki.

=back

=head4 Returns

MediaWiki-Code (String)

=cut

# -----------------------------------------------------------------------------

sub mediawikiCode {
    my ($self,$m) = @_;

    my $title = $self->expandText($m,'titleS');
    
    my $code = ''; # = $m->comment('Generated by Sdoc - DO NOT EDIT!');
    my $info = $self->expandText($m,'authorS');
    if (my $date = $self->expandText($m,'dateS')) {
        if ($info) {
            $info .= ', ';
        }
        $info .= $date;
    }
    if ($info) {
        $code .= $m->paragraph($info);
    }
    $code .= $self->generateChilds('mediawiki',$m);

    return Sdoc::Core::Record->toString(
        -format => '@',
        Title => $title,
        Content => $code,
        -space => 1,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

3.00

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2020 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
