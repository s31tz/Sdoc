package Sdoc::Node;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 3.00;

use Scalar::Util ();
use Sdoc::Core::LaTeX::Code;
use Sdoc::Core::AnsiColor;
use Sdoc::Core::TreeFormatter;

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
ein innen liegender Knoten keinen Anker, wird als Anker sein Typ
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

Das Zielformat. Mögliche Werte: 'latex', 'tree'.

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

    if ($format eq 'tree') {
        return $self->tree(@_);
    }
    elsif ($format eq 'latex') {
        my $gen = Sdoc::Core::LaTeX::Code->new;
        return $self->latex($gen);
    }

    $self->throw(
        q~SDOC-00004: Unknown format~,
        Format => $format,
    );
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
        $code .= $node->$format($gen);
    }

    return $code;
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

=head3 latexText() - Attributwert als fertiger LaTeX-Code

=head4 Synopsis

    $code = $node->latexText($gen,$key);
    $code = $node->latexText($gen,\$str);

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

LaTeX-Code (String)

=head4 Description

Liefere den Wert des Knoten-Attributs $key, nachdem alle Segmente
expandiert und die LaTeX-Metazeichen geschützt wurden. Dieser Wert
(Text) kann ohne weitere Änderungen in einen LaTeX-Quelltext
übernommen werden.

=cut

# -----------------------------------------------------------------------------

sub latexText {
    my ($self,$l,$arg) = @_;

    my $root = $self->root;

    # Ersetze die gewandelten Sdoc-Segmente durch LaTeX-Konstrukte

    my $r = sub {
        my ($seg,$val,$arg) = @_;

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
            if ($self->type eq 'Paragraph') {
                if ($root->smallerMonospacedFont) {
                    return sprintf '\texttt{\small %s}',$val;
                }
                return sprintf '\texttt{%s}',$val;
            }
            else {
                return sprintf '\texttt{%s}',$val;
            }
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
                my $type = $self->type;
                if ($type =~ /^(BridgeHead|Section)$/ ||
                        $arg eq 'captionS') {
                    $code .= '\protect';
                }
                my @opt = split /,/,$gph->latexOptions // '';
                if (my $scale = $gph->scale) {
                    push @opt,"scale=$scale";
                }
                $code .= $l->c('\includegraphics[%s]{%s}',
                    \@opt,
                    $root->expandPlus($gph->file),
                    -nl => 0,
                );
                if ($type eq 'Item' && $code =~ tr/[//) {
                    # Im Definitionsterm müssen wir Group-Klammern setzen
                    $code = "{$code}";
                }
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
                # $dest und $text sind identisch
                $code = $l->ci('\href{%s}{%s}',$l->protect($h->destText),
                    $l->protect($h->text));
            }
            elsif ($h->type eq 'internal') {
                my $destNode = $h->destNode;
                my $linkId = $destNode->linkId;

                if ($h->attribute eq '+') {
                    $code .= $l->ci('\ref{%s} - ',$linkId);
                    $code .= $l->ci('\hyperref[%s]{%s} ',$linkId,
                        $destNode->latexLinkText($l));
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
        elsif ($seg eq 'Q') {
            return "``$val''";
        }
        else {
            $self->throw(
                q~SDOC-00001: Unknown segment~,
                Segment => $seg,
                Code => "$seg\{$val\}",
                Input => $self->input,
                Line => $self->lineNum,
            );
        }
    };

    my $val = ref $arg? $$arg: $self->get($arg);
    if (defined $val) {
        $val = $l->protect($val); # Schütze reservierte LaTeX-Zeichen
        1 while $val =~
            s/([ABCGILMQ])\x01([^\x01\x02]*)\x02/$r->($1,$2,$arg)/e;
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head3 latexTableOfContents() - LaTeX-Code für Inhaltsverzeichnis

=head4 Synopsis

    $code = $node->latexTableOfContents($gen);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=back

=head4 Returns

LaTeX-Code (String)

=head4 Description

Liefere den LaTeX-Code für das Inhaltsverzeichnis. Das
Inhaltsverzeichnis wird von zwei Stellen aus erzeugt, daher haben
wir dafür hier eine eigene Methode.

=cut

# -----------------------------------------------------------------------------

sub latexTableOfContents {
    my ($self,$l) = @_;
    return $l->c('{\hypersetup{hidelinks}\tableofcontents}',-nl=>2);
}

# -----------------------------------------------------------------------------

=head3 latexLevelToSectionName() - LaTeX Abschnittsname zu Sdoc Abschnittsebene

=head4 Synopsis

    $code = $node->latexLevelToSectionName($gen,$level);

=head4 Arguments

=over 4

=item $gen

Generator für das Zielformat.

=item $level

Sdoc Abschnittsebene.

=back

=head4 Returns

LaTeX Abschnittsname (String)

=head4 Description

Liefere den LaTeX Abschnittsnamen zur Sdoc Abschnittsebene.

=cut

# -----------------------------------------------------------------------------

sub latexLevelToSectionName {
    my ($self,$l,$level) = @_;

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
