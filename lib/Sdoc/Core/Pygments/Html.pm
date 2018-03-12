package Sdoc::Core::Pygments::Html;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.125;

use Sdoc::Core::CommandLine;
use Sdoc::Core::Shell;
use Sdoc::Core::Ipc;
use Sdoc::Core::Unindent;
use Sdoc::Core::Css;
use Sdoc::Core::Html::Table::Simple;
use Sdoc::Core::Html::Page;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Pygments::Html - Syntax Highlighting in HTML

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 METHODS

=head2 Klassenmethoden

=head3 css() - CSS-Information für Highlighting in HTML

=head4 Synopsis

    ($rules,$bgColor) = $class->css;
    ($rules,$bgColor) = $class->css($style);
    ($rules,$bgColor) = $class->css($style,$selector);

=head4 Arguments

=over 4

=item $style (Default: 'default')

Name des Pygments-Style, für den die CSS-Information geliefert wird.

Mögliche Werte: abap, algol, algol_nu, arduino, autumn, borland,
bw, colorful, default, emacs, friendly, fruity, igor, lovelace,
manni, monokai, murphy, native, paraiso-dark, paraiso-light,
pastie, perldoc, rainbow_dash, rrt, tango, trac, vim, vs, xcode.

Die definitiv gültige Liste der Stylenamen liefert die Methode
styles().

=item $selector

CSS-Selektor, der den CSS-Regeln vorangestellt wird. Der Selektor
schränkt den Gültigkeitsbereich der CSS-Regeln auf ein
Parent-Element ein. Ist kein Selektor angegeben, gelten die
CSS-Regeln global.

=back

=head4 Returns

CSS-Regeln und Hintergrundfarbe (String, String)

=head4 Description

Liefere die CSS-Regeln für die Vordergrund-Darstellung von
Syntax-Elementen und die zugehörige Hintergrundfarbe für
Pygments-Style $style.

=cut

# -----------------------------------------------------------------------------

sub css {
    my $class = shift;
    my $style = shift // 'default';
    my $selector = shift // 'D-U-M-M-Y';

    my $c = Sdoc::Core::CommandLine->new('pygmentize');
    $c->addOption(
        -f => 'html',
        -S => $style,
        -a => $selector,
    );

    my $css = Sdoc::Core::Shell->exec($c->command,-capture=>'stdout');

    # Bestimme Hintergrundfarbe, diese muss existieren, da die
    # Forderungrundfarben darauf abgestimmt sind.

    $css =~ s/^$selector\s*\{.*background:\s*(\S+);.*\n//m;
    my $bgColor = $1;
    if (!$bgColor) {
        $class->throw(
            q~PYG-00001: Can't determine main background-color~,
            Style => $style,
            CssRules => $css,
        );
    }

    if ($selector eq 'D-U-M-M-Y') {
        # Entferne Dummy aus den CSS-Regeln
        $css =~ s/^$selector\s+//mg;
    }

    return ($css,$bgColor);
}

# -----------------------------------------------------------------------------

=head3 html() - Quellcode in HTML highlighten

=head4 Synopsis

    $html = $class->html($lang,$code);

=head4 Arguments

=over 4

=item $lang

Die Sprache des Quelltexts $code. In Pygments-Terminiologie
handelt es sich um den Namen eines "Lexers". Die Liste aller
Lexer liefert das Kommando:

    $ pygmentize -L lexers

=item $code

Der Quelltext, der gehighlightet wird.

=back

=head4 Returns

HTML-Code mit gehighlightetem Quelltext (String)

=head4 Description

Liefere den HTML-Code mit dem Syntax-Highlighting für Quelltext $code
der Sprache $lang.

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($class,$lang,$code) = @_;

    # Quelltext highlighten

    my $c = Sdoc::Core::CommandLine->new('pygmentize');
    $c->addOption(
        -f => 'html',
        -l => $lang, # = lexer
    );
    my $html = Sdoc::Core::Ipc->filter($c->command,$code);

    # Nicht benötigte "Umrahmung" des gehighlighteten Code entfernen

    $html =~ s|^<div.*?><pre>(<span></span>)?||;
    $html =~ s|</pre></div>\s*$||;

    return $html;
}

# -----------------------------------------------------------------------------

=head3 styles() - Liste der Pygments-Styles

=head4 Synopsis

    @styles | $styleA = $class->styles;

=head4 Returns

Liste von Pygments Stylenamen (Array of Strings).

=head4 Description

Ermittele die Liste der Namen aller Pygments-Styles und liefere diese
zurück. Im Skalarkontext liefere ein Referenz auf die Liste.

Interaktiv lässt sich die (kommentierte) Liste aller Styles
ermitteln mit:

    $ pygmentize -L styles

=cut

# -----------------------------------------------------------------------------

sub styles {
    my $class = shift;

    # Styles ermitteln

    my $c = Sdoc::Core::CommandLine->new('pygmentize');
    $c->addOption(
        -L => 'styles',
    );
    my $text = Sdoc::Core::Shell->exec($c->command,-capture=>'stdout');
    my @styles = sort $text =~ /^\* (\S+?):/mg;

    return wantarray? @styles: \@styles;
}

# -----------------------------------------------------------------------------

=head3 stylesPage() - HTML-Seite mit allen Styles

=head4 Synopsis

    $html = $class->stylesPage($h,$lang,$code);

=head4 Arguments

=over 4

=item $h

HTML-Generator.

=item $lang

Die Sprache des Quelltexts $code (siehe auch Methode html()).

=item $code

Beispiel-Quelltext der Sprache $lang.

=back

=head4 Returns

HTML-Seite (String)

=head4 Description

Erzeuge für Codebeispiel $code der Sprache (des "Lexers") $lang
eine HTML-Seite mit allen Pygments-Styles und liefere diese
zurück.

Diese Seite bietet Hilfestellung für die Entscheidung, welcher
Style am besten passt.

=head4 Example

Generiere eine Seite mit allen Styles und schreibe sie auf Datei $file:

    my $h = Sdoc::Core::Html::Tag->new;
    my $html = Sdoc::Core::Pygments::Html->stylesPage($h,'perl',q~
        PERL-CODE
    ~));
    Sdoc::Core::Path->write($file,$html);

=cut

# -----------------------------------------------------------------------------

sub stylesPage {
    my ($class,$h,$lang,$code) = @_;

    $code = Sdoc::Core::Unindent->trimNl($code);

    my $css = Sdoc::Core::Css->new('flat');

    my ($rules,$html);
    $rules .= $css->rule('td pre',
        margin => 0,
    );
    for my $style ($class->styles) {
        my ($styleRules,$bgColor) = $class->css($style,".$style");
        $rules .= $css->rule(".$style",
            backgroundColor => $bgColor,
            border => '1px solid #e0e0e0',
            marginLeft => '1em',
            padding => '4px',
        );
        $rules .= $styleRules;

        $html .= $h->tag('h3',$style);
        $html .= Sdoc::Core::Html::Table::Simple->html($h,
            class => $style,
            rows => [[[$h->tag('pre',$class->html($lang,$code))]]],
        );
    }

    return Sdoc::Core::Html::Page->html($h,
        title => 'Pygments Styles',
        styleSheet => $rules,
        body => $html,
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
