package Sdoc::Core::Pygments::Html;
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;

our $VERSION = 1.125;

use Sdoc::Core::CommandLine;
use Sdoc::Core::Shell;
use Sdoc::Core::Css;
use Sdoc::Core::Option;
use Sdoc::Core::Ipc;
use Sdoc::Core::Html::Table::Simple;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Pygments::Html - Syntax Highlighting in HTML

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Syntax Highlighter

=head4 Synopsis

    $pyg = $class->new(@keyVal);

=head4 Options

=over 4

=item classPrefix => $str (Default: 'pyg')

Präfix, der, mit Bindestrich getrennt, den CSS Klassennamen
vorangestellt wird.

=back

=head4 Returns

Referenz auf Highlighter-Objekt.

=head4 Description

Instantiiere ein Highlighter-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        classPrefix => 'pyg',
        tableProperties => [
            # 'background-color' => '#f0f0f0',
        ],
        lnColumnProperties => [
            color => '#808080',
        ],
        marginColumnProperties => [
            width => '0.6em',
        ],
        textColumnProperties => [
        ],
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 css() - CSS-Code für HTML Highlighting

=head4 Synopsis

    $css = $pyg->css($style);

=head4 Returns

CSS-Code (String)

=cut

# -----------------------------------------------------------------------------

sub css {
    my ($self,$style) = @_;

    # Objektattribute
    my $prefix = $self->classPrefix;

    # Style-Code erzeugen

    my $c = Sdoc::Core::CommandLine->new('pygmentize');
    $c->addOption(
        -f => 'html',
        -S => $style,
        -a => ".$prefix-code-text",
    );

    my $code = Sdoc::Core::Shell->exec($c->command,-capture=>'stdout');

    # Nachbearbeitung des CSS-Codes:
    # * Definition der <div>-Klasse entfernen, denn
    #   die wollen wir selbst definieren

    $code =~ s|^\.$prefix-code-text\s+\{.*\n||m;

    # Definition der eigenen Regeln

    my $css = Sdoc::Core::Css->new('flat');
    my $rules .= $css->rule(".$prefix-code-table pre",
        margin => 0,
    );
    $rules .= $css->rule(".$prefix-code-table",
        @{$self->tableProperties},
    );
    $rules .= $css->rule(".$prefix-code-ln",
        @{$self->lnColumnProperties},
    );
    $rules .= $css->rule(".$prefix-code-margin",
        @{$self->marginColumnProperties},
    );
    $rules .= $css->rule(".$prefix-code-text",
        @{$self->textColumnProperties},
    );

    return "$rules$code";
}

# -----------------------------------------------------------------------------

=head3 html() - Syntax Highlighting in HTML

=head4 Synopsis

    $html = $pyg->html($h,$lexer,$code,@opt);

=head4 Options

=over 4

=item ln => $n (Default: 0)

Nummeriere die Zeilen, beginnend mit Zeilennummer $n. Wert 0
bedeutet: Keine Zeilennummern.

=back

=head4 Returns

HTML-Code (String)

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($self,$h,$lexer,$code) = splice @_,0,4;
    # @_: @opt

    # Objektattribute
    my $prefix = $self->classPrefix;

    # Optionen

    my $ln = 0;

    Sdoc::Core::Option->extract(\@_,
        -ln => \$ln,
    );

    # Quelltext highlighten

    my $c = Sdoc::Core::CommandLine->new('pygmentize');
    $c->addOption(
        -f => 'html',
        -l => $lexer,
    );
    my $hl = Sdoc::Core::Ipc->filter($c->command,$code);

    # Tabelle erzeugen

    my $lnCount = ($hl =~ tr/\n//)-1; # Anzahl Sourcecode-Zeilen
    $hl =~ s|\s+$||;                  # Whitespace am Ende entfernen
    $hl =~ s|\n+(</pre>)|$1|;         # NL am Ende des pre-Content entfernen
    $hl =~ s|\n|&#10;|g;              # NL in Entities wandeln
    $hl =~ s|^<div.*?>||;             # <div> am Anfang entfernen
    $hl =~ s|</div>$||;               # </div> am Ende entfernen

    my @cols;

    if ($ln) {
        my $lnLast = $ln + $lnCount - 1;
        my $lnMaxWidth = length $lnLast;
        my $tmp;
        for (my $i = $ln; $i <= $lnLast; $i++) {
            if ($tmp) {
                $tmp .= '&#10;';
            }
            $tmp .= sprintf '%*d',$lnMaxWidth,$i;
        }
        push @cols,
            [class=>"$prefix-code-ln",$h->tag('pre',$tmp)],
            [class=>"$prefix-code-margin",''],
        ;
    }
    push @cols,[class=>"$prefix-code-text",$hl];

    return Sdoc::Core::Html::Table::Simple->html($h,
        class => "$prefix-code-table",
        cellpadding => 0,
        rows => [
            [@cols],
        ],
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
