package Sdoc::Core::Html::Verbatim;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.125;

use Sdoc::Core::Html::Table::Simple;

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

    <div class="verbatim">
      <table class="verbatim-table" cellpadding="0" cellspacing="0">
      <tr>
        <td class="verbatim-text">
          <pre>TEXT</pre>
        </td>
      </tr>
      </table>
    </div>

Aufbau eines Verbatim-Abschnitts I<mit> Zeilennummern:

    <div class="verbatim">
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
    </div>

Das umgebende Div ermglicht, dass der Hintergrund des Abschnitts
über die gesamte Breite der Seite farbig hinterlegt werden kann.

Das Aussehen des Verbatim-Abschnitts kann via CSS gestaltet werden.
Der Abschnitt verwendet fünf CSS-Klassen:

[CLASS]

    Die Klasse des umgebenden Div (Default: 'verbatim').

=over 4

=item CLASS-table

Die Tabelle.

=item CLASS-ln

Die Zeilennummern-Spalte der Tabelle.

=item CLASS-margin

Die Trenn-Spalte der Tabelle zwischen Zeilennummer- und
Text-Spalte.

=item CLASS-text

Die Text-Spalte der Tabelle.

=back

CLASS ist hierbei der über das Attribut C<class> änderbarer
CSS-Klassenname. Default ist 'verbatim'.

Der CSS-Code kann mittels der Klassenmethode $class->css()
erzeugt werden. Beschreibung siehe dort.

=head1 ATTRIBUTES

=over 4

=item class => $name (Default: 'verbatim')

CSS-Klasse des Verbatim-Abschnitts. Subelemente erhalten diesen
Klassennamen als Präfix.

=item id => $name

Die CSS-Id des Verbatim-Abschnitts.

=item ln => $n (Default: 0)

Wenn ungleich 0, wird jeder Zeile eine Zeilennummer vorangestellt,
beginnend Zeilennummer $n.

=item style => $style

CSS-Properties des Verbatim-Abschnitts.

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
        class => 'verbatim',
        id => undef,
        ln => 0,
        style => undef,
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

    my ($class,$id,$ln,$style,$text) = $self->get(qw/class id ln style text/);

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
            [class=>"$class-ln",$h->tag('pre',$tmp)],
            [class=>"$class-margin",''],
        ;
    }
    
    # Text-Kolumne
    push @cols,[class=>"$class-text",$h->tag('pre',$text)];

    # Erzeuge Tabelle

    return $h->tag('div',
        class => $class,
        id => $id,
        style => $style,
        Sdoc::Core::Html::Table::Simple->html($h,
            class => "$class-table",
            border => undef,
            cellpadding => undef,
            cellspacing => undef,
            rows => [
                [@cols],
            ],
        )
    );
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
