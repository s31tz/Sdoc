package Sdoc::Node;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 3.00;

use Digest::SHA ();
use Scalar::Util ();
use Sdoc::Core::Html::Tag;
use Sdoc::Core::LaTeX::Code;
use Sdoc::Core::AnsiColor;
use Sdoc::Core::TreeFormatter;
use Sdoc::Core::LaTeX::Figure;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Node - Knoten des Sdoc-Parsingbaums

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 ATTRIBUTES

=over 4

=item input => $input

Die Quelle der Eingabe (für Fehlermeldungen). Dies ist eine
Zeichenkette (Dateipfad) oder eine Referenz (String- oder
Array-Referenz), siehe Sdoc::Core::LineProcessor::Line.

=item lineNum => $n

Zeilennummer in der Quelle, an der die Knotendefinition
beginnt.

=item variant => $n

Markup-Variante: 0 = Block, 1 .. n = Variante des Markup

=item type => $type

Typ des Knotens.

=item root => $root

Verweis auf den Wurzelknoten des Parsingbaums. Dies ist der
Dokument-Knoten des Sdoc-Dokuments.

=item parent => $parent

Verweis auf den Elternknoten.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Knoten

=head4 Synopsis

    $node = $class->new($type,$variant,$root,$parent,@keyVal);

=head4 Arguments

=over 4

=item $type

Typ des Knotens.

=item $variant

Markup-Variante: 0 = Block, 1 .. n = Variante des Markup

=item $root

Referenz auf den Wurzelknoten des Parsingbaums. Dies ist der
Dokument-Knoten des Sdoc-Dokuments.

=item $parent

Referenz auf den übergeordneten Knoten im Parsingbaum.

=item @keyVal

Liste von Schlssel/Wert-Paaren, die weitere Attribute des
Knotens definieren.

=back

=head4 Returns

Knoten-Objekt

=cut

# -----------------------------------------------------------------------------

our $InstantiatedNodes = 0;
our $DestroyedNodes = 0;

sub DESTROY {
    $DestroyedNodes++;
}

sub new {
    my ($class,$type,$variant,$root,$parent) = splice @_,0,5;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        type => $type,
        variant => $variant,
        root => $root,
        parent => $parent,
        input => undef,
        lineNum => undef,
        @_,
    );
    $self->weaken('root');
    $self->weaken('parent');

    $InstantiatedNodes++;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Navigation

=head3 nextNode() - Liefere nächsten Knoten

=head4 Synopsis

    $nextNode = $node->nextNode;

=head4 Returns

Knoten-Objekt oder C<undef>

=cut

# -----------------------------------------------------------------------------

sub nextNode {
    my $self = shift;

    my $childA = $self->parent->childs;
    for (my $i = 0; $i < @$childA; $i++) {
         if ($self == $childA->[$i]) {
             return $childA->[$i+1];
         }
    }

    $self->throw;
}

# -----------------------------------------------------------------------------

=head2 Knoten

=head3 allNodes() - Liste aller Knoten (rekursiv)

=head4 Synopsis

    @nodes = $node->allNodes;

=head4 Returns

Liste von Knoten

=head4 Description

Liefere die Liste aller Knoten ab und einschließlich Knoten $node.

=cut

# -----------------------------------------------------------------------------

sub allNodes {
    my $self = shift;

    my @arr = ($self);
    for my $node ($self->childs) {
        push @arr,$node->allNodes;
    }

    return @arr;
}

# -----------------------------------------------------------------------------

=head3 childs() - Liste der direkten Unterknoten

=head4 Synopsis

    @nodes | $nodeA = $node->childs;

=head4 Returns

Liste von Knoten. Im Skalarkontext wird eine Referenz auf die
Liste geliefert.

=head4 Description

Liefere die Liste der I<direkten> Subknoten des Knotens
$node. Besitzt ein Knotentyp keine Kindknoten, liefert die Methode
eine leere Liste.

=cut

# -----------------------------------------------------------------------------

sub childs {
    my $self = shift;
    my $childA = $self->exists('childA')? $self->childA: [];
    return wantarray? @$childA: $childA;
}

# -----------------------------------------------------------------------------

=head3 nodeHierarchy() - Knotenhierarchie als Liste (rekursiv)

=head4 Synopsis

    @pairs | $pairA = $node->nodeHierarchy;

=head4 Returns

