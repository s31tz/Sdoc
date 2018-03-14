package Sdoc::Core::Html::Verbatim;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.125;

use Sdoc::Core::Html::Table::Simple;
use Sdoc::Core::Option;
use Sdoc::Core::Css;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Html::Verbatim - Verbatim-Abschnitt in HTML

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Verbatim-Abschnitt in
HTML. Ein Verbatim-Abschnitt gibt einen Text TEXT in einem
monospaced Font mit allen Leerzeichen und Zeilenumbrüchen
identisch wieder. Der Verbatim-Abschnitt kann mit oder ohne
Zeilennummern ausgestattet sein.

Aufbau eines Verbatim-Abschnitts I<ohne> Zeilennummern:

    <table class="verbatim-table" cellpadding="0" cellspacing="0">
    <tr>
      <td class="verbatim-text">
        <pre>TEXT</pre>
      </td>
    </tr>
    </table>

Aufbau eines Verbatim-Abschnitts I<mit> Zeilennummern:

    <table class="verbatim-table" cellpadding="0" cellspacing="0">
    <tr>
      <td class="verbatim-ln">
        <pre>ZEILENNUMMERN</pre>
      </td>
      <td class="verbatim-margin"></td>
      <td class="verbatim-text">
        <pre>TEXT</pre>
      </td>
    </tr>
    </table>

Das Aussehen des Verbatim-Abschnitts kann via CSS gestaltet werden.
Der Abschnitt verwendet vier CSS-Klassen:

=over 4

=item PREFIX-table

Die gesamte Tabelle.

=item PREFIX-ln

Die Zeilennummern-Spalte.

=item PREFIX-margin

Die Trenn-Spalte zwischen Zeilennummer- und Text-Spalte.

=item PREFIX-text

Die Text-Spalte.

=back

PREFIX ist hierbei ein über das Attribut cssClassPrefix
änderbarer Namens-Präfix. Default ist 'verbatim'.

Der CSS-Code kann mittels der Klassenmethode $class->rules()
erzeugt werden. Beschreibung siehe dort.

=head1 ATTRIBUTES

=over 4

=item cssClassPrefix => $str (Default: 'verbatim')

Präfix für die CSS-Klassen des Verbatim-Abschnitts.

=item cssTableStyle => $properties

Setze Properties $properties auf dem style-Attribut der Tabelle.

=item ln => $n (Default: 0)

Wenn ungleich 0, wird jeder Zeile eine Zeilennummer vorangestellt,
beginnend Zeilennummer $n.

=item text => $text

Der dargestellt Text. Ist $text leer (C<undef> oder Leerstring),
wird kein Verbatim-Abschnitt erzeugt, d.h. die Methode $obj->html()
liefert einen Leerstring.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Verbatim-Abschnitts-Objekt

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste von Attribut/Wert-Paaren. Die Werte werden auf dem Objekt
gesetzt. Siehe Abschnitt ATTRIBUTES.

=back

=head4 Returns

=over 4

=item $e

Verbatim-Abschnitts-Objekt (Referenz)

=back

=head4 Description

Instantiiere ein Verbatim-Abschnitts-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        cssClassPrefix => 'verbatim',
        cssTableStyle => undef,
        ln => 0,
        text => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=head4 Arguments

=over 4

=item $h

Objekt für die HTML-Generierung, d.h. eine Instanz der Klasse
Sdoc::Core::Html::Tag).

=item @keyVal

