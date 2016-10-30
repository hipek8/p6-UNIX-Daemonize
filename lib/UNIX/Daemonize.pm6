use v6;
unit module UNIX::Daemonize;
use UNIX::Daemonize::NativeSymbols;
use NativeCall;

sub daemonize(*@executable, Str :$cd, 
    Str :$stderr='/dev/null', Str :$stdout='/dev/null', :%ENV, Str :$pid-file is copy,
    Str :$user, Bool :$repeat) is export {
    fork-or-fail() && exit 0;
    setsid();
    fork-or-fail() && exit 0;
    with %ENV {
        for %ENV.kv -> $k, $v {
            %*ENV{$k} = $v;
        }
    }
    with $pid-file {
        $pid-file = $pid-file.IO.abspath;
        if lockfile_create("$pid-file",0,16) != Lockfile-Return::L_SUCCESS {
            if "$pid-file".IO ~~ :e {
                fail("Can't lock file $pid-file\nService already running on PID " ~ slurp("$pid-file") ~ "Not doing anything…");
            } else {
                fail("Can't lock file $pid-file\nExitting...") ;
            }
        }
    }
    setsid();
    umask(0);
    chdir $cd with $cd;
    my $childOUT = open($stdout, :w) or fail("Can't open $stdout for writing");
    my $childERR = open($stderr, :w) or fail("Can't open $stderr for writing");
    if $repeat {
        loop {
            run @executable, :out($childOUT), :err($childERR);
        }
    } else {
        run @executable, :out($childOUT), :err($childERR);
    }

    with $pid-file {
        lockfile_remove("$pid-file");
    }
}

sub accepts-signals(Int $pid) is export {
    kill($pid, 0) == 0 ?? True !! False;
}

sub is-alive(Int $pid) is export {
    if kill($pid, 0) == 0 or cglobal('libc.so.6', 'errno', int32) == 1 { # sending signals not permitted
        return True;
    } else {
        return False;
    }

}
sub fork-or-fail is export {
    my $rv = fork();
    return $rv if $rv >= 0; 
    fail ("Can't fork");
}

sub terminate-process-group(Int $pgid, Bool :$force, Bool :$verbose) is export {
    "Terminating PG $pgid".say if $verbose;;
    my $sig-num = $force ?? SignalNumbers::KILL !! SignalNumbers::TERM;
    # to kill whole process group use negative number
    kill(-abs($pgid),$sig-num);   
}

sub terminate-process-group-from-file(Str $pid-file, Bool :$force, Bool :$verbose) is export {
    if lockfile_check($pid-file,16) == Lockfile-Return::L_SUCCESS {
        "Lockfile exists, terminating".say if $verbose;
        terminate-process-group(slurp($pid-file).Int, :$force);
    } else {
        fail "No valid lockfile";    
    }
}

=begin pod

=head1 NAME

UNIX::Daemonize - blah blah blah

=head1 SYNOPSIS

  use UNIX::Daemonize;

=head1 DESCRIPTION

UNIX::Daemonize is ...

=head1 AUTHOR

Paweł Szulc <pawel_szulc@onet.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