Liste von Paaren ([$level,$node], ...). Im Skalarkontext wird eine
Referenz auf die Liste geliefert.

=head4 Description

Liefere die Knotenhierarchie für Knoten $node - also eine
Knotenhierarchie mit $node als oberstem Knoten - in Form einer
Liste von Paaren, wie sie von der Klasse Sdoc::Core::TreeFormatter
erwartet wird. Details siehe dort.

=cut

# -----------------------------------------------------------------------------

sub nodeHierarchy {
    my $self = shift;

    my @arr = ([0,$self]);
    for my $node ($self->childs) {
        push @arr,map {$_->[0]++; $_} $node->nodeHierarchy;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head2 Attribute

=head3 setAttributes() - Setze Knoten-Attribute

=head4 Synopsis

    $node->setAttributes(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste von Attribute/Wert-Paaren

=back

=head4 Description

Setze die Attribut/Wert-Paare @keyVal auf dem Knoten. Für jedes
Attribut wird geprüft, ob es auf dem Knoten existiert. Ist dies
nicht der Fall, wird das Attribut/Wert-Paar ignoriert und eine
Warnung ausgegeben.

=cut

# -----------------------------------------------------------------------------

sub setAttributes {
    my $self = shift;
    # @_: @keyVal

    my @unknown;
    while (@_) {
        my $key = shift;
        my $val = shift;

        if (!$self->exists($key)) {
            push @unknown,$key;
            next;
        }
        $self->set($key=>$val);
    }

    # Wir geben die Warnung verzögert aus, damit wir die
    # Zeilennnummer abfragen knnen.

    for my $key (@unknown) {
        $self->warn('Attribute "%s" does not exist',$key);
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Anker-Pfad

=head3 anchorPathAsArray() - Anker-Pfad als Array (memoized)

=head4 Synopsis

    @anchors | $anchorA = $node->anchorPathAsArray;

=head4 Returns

Anker-Pfad als Liste von Ankern (Array of Strings). Im
Skalar-Kontext wird eine Referenz auf die Liste geliefert.

=head4 Description

Liefere den Anker-Pfad des Knotens $node als Liste von
Ankern. Definiert der Knoten keinen Anker, wird eine leere Liste
geliefert. Der Anker-Pfad eines Knotens ist die Liste aller Anker
vom Wurzelknoten des Dokuments bis zum Knoten $node. Definiert
ein I<innen liegender> Knoten keinen Anker, wird als Anker sein Typ
eingetragen.

=cut

# -----------------------------------------------------------------------------

sub anchorPathAsArray {
    my $self = shift;

    my $arr;
    if (!$self->exists('anchor')) {
        # Knotenklassen ohne Anker speichern keinen Anker-Pfad
        $arr = [];
    }
    else {
        $arr = $self->memoize('anchorA',sub {
            my ($self,$key) = @_;

            my @arr;
            if (my $anchor = $self->anchor) {
                @arr = ($anchor);
                my $node = $self;
                while (1) {
                    $node = $node->parent;
                    if (!$node) {
                        last;
                    }
                    unshift @arr,($node->anchor // $node->type);
                }
            }
            
            return \@arr;
        });
    }
    
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head3 anchorPathAsString() - Anker-Pfad als Zeichenkette

=head4 Synopsis

    $path = $node->anchorPathAsString;

=head4 Returns

Anker-Pfad (String)

=head4 Description

Liefere den Anker-Pfad des Knotens $node als Zeichenkette.
Definiert der Knoten keinen Anker, wird C<undef> geliefert.
Siehe auch Methode $node->anchorPathAsArray().

=cut

# -----------------------------------------------------------------------------

sub anchorPathAsString {
    my $self = shift;

    my $anchorA = $self->anchorPathAsArray;
    if (!@$anchorA) {
        return undef;
    }

    return join '/',@$anchorA;
}

# -----------------------------------------------------------------------------

=head3 linkId() - Link-Id des Knotens (memoize)

=head4 Synopsis

    $linkId = $node->linkId;

=head4 Returns

Link_id (String)

=cut

# -----------------------------------------------------------------------------

sub linkId {
    my $self = shift;

    return $self->memoize('linkId',sub {
        my ($self,$key) = @_;
        
        my $anchorPath = $self->anchorPathAsString;
        if (!$anchorPath) {
            $self->warn("Node can't be referenced");
            return undef;
        }

        return Digest::SHA::sha1_base64($anchorPath);
    });

}

# -----------------------------------------------------------------------------

=head2 Referenzen

=head3 weakenSelfReference() - Schwäche Referenz bei Referenz auf sich selbst

=head4 Synopsis

    $node->weakenSelfReference(\@arr);

=head4 Arguments

=over 4

=item @arr

Array von Knotenrefefenzen.

=back

=head4 Description

Prüfe das Array von Knotenreferenzen @arr daraufhin, ob darin eine
Referenz auf den Knoten $node selbst vorkommt. Wenn ja, mache
diese Referenz zu einer schwachen Referenz.

=cut

# -----------------------------------------------------------------------------

sub weakenSelfReference {
    my ($self,$arr) = @_;

    for (my $i = 0; $i < @$arr; $i++) {
        if ($arr->[$i] == $self) {
            Scalar::Util::weaken($arr->[$i]);
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Warnungen

=head3 warn() - Gib Warnung auf STDERR aus

=head4 Synopsis

    $node->warn($fmt,@args);

=head4 Arguments

=over 4

=item $fmt

Meldung oder Formatelement (sprintf).

=item @args

Argumente, wenn $fmt ein Formatelement ist.

=back

=cut

# -----------------------------------------------------------------------------

sub warn {
    my $self = shift;
    my $fmt = shift;
    # @_: @args;

    my $quiet = $self->root->quiet;
    if (!$quiet) {
        warn sprintf "WARNING: %s (%s +%s %s)\n",
            sprintf($fmt,@_),
            $self->type,
            $self->lineNum,
            $self->input;
    }
    
    return;
}

# -----------------------------------------------------------------------------

=head2 Debug

Die Klasse Sdoc::Node ist an jeder Knoten-Instantiierung
beteiligt. Sie definiert zwei Zähler:

=over 4

=item $InstantiatedNodes

Anzahl der instantiierten Knoten. Dieser Zähler wird bei jeder
Knoten-Instantiierung um 1 erhöht.

=item $DestroyedNodes

Anzahl der destrukturierten Knoten. Dieser Zähler wird bei
jeder Knoten-Destrukturierung um 1 erniedrigt.

=back

Konstistenzbedingung: Wenn die letzte Referenz auf den
Wurzelknoten des Parsingbaums entfernt wird, müssen alle Knoten
des Baums destrukturiert werden. D.h. beide Zähler müssen den
gleichen Wert haben.

Die Methoden resetCounts() und getCounts() können genutzt werden,
um die Konsistenzbedingung zu prüfen.

=head3 resetCounts() - Lösche Instanz-Zähler

=head4 Synopsis

    $class->resetCounts;

=cut

# -----------------------------------------------------------------------------

sub resetCounts {
    my $class = shift;

    $InstantiatedNodes = 0;
    $DestroyedNodes = 0;

    return;
}

# -----------------------------------------------------------------------------

=head3 getCounts() - Liefere Instanz-Zähler

=head4 Synopsis

    ($destroyed,$instantiated) = $class->getCounts;

=cut

# -----------------------------------------------------------------------------

sub getCounts {
    my $class = shift;
    return ($DestroyedNodes,$InstantiatedNodes);
}

# -----------------------------------------------------------------------------

=head2 Generierung

=head3 generate() - Generiere Knoten-Code

=head4 Synopsis

    $code = $node->generate($format,@args);

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

    my $gen;
    if ($format eq 'tree') {
        return $self->tree(@_);
    }
    elsif ($format eq 'html') {
        $gen = Sdoc::Core::Html::Tag->new;
    }
    elsif ($format eq 'latex') {
        $gen = Sdoc::Core::LaTeX::Code->new;
    }
    else {
        $self->throw(
            q~SDOC-00004: Unknown format~,
            Format => $format,
        );
    }

    return $self->generateFormat($format,$gen);
}

# -----------------------------------------------------------------------------

=head3 generateChilds() - Generiere Child-Code

=head4 Synopsis

    $code = $node->generateChilds($format,$gen);

=head4 Arguments

=over 4

=item $format

Das Zielformat, in dem der Code generiert wird.

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

Code (String)

=head4 Description

Generiere Code im Format $format für jeden direkten Unterknoten
von Knoten $node, konkateniere die Teile, und liefere das Resultat
zurück.

=cut

# -----------------------------------------------------------------------------

sub generateChilds {
    my ($self,$format,$gen) = @_;

    my $code = '';
    for my $node ($self->childs) {
        $code .= $node->generateFormat($format,$gen);
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 generateFormat() - Generiere Knoten-Code für alle Formate (überschreibbar)

=head4 Synopsis

    $code = $node->generateFormat($format,$gen);

=head4 Arguments

=over 4

=item $format

Zielformat, das generiert wird.

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

Code (String)

=head4 Description

Generiere Code im Format $format unter Nutzung des Generators $gen
für Knoten $node und liefere das Resultat zurück. Diese Methode
kann in einer Knoten-Klasse überschrieben werden, falls es bei
der Generierung gemeinsamen Code für alle Formate gibt. Die Methode
delegiert dann selbst an die Methoden generateI<FORMAT>().

=cut

# -----------------------------------------------------------------------------

sub generateFormat {
    my ($self,$format,$gen) = @_;

    my $meth = sprintf 'generate%s',ucfirst $format;
    return $self->$meth($gen);
}

# -----------------------------------------------------------------------------

=head2 Formate

=head3 tree() - Baumdarstellung (für Debugging)

=head4 Synopsis

    $str = $node->tree($ansiColor);

=head4 Arguments

=over 4

=item $ansiColor (Default: 1)

Wenn gesetzt, erzeuge die Baumdarstellung mit ANSI Colorcodes.

=back

=head4 Returns

Baumdarstellung (String)

=head4 Description

Generiere eine Baumdarstellung für Knoten $node und seine
Unterknoten und liefere diese zurück. Auf den Wurzelknoten des
Parsingbaums angewendet, liefert die Methode eine Baumdarstellung
für das gesamte Dokument.

=cut

# -----------------------------------------------------------------------------

sub tree {
    my $self = shift;
    my $ansiColor = shift // 1;

    my $a = Sdoc::Core::AnsiColor->new($ansiColor);

    my $pairA = $self->nodeHierarchy;
    return Sdoc::Core::TreeFormatter->new($pairA)->asText(
        -getText => sub {
            my $node = shift;
            my $str =  $a->str('bold red',$node->type)."\n";
            for my $key (sort $node->keys) {
                my $val = $node->get($key) // 'undef';
                if ($val =~ tr/\n//) {
                    $val =~ s/^/:   /mg;
                    $val = "\n$val";
                }
                $str .= ": $key: $val\n";
            }
            return $str;
        },
    );
}

# -----------------------------------------------------------------------------

=head3 expandText() - Expandiere Segmente in Text

=head4 Synopsis

    $code = $node->expandText($gen,$key);
    $code = $node->expandText($gen,\$str);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=item $key

Name des Attributs.

=item $str

Wert.

=back

=head4 Returns

Quelltext des Zielformats (String)

=head4 Description

Liefere den Wert des Knoten-Attributs $key, nachdem alle Segmente
expandiert und die Metazeichen des jeweiligen Zielformats
geschützt wurden. Dieser Wert (Text) kann ohne weitere Änderungen
in einen Quelltext des Zielformats übernommen werden.

=cut

# -----------------------------------------------------------------------------

sub expandText {
    my ($self,$gen,$arg) = @_;

    my $val = ref $arg? $$arg: $self->get($arg);
    if (defined $val) {
        # Schütze reservierte Zeichen
        $val = $gen->protect($val);

        # Ermittele Zielformat-spezifische Methode

        my $meth = 'unknown';
        if ($gen->isa('Prty::Html::Tag')) {
            $meth = 'expandSegmentsToHtml';
        }
        elsif ($gen->isa('Prty::LaTeX::Code')) {
            $meth = 'expandSegmentsToLatex';
        }

        # Expandiere Segmente mittels Zielformat-spezifischer Methode

        1 while $val =~
            s/([ABCGILMNQ])\x01([^\x01\x02]*)\x02/$self->$meth($gen,$1,$2)/e;
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 expandSegmentsToHtml() - Expandiere Segmente zu HTML-Code

=head4 Synopsis

    $code = $node->expandSegmentsToHtml($gen,$segment,$val);

=head4 Arguments

=over 4

=item $gen

Generator für HTML

=item $segment

Segment-Bezeichner (ein Buchstabe)

=item $val

Wert innerhalb der Segment-Klammern.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub expandSegmentsToHtml {
    my ($self,$h,$seg,$val) = @_;

    my $root = $self->root;

    if ($seg eq 'A') {
        # Darf es eigentlich nicht geben. Entweder wurde A{} verwendet,
        # wo es nicht vorgesehen ist, oder A{} wurde in einem Block
        # mehr als einmal verwendet. Entsprechende Warnungen
        # wurden an anderer Stelle erzeugt.
        return sprintf 'A\{%s\}',$val;
    }
    elsif ($seg eq 'B') {
        return $h->tag('b',$val);
    }
    elsif ($seg eq 'C') {
        if ($self->type eq 'Paragraph' && $root->smallerMonospacedFont) {
            return $h->tag('tt',
                style => 'font-size: smaller',
                $val
            );
        }
        return $h->tag('tt',
            $val
        );
    }
    elsif ($seg eq 'I') {
        return $h->tag('i',$val);
    }
    elsif ($seg eq 'G') {
        my $code;

        if ($val !~ /^\d+$/) {
            # G hat als Wert keinen Index, also ist G{} auf
            # diesem Knoten kein erwartetes Segment. Siehe auch
            # Methode parseSegments(). Wir liefern den Text
            # unverändert.
            return sprintf 'G{%s}',$val;
        }
        my ($name,$gph) = @{$self->graphicA->[$val]};
        if ($gph) {
            # FIXME
            $self->warn('G-Segment not implemented for HTML');
            $code = sprintf 'G{%s}',$name;
        }
        else {
            $code = sprintf 'G{%s}',$name;
        }

        return $code;
    }
    elsif ($seg eq 'L') {
        my $code;

        if ($val !~ /^\d+$/) {
            # L hat als Wert keinen Index, also ist L{} auf
            # diesem Knoten kein erwartetes Segment. Siehe auch
            # Methode parseSegments(). Wir liefern den Text
            # unverändert.
            return sprintf 'L{%s}',$val;
        }

        my ($linkText,$obj) = @{$self->linkA->[$val]};
        if ($obj->type eq 'external') {
            $code = $h->tag('a',
                href => $obj->destText,
                $h->protect($obj->text),
            );
        }
        elsif ($obj->type eq 'internal') {
            my $destNode = $obj->destNode;
            my $linkId = $destNode->linkId;

            if ($obj->attribute eq '+') {
                $code = $h->tag('a',
                    href => "#$linkId",
                    $destNode->linkText($h),
                );
            }
            else {
                $code = $h->tag('a',
                    href => "#$linkId",
                    $h->protect($obj->text),
                );
            }
        }
        elsif ($h->type eq 'unresolved') {
            $code = sprintf 'L{%s}',$h->protect($linkText);
        }

        return $code;
    }
    elsif ($seg eq 'M') {
        if ($val !~ /^\d+$/) {
            # M hat als Wert keinen Index, also ist M{} auf
            # diesem Knoten kein erwartetes Segment. Siehe auch
            # Methode parseSegments(). Wir liefern das
            # Segment als Text.
            return sprintf 'M~%s~',$val;
        }

        return $h->tag('b',
            $h->protect($self->formulaA->[$val])
        );
    }
    elsif ($seg eq 'N') {
        return $h->tag('br');
    }
    elsif ($seg eq 'Q') {
        return $h->tag('q',$val);
    }

    $self->throw(
        q~SDOC-00001: Unknown segment~,
        Segment => $seg,
        Code => "$seg\{$val\}",
        Input => $self->input,
        Line => $self->lineNum,
    );
}

# -----------------------------------------------------------------------------

=head3 expandSegmentsToLatex() - Expandiere Segmente zu LaTeX-Code

=head4 Synopsis

    $code = $node->expandSegmentsToLatex($gen,$segment,$val);

=head4 Arguments

=over 4

=item $gen

Generator für LaTeX.

=item $segment

Segment-Bezeichner (ein Buchstabe)

=item $val

Wert innerhalb der Segment-Klammern.

=back

=head4 Returns

LaTeX-Code (String)

=cut

# -----------------------------------------------------------------------------

sub expandSegmentsToLatex {
    my ($self,$l,$seg,$val) = @_;

    my $root = $self->root;

    if ($seg eq 'A') {
        # Darf es eigentlich nicht geben. Entweder wurde A{} verwendet,
        # wo es nicht vorgesehen ist, oder A{} wurde in einem Block
        # mehr als einmal verwendet. Entsprechende Warnungen
        # wurden an anderer Stelle erzeugt.
        return sprintf 'A\{%s\}',$val;
    }
    elsif ($seg eq 'B') {
        return sprintf '\textbf{%s}',$val;
    }
    elsif ($seg eq 'C') {
        if ($self->type eq 'Paragraph' && $root->smallerMonospacedFont) {
            return sprintf '\texttt{\small %s}',$val;
        }
        return sprintf '\texttt{%s}',$val;
    }
    elsif ($seg eq 'I') {
        return sprintf '\textit{%s}',$val;
    }
    elsif ($seg eq 'G') {
        my $code;

        if ($val !~ /^\d+$/) {
            # G hat als Wert keinen Index, also ist G{} auf
            # diesem Knoten kein erwartetes Segment. Siehe auch
            # Methode parseSegments(). Wir liefern den Text
            # unverändert.
            return sprintf 'G\{%s\}',$val;
        }
        my ($name,$gph) = @{$self->graphicA->[$val]};
        if ($gph) {
            $code .= Sdoc::Core::LaTeX::Figure->latex($l,
                inline => 1,
                border => $gph->border,
                borderMargin => $gph->borderMargin,
                file => $root->expandPath($gph->file),
                height => $gph->height,
                indent => $gph->indentation // 0?
                    $root->indentation.'em': undef,
                link => $gph->latexLinkCode($l),
                options => $gph->latexOptions,
                scale => $gph->scale,
                width => $gph->width,
            );
        }
        else {
            $code = sprintf 'G\{%s\}',$name;
        }

        return $code;
    }
    elsif ($seg eq 'L') {
        my $code;

        if ($val !~ /^\d+$/) {
            # L hat als Wert keinen Index, also ist L{} auf
            # diesem Knoten kein erwartetes Segment. Siehe auch
            # Methode parseSegments(). Wir liefern den Text
            # unverändert.
            return sprintf 'L\{%s\}',$val;
        }

        my ($linkText,$h) = @{$self->linkA->[$val]};
        if ($h->type eq 'external') {
            $code = $l->ci('\href{%s}{%s}',$l->protect($h->destText),
                $l->protect($h->text));
        }
        elsif ($h->type eq 'internal') {
            my $destNode = $h->destNode;
            my $linkId = $destNode->linkId;

            if ($h->attribute eq '+') {
                $code .= $l->ci('\ref{%s} - ',$linkId);
                $code .= $l->ci('\hyperref[%s]{%s} ',$linkId,
                    $destNode->linkText($l));
            }
            else {
                $code .= $l->ci('\hyperref[%s]{%s} ',$linkId,
                    $l->protect($h->text));
            }
            $code .= $l->ci('\vpageref{%s}',$linkId);
        }
        elsif ($h->type eq 'unresolved') {
            $code = sprintf 'L\{%s\}',$l->protect($linkText);
        }

        return $code;
    }
    elsif ($seg eq 'M') {
        if ($val !~ /^\d+$/) {
            # M hat als Wert keinen Index, also ist M{} auf
            # diesem Knoten kein erwartetes Segment. Siehe auch
            # Methode parseSegments(). Wir liefern das
            # Segment als Text.
            return sprintf 'M\textasciitilde{}%s\textasciitilde{}',$val;
        }

        # Wir übergeben die Formel an den LaTeX Mathe-Modus
        return sprintf '\(%s\)',$self->formulaA->[$val];
    }
    elsif ($seg eq 'N') {
        return '\\\\';
    }
    elsif ($seg eq 'Q') {
        return "``$val''";
    }

    $self->throw(
        q~SDOC-00001: Unknown segment~,
        Segment => $seg,
        Code => "$seg\{$val\}",
        Input => $self->input,
        Line => $self->lineNum,
    );
}

# -----------------------------------------------------------------------------

=head3 latexSectionName() - LaTeX Abschnittsname zu Sdoc Abschnittsebene

=head4 Synopsis

    $code = $node->latexSectionName($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX Abschnittsname (String)

=head4 Description

Liefere den LaTeX Abschnittsnamen zur Sdoc Abschnittsebene.

=cut

# -----------------------------------------------------------------------------

sub latexSectionName {
    my ($self,$l) = @_;

    my $level = $self->level;

    my $name;
    if ($level == -1) {
        $name = 'part';
    }
    elsif ($level == 0) {
        $name = 'chapter';
    }
    elsif ($level == 1) {
        $name = 'section';
    }
    elsif ($level == 2) {
        $name = 'subsection';
    }
    elsif ($level == 3) {
        $name = 'subsubsection';
    }
    elsif ($level == 4) {
        $name = 'paragraph';
    }
    else {
        $self->throw(
            q~SDOC-00005: Unexpected section level~,
            Level => $level,
            Input => $self->input,
            Line => $self->lineNum,
        );
    }

    return $name;
}

# -----------------------------------------------------------------------------

=head3 htmlSectionCode() - HTML-Code für Section und Bridgehead

=head4 Synopsis

    $code = $node->htmlSectionCode($gen,$type);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=item $type

Typ der Überschrift. Mögliche Werte: 'bridgehead', 'section'.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Liefere den HTML-Code für einen Section- oder BridgeHead-Knoten.

=cut

# -----------------------------------------------------------------------------

sub htmlSectionCode {
    my ($self,$h,$type) = @_;

    my $doc = $self->root;

    my $title = $self->expandText($h,'titleS');
    if ($type eq 'section' && $self->level <= $doc->sectionNumberDepth) {
        $title = $self->sectionNumber.' '.$title;
    }

    # Abschnitt generieren

    my $highestLevel = $doc->highestSectionLevel;
    my $n = $self->level+(1-$highestLevel);
    #if ($highestLevel == 1 && $doc->title) {
    #    # Sonderbehandlung: Wenn das Dokument einen Titel, aber keine
    #    # übergeordneten Abschnitte (Part oder Chapter) hat, beginnen
    #    # wir mit h2, da der Titel bereits h1 ist.
    #    $n++;
    #}

    # In HTML stellen wir jedem Abschnitt einen Anker voran,
    # um alle Abschnitte aus dem Inhaltsverzeichnis und
    # von externen Links referenzieren zu können

    my $code .= $h->tag('a',
        -nl => 1,
        name => $self->linkId,
    );
    $code .= $h->tag("h$n",
        class => "sdoc-$type",
        $title
    );

    return $code;
}

# -----------------------------------------------------------------------------

=head3 htmlTableOfContents() - Erzeuge Inhaltsverzeichnis in HTML (rekursiv)

=head4 Synopsis

    $code = $node->htmlTableOfContents($gen,$maxDepth);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=item $maxDepth

Tiefe des tiefsten Abschnitts, der noch in das Inhaltsverzeichnis
aufgenommen wird. Mögliche Werte: -1, 0, 1, 2, 3, 4.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Erzeuge das Inhaltsverzeichnis des Dokuments in HTML und liefere
dieses zurück. Die Methode wird initial über den Dokument-Knoten
(Wurzelknoten des Dokuments) aufgerufen und ruft sich selbst über
den untergeordneten Abschnitts-Knoten auf.

=cut

# -----------------------------------------------------------------------------

sub htmlTableOfContents {
    my ($self,$h,$maxDepth) = @_;

    my $doc = $self->root;

    my $html = '';
    my $sectionNumber; # zeigt an, ob Ebene mit Abschnittsnummern
    for my $node ($self->childs) {
        if ($node->type eq 'Section' &&
                $node->level <= $maxDepth && !$node->notToc) {

            my $title = $node->expandText($h,'titleS');
            if ($node->level <= $doc->sectionNumberDepth) {
                $sectionNumber = $h->tag('span',
                    class => 'n',
                    $node->sectionNumber
                ).' ';
            }

            $html .= $h->tag('li',
                $h->cat(
                    $sectionNumber,
                    $h->tag('a',
                        -nl => 1,
                        href => '#'.$node->linkId,
                        $title
                    ),
                    $node->htmlTableOfContents($h,$maxDepth),
                ),
            );
        }
    }
    if ($html) {
        $html = $h->tag('ul',
            class => $sectionNumber? 'number': 'bullet',
            $html
        );
        if ($self->type eq 'Document') {
            my $title = $doc->language eq 'german'? 'Inhaltsverzeichnis':
                'Contents';
            $html = $h->tag('div',
                class => 'sdoc-tableofcontents',
                '-',
                $h->tag('h3',$title),
                $html,
            );
        }
    }

    return $html;
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
