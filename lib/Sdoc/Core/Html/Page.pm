package Sdoc::Core::Html::Page;
use base qw/Sdoc::Core::Html::Base/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.125;

use Sdoc::Core::Css;
use Sdoc::Core::JavaScript;
use Sdoc::Core::Template;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Html::Page - HTML-Seite

=head1 BASE CLASS

L<Sdoc::Core::Html::Base>

=head1 SYNOPSIS

    use Sdoc::Core::Html::Page;
    
    $h = Sdoc::Core::Html::Tag->new;
    
    $obj = Sdoc::Core::Html::Page->new(
        body=>'hello world!',
    );
    
    $html = $obj->html($h);

=head1 ATTRIBUTES

=over 4

=item body => $str (Default: '')

Rumpf der Seite.

=item comment => $str (Default: undef)

Kommentar am Anfang der Seite.

=item encoding => $charset (Default: 'utf-8')

Encoding der Seite, z.B. 'iso-8859-1'.

=item head => $str (Default: '')

Kopf der Seite.

=item noNewline => $bool (Default: 0)

Füge kein Newline am Ende der Seite hinzu.

=item placeholders => \@keyVal (Default: [])

Ersetze im generierten HTML-Code die angegebenen Platzhalter durch
ihre Werte.

=item javaScript => $url|$jsCode|[...] (Default: undef)

URL oder JavaScript-Code im Head der Seite. Mehrfach-Definition,
wenn Array-Referenz. Das Attribut kann mehrfach auftreten, die
Werte werden zu einer Liste zusammengefügt.

=item styleSheet => $spec | \@specs (Default: undef)

Einzelne Style-Spezifikation oder Liste von Style-Spezifikationen.
Siehe Methode Sdoc::Core::Css->style(). Das Attribut kann mehrfach
auftreten, die Werte werden zu einer Liste zusammengefügt.

=item title => $str (Default: undef)

Titel der Seite.

=item topIndentation => $n (Default: 2)

Einrückung des Inhalts der obersten Elemente <head> und <body>.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $obj = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        body=>'',
        comment=>undef,
        encoding=>'utf-8',
        head=>'',
        noNewline=>0,
        placeholders=>[],
        javaScript=>[],
        styleSheet=>[],
        title=>'',
        topIndentation=>2,
    );

    while (@_) {
        my $key = shift;
        my $val = shift;

        if ($key eq 'javaScript' || $key eq 'styleSheet') {
            my $arr = $self->get($key);
            push @$arr,ref $val? @$val: $val;
        }
        else {
            $self->set($key=>$val);
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

    $html = $obj->html($h);
    $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($body,$comment,$encoding,$head,$noNewline,$placeholders,
        $title,$javaScript,$styleSheet,$topIndentation) =
        $self->get(qw/body comment encoding head noNewline placeholders
        title javaScript styleSheet topIndentation/);

    # Stylesheet-Defininition(en)
    my $styleTags = Sdoc::Core::Css->style($h,$styleSheet);

    # Script-Definition(en)

    my $scriptTags = Sdoc::Core::JavaScript->script($h,$javaScript);

    # Wenn $body keinen body-Tag enthält, fügen wir ihn hinzu.

    $body = $h->cat($body);
    if ($body !~ /^<body/i) {
        $body = $h->tag('body',
            -ind=>$topIndentation,
            '-',
            $body,
            $scriptTags,
        );
    }

    my $html = $h->cat(
        $h->doctype,
        $h->comment(-nl=>2,$comment),
        $h->tag('html',
            '-',
            $h->tag('head',
                -ind=>$topIndentation,
                '-',
                $h->tag('title',
                    -ignoreIf=>!$title,
                    '-',
                    $title,
                ),
                $h->tag('meta',
                    'http-equiv'=>'content-type',
                    content=>"text/html; charset=$encoding",
                ),
                $h->cat($head),
                $styleTags,
            ),
            $body,
        ),
    );

    if (@$placeholders) {
        # Platzhalter ersetzen

        my $tpl = Sdoc::Core::Template->new('text',\$html);
        $tpl->replace(@$placeholders);
        $html = $tpl->asString;
    }

    if ($noNewline) {
        chomp $html;
    }

    return $html;
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
