# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc2::Link - Definition eines Link

=head1 BASE CLASS

L<Sdoc2::Node>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert die Definition eines Link.

=head1 ATTRIBUTES

=over 4

=item parent => $parent

Verweis auf Superknoten

=item name => $name

Name oder Namen des Link. Mehrere Namen werden mit | getrennt.

=item url => $url

Url des Link

=back

=cut

# -----------------------------------------------------------------------------

package Sdoc2::Link;
use base qw/Sdoc2::Node/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $node = $class->new($doc,$parent,$att);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$doc,$parent,$att) = @_;

    my $root = $parent->rootNode;
    my $linkH = $root->links;

    for my $name (split /\|/,{@$att}->{'name'}) {
        # Objekt instantiieren

        my $self = $class->SUPER::new(
            parent=>undef,
            type=>'Link',
            name=>undef,
            url=>undef,
        );
        $self->parent($root); # schwache Referenz
        $self->set(@$att);
        $self->set(name=>$name);
        $self->lockKeys;

        $linkH->set($name=>$self);
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2021 Frank Seitz

=cut

# -----------------------------------------------------------------------------

1;

# eof
