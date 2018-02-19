package Sdoc::Core::Shell;
BEGIN {
    $INC{'Sdoc::Core/Shell.pm'} ||= __FILE__;
}
use base qw/Sdoc::Core::Hash/;

use strict;
use warnings;
use utf8;

our $VERSION = 1.124;

use Time::HiRes ();
use Sdoc::Core::Option;
use Sdoc::Core::Converter;
use Sdoc::Core::Path;
use Sdoc::Core::Process;
use Cwd ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Sdoc::Core::Shell - Ausführung von Shell-Kommandos

=head1 BASE CLASS

L<Sdoc::Core::Hash>

=head1 METHODS

=head2 Konstruktor/Destruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $sh = $class->new(@opt);

=head4 Options

=over 4

=item cmdPrefix => $str (Default: '')

Zeichenkette, der jeder Kommandozeile im Log vorangestellt wird.

=item dryRun => $bool (Default: 0)

Führe Kommandos nicht aus, sondern logge sie nur (impliziert log=>1).

=item log => $bool (Default: 0)

Log Commands to STDOUT.

=item logDest => $fd (Default: *STDOUT)

Datei-Deskriptor, auf den die Logmeldungen geschrieben werden.

=item msgPrefix => $str (Default: '')

Zeichenkette, die jeder Meldung im Log vorangestellt wird.

=item quiet => $bool

Unterdrck stdout und stderr.

=item time => $bool (Default: 0)

Gib nach jedem Kommando die Zeit aus, die es benötigt hat.

=item timePrefix => $str (Default: '')

Zeichenkette, die jeder Zeitausgabe vorangestellt wird.

=item timeSummary => $bool (Default: 0)

Gib zum Schluss bei der Destrukturierung des Objekts
die Gesamtausführungszeit aus.

=back

=head4 Description

Instantiiere ein Shell-Objekt, und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        cmdPrefix=>'',
        dryRun=>0,
        dirStack=>[],
        log=>0,
        logDest=>*STDOUT,
        msgPrefix=>'',
        quiet=>0,
        time=>0,
        timePrefix=>'',
        timeSummary=>0,
        t0=>Time::HiRes::gettimeofday,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head3 DESTROY() - Destruktor

=head4 Synopsis

    $sh->%METH;

=head4 Description

Wenn timeSummary gesetzt ist, wird im Zuge der Destruktuierung
die Gesamtausführungszeit für alle Kommandos, die über das
Shell-Objekt ausgeführt wurden, ausgegeben.

=cut

# -----------------------------------------------------------------------------