Siehe Konstruktor.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Generiere den HTML-Code des Verbatim-Abschnitts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern
mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($prefix,$style,$ln,$text) = $self->get(qw/cssClassPrefix
        cssTableStyle ln text/);

    if (!defined($text) || $text eq '') {
        # Wenn kein Text gegeben ist, wird kein Code generiert
        return '';
    }

    my @cols;
    if ($ln) {
        # Zeilennummern- und Margin-Kolumne

        my $lnCount = $text =~ tr/\n//;
        if (substr($text,-1,1) ne "\n") {
            # Wenn die letzte Zeile nicht mit einem Newline endet,
            # haben wir eine Zeilennummer mehr
            $lnCount++;
        }
        my $lnLast = $ln + $lnCount - 1;

        my $tmp;
        my $lnMaxWidth = length $lnLast;
        for (my $i = $ln; $i <= $lnLast; $i++) {
            if ($tmp) {
                $tmp .= "\n";
            }
            $tmp .= sprintf '%*d',$lnMaxWidth,$i;
        }
        push @cols,
            [class=>"$prefix-ln",$h->tag('pre',$tmp)],
            [class=>"$prefix-margin",''],
        ;
    }
    
    # Text-Kolumne
    push @cols,[class=>"$prefix-text",$h->tag('pre',$text)];

    # Erzeuge Tabelle

    return Sdoc::Core::Html::Table::Simple->html($h,
        class => "$prefix-table",
        cellpadding => 0,
        style => $style,
        rows => [
            [@cols],
        ],
    );
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 css() - CSS-Regeln für Verbatim-Abschnitt

=head4 Synopsis

    $rules = $class->css($format,@keyVal);

=head4 Arguments

=over 4

=item $format (Default: siehe Sdoc::Core::Css->new())

Format, in der die CSS-Regeln erzeugt werden.

=item @keyVal

Schlüssel/Wert-Paare, die die CSS-Eigenschaften definieren.

=over 4

=item cssClassPrefix

(Default: 'verbatim') Präfix der CSS-Klassen des Verbatim-Abschnitts.

=item cssTableProperties

(Default: []) Liste der Properties der CSS-Klasse PREFIX-table.

=item cssLnProperties

(Default: [color=>'#808080']) Liste der Properties der
CSS-Klasse PREFIX-ln.

=item cssMarginProperties

(Default: [width=>'0.6em']) Liste der Properties der
CSS-Klasse PREFIX-margin.

=item cssTextProperties

(Default: []) Liste der Properties der CSS-Klasse PREFIX-text.

=back

Ist '+' das erste Element einer Property-Liste, werden die
Default-Properties um diese I<ergänzt>.

=back

=head4 Returns

CSS-Regeln (String)

=head4 Description

Generiere CSS-Regeln für den Verbatim-Abschnitt auf Basis der
CSS-Eigenschaften @keyVal und liefere diese zurück.

=head4 Example

Ergänze die Kolumnen um Hintergrundfarben:

    Sdoc::Core::Html::Verbatim->css('flat',
        cssLnProperties => ['+',
            backgroundColor => 'yellow',
        ],
        cssMarginProperties => ['+',
            backgroundColor => 'red',
        ],
        cssTextProperties => ['+',
            backgroundColor => 'green',
        ],
    );

liefert

    .verbatim-table pre { margin: 0; }
    .verbatim-ln { color: #808080; background-color: yellow; }
    .verbatim-margin { width: 0.6em; background-color: red; }
    .verbatim-text { background-color: green; }

=cut

# -----------------------------------------------------------------------------

sub css {
    my $class = shift;
    my $format = shift;
    # @_: @keyVal

    # Übergebene Attribute

    my $opt = Sdoc::Core::Option->extract(-properties=>1,\@_,
        cssClassPrefix => 'verbatim',
        cssTableProperties => undef,
        cssLnProperties => undef,
        cssMarginProperties => undef,
        cssTextProperties => undef,
    );        

    # CSS-Regeln erzeugen

    my $css = Sdoc::Core::Css->new($format);
    my $prefix = $opt->cssClassPrefix;
    my $rules .= $css->rule(".$prefix-table pre",
        margin => 0,
    );
    $rules .= $css->rulesFromObject($opt,
        cssTableProperties => [".$prefix-table"],
        cssLnProperties => [".$prefix-ln",color=>'#808080'],
        cssMarginProperties => [".$prefix-margin",width=>'0.6em'],
        cssTextProperties => [".$prefix-text"],
    );

    return $rules;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.125

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
