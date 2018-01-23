package Sdoc::Core::Object;

use strict;
use warnings;

our $VERSION = 1.123;

use Scalar::Util ();
use Hash::Util ();
use Sdoc::Core::Stacktrace;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Object - Basisklasse für alle Klassen der Klassenbibliothek

=head1 SYNOPSIS

    package MyClass;
    use base qw/Sdoc::Core::Object/;
    ...

=head1 METHODS

=head2 Instantiierung

=head3 bless() - Blesse Objekt auf Klasse

=head4 Synopsis

    $obj = $class->bless($ref);

=head4 Description

Objektorientierte Syntax für bless(). Blesse Objekt (Referenz) $ref auf
Klasse $class und liefere die geblesste Referenz zurück. Dies geht
natürlich nur, wenn $class eine direkte oder indirekte
Subklasse von Sdoc::Core::Object ist.

Der Aufruf ist äquivalent zu:

    $obj = bless $ref,$class;

=head4 Example

    $hash = Hash->bless({});

=cut

# -----------------------------------------------------------------------------

sub bless {
    my ($class,$ref) = @_;

    if (Scalar::Util::reftype($ref) ne 'HASH') {
        CORE::bless $ref,$class;
    }
    else { # HASH
        local $@;
        eval {CORE::bless $ref,$class};
        if ($@) { # Restricted Hash gelocked
            Hash::Util::unlock_keys(%$ref);
            CORE::bless $ref,$class;
            Hash::Util::lock_keys(%$ref);
        }
    }

    return $ref;
}

# -----------------------------------------------------------------------------

=head3 rebless() - Blesse Objekt auf eine andere Klasse um

=head4 Synopsis

    $obj->rebless($class);

=head4 Description

Blesse Objekt $obj auf Klasse $class um.

Der Aufruf ist äquivalent zu:

    bless $obj,$class;

=head4 Example

    $hash->rebless('MyClass');

=cut

# -----------------------------------------------------------------------------

sub rebless {
    my ($self,$class) = @_;
    $class->bless($self);
    return;
}

# -----------------------------------------------------------------------------

=head2 Exceptions

=head3 throw() - Wirf Exception

=head4 Synopsis

    $this->throw;
    $this->throw(@opt,@keyVal);
    $this->throw($msg,@opt,@keyVal);

=head4 Options

=over 4

=item -stdout => $bool (Default: 0)

Erzeuge die Meldung auf STDOUT (statt STDERR), wenn -warning => 1
gesetzt ist.

=item -stacktrace => $bool (Default: 1)

Ergänze den Exception-Text um einen Stacktrace.

=item -warning => $bool (Default: 0)

Wirf keine Exception, sondern gib lediglich eine Warnung aus.

=back

=head4 Description

Wirf eine Exception mit dem Fehlertext $msg und den hinzugefügten
Schlüssel/Wert-Paaren @keyVal. Die Methode kehrt nur zurück, wenn
Option -warning gesetzt ist.

=cut

# -----------------------------------------------------------------------------

sub throw {
    my $class = ref $_[0]? ref(shift): shift;
    # @_: $msg,@keyVal

    # Optionen nicht durch eine andere Klasse verarbeiten!
    # Die Klasse darf auf keiner anderen Klasse basieren.

    my $stdout = 0;
    my $stacktrace = 1;
    my $warning = 0;

    for (my $i = 0; $i < @_; $i++) {
        if (!defined $_[$i]) {
            next;
        }
        elsif ($_[$i] eq '-stdout') {
            $stdout = $_[$i+1];
            splice @_,$i--,2;
        }
        elsif ($_[$i] eq '-stacktrace') {
            $stacktrace = $_[$i+1];
            splice @_,$i--,2;
        }
        elsif ($_[$i] eq '-warning') {
            $warning = $_[$i+1];
            splice @_,$i--,2;
        }
    }

    my $msg = 'Unerwarteter Fehler';
    if (@_ % 2) {
        $msg = shift;
    }

    # Newlines am Ende entfernen
    $msg =~ s/\n$//;

    # Schlüssel/Wert-Paare

    my $keyVal = '';
    for (my $i = 0; $i < @_; $i += 2) {
        my $key = $_[$i];
        my $val = $_[$i+1];

        # FIXME: überlange Werte berücksichtigen
        if (defined $val) {
            $val =~ s/\s+$//;    # Whitespace am Ende entfernen
        }

        if (defined $val && $val ne '') {
            $key = ucfirst $key;
            if ($warning) {
                if ($keyVal) {
                    $keyVal .= ', ';
                }
                $keyVal .= "$key=$val";
            }
            else {
                $val =~ s/^/    /mg; # Wert einrücken
                $keyVal .= "$key:\n$val\n";
            }
        }
    }

    if ($warning) {
        # Keine Exception, nur Warnung

        my $msg = "WARNING: $msg. $keyVal\n";
        if ($stdout) {
            print $msg;
        }
        else {
            warn $msg;
        }
        return;
    }

    # Bereits generierte Exception noch einmal werfen
    # (nachdem Schlüssel/Wert-Paare hinzugefügt wurden)

    if ($msg =~ /^Exception:\n/) {
        my $pos = index($msg,'Stacktrace:');
        if ($pos >= 0) {
            # mit Stacktrace
            substr $msg,$pos,0,$keyVal;
        }
        else {
            # ohne Stacktrace
            $msg .= $keyVal;
        }
        $msg =~ s/\n*$/\n/; # Meldung endet mit genau einem NL

        die $msg;
    }

    # Generiere Meldung

    $msg =~ s/^/    /mg;
    my $str = "Exception:\n$msg\n";
    if ($keyVal) {
        $str .= $keyVal;
    }

    if ($stacktrace) {
        # Generiere Stacktrace

        my $stack = Sdoc::Core::Stacktrace->asString;
        chomp $stack;
        $stack =~ s/^/    /gm;
        $str .= "Stacktrace:\n$stack\n";
    }

    # Wirf Exception

    die $str;
}