sub DESTROY {
    my $self = shift;

    if ($self->{'timeSummary'}) {
        (my $prog = $0) =~ s|.*/||;
        my $pre = $self->{'msgPrefix'};
        my $t = Time::HiRes::gettimeofday - $self->{'t0'};
        my $fd = $self->{'logDest'};
        printf $fd "%sAusführungszeit %s: %d Min. %d Sek.\n",
            $pre,$prog,$t/60,$t%60;
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Kommando ausführen

=head3 exec() - Führe Kommando aus

=head4 Synopsis

    $str|@arr = $this->exec($cmd,@opt);

=head4 Options

=over 4

=item -capture => $channels (Default: keiner)

Liefere die die Programmausgabe auf dem Kanal bzw. den Kanälen
$channels zurück. Mögliche Werte für $channels:

=over 4

=item 'stdout'

Liefere Ausgabe auf stdout, unterdrücke stderr.

=item 'stderr'

Liefere Ausgabe auf stderr, unterdrücke stdout.

=item 'stdout+stderr'

Liefere Ausgabe auf stdout und stderr zusammen.

=item 'stdout,stderr'

Liefere Ausgabe auf stdout und stderr getrennt.

=back

Für Beispiele siehe Abschnitt L</exec/Examples>.

=item -quiet => $bool (Default: 0)

Unterdrücke Programmausgabe auf stdout und stderr.

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn das Programm fehlschlägt, sondern
liefere dessen Exitcode. Ist gleichzeitig die Option -capture angegeben,
hat diese hinsichtlich des Rückgabewerts Priorität.

=back

=head4 Returns

Der Rückgabewert richtet sich nach den Optionen @opt. Ist -capture
definiert, wird die angegebene Programmausgabe geliefert. Ist
-sloppy wahr, wird der Exitcode geliefert. Die Option -capture hat
Priorität gegenüber der Option -sloppy.  Sind weder -capture noch
-sloppy angegeben, liefert die Methode keinen Wert.

=head4 Description

Führe Kommando $cmd aus. Im Falle eines Fehlers löse eine Exception aus.

Beginnt das Kommando $cmd mit einem Bindestrich, wird
implizit die Option -sloppy gesetzt.

=head4 Examples

Unterdrücke Ausgabe auf stdout und stderr:

    $this->exec($cmd,-quiet=>1);

Liefere Ausgabe auf stdout:

    $stdout = $this->exec($cmd,-capture=>'stdout');

Liefere Ausgabe auf stderr:

    $stderr = $this->exec($cmd,-capture=>'stderr');

Liefere Ausgabe auf stdout und stderr zusammen:

    $output = $this->exec($cmd,-capture=>'stdout+stderr');

Liefere Ausgabe auf stdout und stderr getrennt:

    ($stdout,$stderr) = $this->exec($cmd,-capture=>'stdout,stderr');

Keine Exception, liefere Exitcode:

    $exitCode = $this->exec($cmd,-sloppy=>1);

=cut

# -----------------------------------------------------------------------------

sub exec {
    my $self = ref $_[0]? shift: shift->new;
    my $cmd = shift;

    # Optionen

    my $capture = undef;
    my $quiet = $self->get('quiet');
    my $sloppy = 0;

    if (@_) {
        Sdoc::Core::Option->extract(\@_,
            -capture=>\$capture,
            -quiet=>\$quiet,
            -sloppy=>\$sloppy,
        );
    }

    # Exception?

    my $except = 1; # löse Exception aus
    if ($sloppy || $cmd =~ s/^-//) {
        $except = 0;
    }

    # Umleitungen aufsetzen

    if ($quiet) {
        $cmd = "($cmd) >/dev/null 2>&1";
        $capture = undef;
    }

    my $qx = 0;
    my $stdoutFile = "/tmp/$$.stdout";
    my $stderrFile = "/tmp/$$.stderr";

    if (!$capture) {
        # nichts tun
    }
    elsif ($capture eq 'stdout') {
        $cmd = "($cmd) 2>/dev/null";
        $qx = 1;
    }
    elsif ($capture eq 'stderr') {
        $cmd = "($cmd) 2>&1 1>/dev/null";
        $qx = 1;
    }
    elsif ($capture eq 'stdout+stderr') {
        $cmd = "($cmd) 2>&1";
        $qx = 1;
    }
    elsif ($capture eq 'stdout,stderr') {
        $cmd = "($cmd) 1>$stdoutFile 2>$stderrFile";
    }
    else {
        $self->throw(
            q~CMD-00004: Ungültiger Wert für -capture~,
            Capture=>$capture,
        );
    }

    #if ($quiet) {
    #    $cmd = "($cmd) 1>/dev/null 2>/dev/null";
    #}

    # Kommando protokollieren

    my $dryRun = $self->{'dryRun'};
    my $log = $self->{'log'};

    if ($log || $dryRun) {
        my $pre = $self->{'cmdPrefix'};
        my $fd = $self->{'logDest'};
        print $fd "$pre$cmd\n";
    }

    # Kommando ausführen

    my $exit = 0;
    my $output;
    unless ($dryRun) {
        my $t0 = Time::HiRes::gettimeofday;
        if ($qx) {
            $output = qx/$cmd/;
        }
        else {
            system $cmd;
        }
        $exit = $?;
        my $t1 = Time::HiRes::gettimeofday;
        if ($log && $self->{'time'}) {
            my $fd = $self->{'logDest'};
            # printf $fd "/* %.2f */\n",$t1-$t0;
            printf "%s%s\n",$self->{'timePrefix'},
                Sdoc::Core::Converter->epochToDuration($t1-$t0,1,3);
        }
        if ($except) {
            # geht sonst beim Autoload von checkError() verloren
            my $msg = $!;
            $self->checkError($exit,$msg,$cmd);
        }
    }

    # Returnwerte

    if ($capture) {
        if ($capture eq 'stderr+stdout') {
            my $stdout = Sdoc::Core::Path->read($stdoutFile,-delete=>1);
            my $stderr = Sdoc::Core::Path->read($stderrFile,-delete=>1);
            return ($stdout,$stderr);
        }
        return $output;
    }
    elsif (!$except) {
        if ($exit > 255) {
            $exit = int($exit/256);
        }
        return $exit;
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Arbeitsverzeichnis wechseln

=head3 cd() - Wechsele das Arbeitsverzeichnis

=head4 Synopsis

    $sh->cd($dir);

=head4 Returns

Die Methode liefert keinen Wert zurück.

=head4 Description

Wechsle in Arbeitsverzeichnis $dir. Anmerkung: Diese Änderung gilt
für den gesamten Prozess, nicht nur für das Shell-Objekt.

=cut

# -----------------------------------------------------------------------------

sub cd {
    my ($self,$dir) = @_;

    my $dryRun = $self->{'dryRun'};
    my $log = $self->{'log'};

    if ($log || $dryRun) {
        my $pre = $self->{'cmdPrefix'};
        my $fd = $self->{'logDest'};
        print $fd "${pre}cd $dir\n";
    }

    my $cwd = Sdoc::Core::Process->cwd;
    unless ($dryRun) {
        my $t0 = Time::HiRes::gettimeofday;
        Sdoc::Core::Process->cwd($dir);
        my $t1 = Time::HiRes::gettimeofday;

        if ($log && $self->{'time'}) {
            my $fd = $self->{'logDest'};
            printf $fd "/* %4.2f sec */\n",$t1-$t0;
        }
    }
    push @{$self->{'dirStack'}},$cwd;

    return;
}

# -----------------------------------------------------------------------------

=head3 back() - Wechsele ins vorige Arbeitsverzeichnis zurück

=head4 Synopsis

    $this->back;

=cut

# -----------------------------------------------------------------------------

sub back {
    my $self = shift;

    my $dir = pop @{$self->{'dirStack'}};
    unless ($dir) {
        return;
    }

    my $dryRun = $self->{'dryRun'};
    my $log = $self->{'log'};

    if ($log || $dryRun) {
        my $pre = $self->{'cmdPrefix'};
        my $fd = $self->{'logDest'};
        print $fd "${pre}cd $dir\n";
    }

    unless ($dryRun) {
        my $t0 = Time::HiRes::gettimeofday;
        Sdoc::Core::Process->cwd($dir);
        my $t1 = Time::HiRes::gettimeofday;

        if ($log && $self->{'time'}) {
            my $fd = $self->{'logDest'};
            printf $fd "/* %.2f */\n",$t1-$t0;
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Fehlerbehandlung

=head3 checkError() - Löse Exception bei Kommandofehler aus

=head4 Synopsis

    $this->checkError($code,$errMsg,@cmd);

=head4 Returns

nichts

=head4 Description

Prüfe den Status einer vorhergehenden Programmausführung und löse
eine Execption aus, wenn der Status ungleich 0 ist.

=head4 Examples

Prüfe den Ausführungsstatus von system():

    system($cmd);
    Sdoc::Core::Shell->checkError($?,$!,$cmd);

Prüfe den Ausführungsstatus des Backtick-Operators:

    $str = `$cmd`;
    Sdoc::Core::Shell->checkError($?,$!,$cmd);

=cut

# -----------------------------------------------------------------------------

sub checkError {
    my $this = shift;
    my $errCode = shift;   # $?
    my $errMsg = shift;    # $!
    my $cmd = join ' ',@_; # Kommando

    if ($errCode == 0) {
        return; # ok
    }
    elsif ($errCode == -1) {
        $this->throw(
            q~CMD-00001: Kommando konnte nicht aufgerufen werden~,
            Command=>$cmd,
            ErrorMessage=>$errMsg,
        );
    }
    elsif ($errCode & 127) {       # Abbruch mit Signal
        my $sig = $errCode & 127;  # unterste 8 Bit sind Signalnummer
        my $core = $errCode & 128; # 8. Bit zeigt Coredump an
        $this->throw(
            q~CMD-00003: Kommando wurde abgebrochen~,
            Signal=>$sig.($core? ' (Coredump)': ''),
            Command=>$cmd,
            ErrorMessage=>$errMsg,
        );
    }
    $errCode >>= 8;
    $this->throw(
        q~CMD-00002: Kommando endete mit Fehler~,
        ExitCode=>$errCode,
        Command=>$cmd,
        Cwd=>Cwd::getcwd,
        ErrorMessage=>$errMsg,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.124

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
