package Sdoc::Core::Css;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.125;

use Sdoc::Core::Path;
use Sdoc::Core::String;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Css - Generiere CSS Code

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 ATTRIBUTES

=over 4

=item format => 'normal', 'flat' (Default: 'normal')

Format des generierten CSS-Code.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere CSS-Generator

=head4 Synopsis

    $css = $class->new($format);

=head4 Arguments

=over 4

=item $format (Default: 'normal')

Format des generierten CSS-Code. Zulässige Werte:

=over 4

=item 'normal'

=back

Der CSS-Code wird mehrzeilig generiert:

    .comment {
        color: #408080;
        font-style: italic;
    }

=over 4

=item 'flat'

=back

Der CSS-Code wird einzeilig generiert:

    .comment { color: #408080; font-style: italic; }

=back

=head4 Returns

Referenz auf CSS-Generator-Objekt.

=head4 Description

Instantiiere ein CSS-Generator-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$format) = @_;

    my $self = $class->SUPER::new(
        format => $format // 'normal',
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 rule() - Generiere CSS Style Rule

=head4 Synopsis

    $rule = $this->rule($selector,\@properties);
    $rule = $this->rule($selector,@properties);

=head4 Description

Generiere eine CSS Style Rule, bestehend aus Selector $selector
und den Property/Value-Paaren @properties und liefere
diese als Zeichenkette zurück.

=head4 Example

Erzeuge eine einfache Style Rule:

    $rule = Sdoc::Core::Css->rule('p.abstract',
        fontStyle=>'italic',
        marginLeft=>'0.5cm',
        marginRight=>'0.5cm',
    );

liefert

    p.abstract {
        font-style: italic;
        margin-left: 0.5cm;
        margin-right: 0.5cm;
    }

=cut

# -----------------------------------------------------------------------------

sub rule {
    my $this = shift;
    my $selector = shift;
    my $propertyA = ref $_[0]? shift: \@_;

    my $self = ref $this? $this: $this->new;
    my $flat = $self->{'format'} eq 'flat'? 1: 0;

    my $rule = '';
    for (my $i = 0; $i < @$propertyA; $i += 2) {
        my $prop = $propertyA->[$i];
        my $val = $propertyA->[$i+1];

        $prop =~ s/([a-z])([A-Z])/$1-\L$2/g;

        if (defined $val && $val ne '') {
            $rule .= $flat? "$prop: $val; ": "    $prop: $val;\n";
        }
    }

    if ($rule) {
        #  Wir erzeugen nur dann eine Regel, wenn sie Definitionen enthält
        $rule = $flat? "$selector { $rule}\n": "$selector {\n$rule}\n";
    }

    return $rule;
}

# -----------------------------------------------------------------------------

=head3 rules() - Generiere mehrere CSS Style Rules

=head4 Synopsis

    $rules = $css->rules($selector=>\@properties,...);

=head4 Arguments

=over 4

=item $selector

CSS-Selector. Z.B. 'p.abstract'.

=item \@properties

Liste von Property/Wert-Paaren. Z.B. [color=>'red',fontStyle=>'italic'].

=back

=head4 Returns

CSS-Regeln (String)

=head4 Description

Wie $css->rule(), nur für mehrere CSS-Regeln auf einmal.

=cut

# -----------------------------------------------------------------------------

sub rules {
    my $self = shift;
    # @_: $selector=>\@properties,...

    my $rules = '';
    while (@_) {
        $rules .= $self->rule(shift,shift);
    }

    return $rules;
}

# -----------------------------------------------------------------------------

=head3 rulesFromObject() - Generiere CSS Style Rules aus Objekt

=head4 Synopsis

    $rules = $css->rulesFromObject($obj,
        $key => [$selector,@properties],
        ...
    );

=head4 Arguments

=over 4

=item $obj

Das Objekt, aus dessen Objektattributen $key, ... die
CSS-Regeln generiert werden.

=item $key => [$selector,@properties], ...

Der Objekt-Attribut $key zugrunde liegende CSS-Selektor $selector
und dessen Default-Properties @properties. Es kann eine Liste
solcher Definitionen angegeben werden.

=back

=head4 Returns

CSS-Regeln (String)

=head4 Example

Beispiel aus Sdoc::Core::Html::Verbatim:

    $rules .= $css->rulesFromObject($self,
        cssTableProperties => [".$prefix-table"],
        cssLnProperties => [".prefix-ln",color=>'#808080'],
        cssMarginProperties => [".$prefix-margin",width=>'0.6em'],
        cssTextProperties => [".prefix-text"],
    );

=cut

# -----------------------------------------------------------------------------

sub rulesFromObject {
    my $self = shift;
    my $obj = shift;
    # @_: $key => [$selector,@properties], ...

    my $rules = '';
    for (my $i = 0; $i < @_; $i += 2) {
        my $key = $_[$i];
        my ($selector,@defaults) = @{$_[$i+1]};
        my $propA = $obj->get($key);

        my (@prop,$op);
        if ($propA) {
            @prop = @$propA;
            if (@prop % 2 == 1) {
                $op = shift @prop;
            }
        }
        if (!$propA || defined($op) && $op eq '+') {
            unshift @prop,@defaults;
        }
        $rules .= $self->rule($selector,@prop);
    }

    return $rules;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 style() - Generiere StyleSheet-Tags

=head4 Synopsis

    $styleTags = Sdoc::Core::Css->style($h,@specs);

=head4 Arguments

=over 4

=item @specs

Liste von Style-Spezifikationen.

=back

=head4 Description

Übersetze die Style-Spezifikationen @specs in eine Folge von
<link>- und/oder <style>-Tags.

Mögliche Style-Spezifikationen:

=over 4

=item "inline:$file":

Datei $file wird geladen und ihr Inhalt wird hinzugefügt.

=item $string (Zeichenkette mit enthaltenen '{')

Zeichenkette $string wird hinzugefügt.

=item $url (Zeichenkette ohne '{'):

Zeichenkette wird als URL interpretiert und ein <link>-Tag

    <link rel="stylesheet" type="text/css" href="$url" />

hinzugefügt.

=item \@specs (Arrayreferenz):

Wird zu @specs expandiert.

=back

=head4 Example

B<Code zum Laden eines externen Stylesheet:>

    $style = Sdoc::Core::Css->style('/css/stylesheet.css');
    =>
    <link rel="stylesheet" type="text/css" href="/css/stylesheet.css" />

B<Stylesheet aus Datei einfügen:>

    $style = Sdoc::Core::Css->style('inline:/css/stylesheet.css');
    =>
    <Inhalt der Datei /css/stylesheet.css>

B<Mehrere Stylesheet-Spezifikationen:>

    $style = Sdoc::Core::Css->style(
        '/css/stylesheet1.css'
        '/css/stylesheet2.css'
    );
    =>
    <link rel="stylesheet" type="text/css" href="/css/stylesheet1.css" />
    <link rel="stylesheet" type="text/css" href="/css/stylesheet2.css" />

B<Mehrere Stylesheet-Spezifikationen via Arrayreferenz:>

    $style = Sdoc::Core::Css->style(
        ['/css/stylesheet1.css','/css/stylesheet2.css']
    );

Dies ist nützlich, wenn die Spezifikation von einem Parameter
einer umgebenden Methode kommt.

=cut

# -----------------------------------------------------------------------------

sub style {
    my $class = shift;
    my $h = shift;
    # @_: @spec

    my $linkTags = '';
    my $style = '';

    while (@_) {
        my $spec = shift;

        if (ref $spec) {
            unshift @_,@$spec;
            next;
        }
        elsif (!defined $spec || $spec eq '') {
            next;
        }
        elsif ($spec =~ s/^inline://) {
            my $data = Sdoc::Core::Path->read($spec);
            # FIXME: Optional Kommentare entfernen

            # Leerzeilen entfernen
            $data =~ s|\n\s*\n+|\n|g;

            # /* eof */ und Leerzeichen am Ende entfernen

            $data =~ s|\s+$||;
            $data =~ s|\s*/\* eof \*/$||;

            $style .= "$data\n";
        }
        elsif ($spec =~ /\{/) {
            # Stylesheet-Definitionen, wenn { enthalten
            Sdoc::Core::String->removeIndentation(\$spec);
            $style .= "$spec\n";
        }
        else {
            $linkTags .= $h->tag('link',
                rel=>'stylesheet',
                type=>'text/css',
                href=>$spec,
            );
        }
    }
    
    return $h->cat(
        $linkTags,
        $h->tag('style',
            -ignoreIfNull=>1,
            $style
        ),
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