# -----------------------------------------------------------------------------

=head2 Sonstiges

=head3 addMethod() - Erweitere Klasse um Methode

=head4 Synopsis

    $this->addMethod($name,$ref);

=head4 Description

Füge Codereferenz $ref unter dem Namen $name zur Klasse $this hinzu.
Existiert die Methode bereits, wird sie überschrieben.

=head4 Example

    MyClass->addMethod(myMethod=>sub {
        my $self = shift;
        return 4711;
    });

=cut

# -----------------------------------------------------------------------------

sub addMethod {
    my $class = ref $_[0]? ref shift: shift;
    my $name = shift;
    my $ref = shift;

    no warnings 'redefine';
    no strict 'refs';
    *{"$class\::$name"} = $ref;

    return;
}

# -----------------------------------------------------------------------------

=head3 classFile() - Pfad der .pm-Datei

=head4 Synopsis

    $dir = $this->classFile;

=head4 Description

Ermitte den Pfad der .pm-Datei der Klasse $this und liefere
diesen zurück. Die Klasse muss bereits geladen worden sein.

=head4 Example

    $path = Sdoc::Core::Object->classFile;
    ==>
    <PFAD>Sdoc::Core/Object.pm

=cut

# -----------------------------------------------------------------------------

sub classFile {
    my $class = ref $_[0]? ref shift: shift;

    $class =~ s|::|/|g;
    $class .= '.pm';

    return $INC{$class} || $class->throw;
}

# -----------------------------------------------------------------------------

=head3 this() - Liefere Klassenname und Objektreferenz

=head4 Synopsis

    ($class,$self,$isClassMethod) = Sdoc::Core::Object->this($this);
    $class = Sdoc::Core::Object->this($this);

=head4 Description

Liefere Klassenname und Objektreferenz zu Parameter $this und zeige
auf dem dritten Rückgabewert an, ob die Methode als Klassen- oder
Objektmethode gerufen wurde.

Ist $this ein Klassenname (eine Zeichenkette) liefere den Namen selbst
und als Objektreferenz undef und als dritten Rückgabewert 1. Ist
$this eine Objektreferenz, liefere den Klassennamen zur Objektreferenz
sowie die Objektreferenz selbst und als dritten Rückgabewert 0.

=head4 Example

=over 2

=item *

Klassen- sowie Objektmethode:

    sub myMethod {
        my ($class,$self) = Sdoc::Core::Object->this(shift);
    
        if ($self) {
            # Aufruf als Objektmethode
        }
        else {
            # Aufruf als Klassenmethode
        }
    }

=item *

Klassenmethode, die als Objektmethode gerufen werden kann:

    sub mymethod {
        my $class = Sdoc::Core::Object->this(shift);
        ...
    }

=item *

Objektmethode, die als Klassenmethode gerufen werden kann:

    sub myMethod {
        my ($class,$self,$isClassMethod) = Sdoc::Core::Object->this(shift);
    
        $self = $class->new(@_);
    
        # Ab hier ist mittels $self nicht mehr feststellbar,
        # ob die Methode als Klassen- oder Objektmethode gerufen wurde.
        # Die Variable $isclassmethod zeigt es an.
    
        $self->specialMethod if $isClassMethod;
        ...
    }

=back

=cut

# -----------------------------------------------------------------------------

sub this {
    my ($class,$this) = @_;

    if (wantarray) {
        return ref $this? (ref($this),$this,0): ($this,undef,1);
    }
    return ref $this || $this;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.123

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
