use v6;
unit module UNIX::Daemonize;
use UNIX::Daemonize::NativeSymbols;
use NativeCall;

sub daemonize-self(*%kwargs) is export {
    return daemonize(%kwargs);
}

sub daemonize(*@executable, Str :$cd, Str :$stderr='/dev/null', 
        Str :$stdout='/dev/null', :%ENV, Str :$pid-file,
        Bool :$repeat, Bool :$shell,
        ) is export {
    my $daemonize-self = !@executable;
    if $daemonize-self {
        fork() && exit 0; # main thread exits, daemon will its place
    } else {
    say $pid-file.IO.abspath ~ ":  " ~ $pid-file.IO.e;
        fork() && return 0; # return to main thread, daemon will do following
    };
    say $pid-file.IO.abspath ~ ":  " ~ $pid-file.IO.e;
    fail "Can't detach" if setsid() < 0;
    fork() && exit 0;
    #with %ENV {
        #for %ENV.kv -> $k, $v {
            #%*ENV{$k} = $v;
        #}
    #}
    say $pid-file.IO.abspath ~ ":  " ~ $pid-file.IO.e;
    chdir $cd with $cd;
    say $pid-file.IO.abspath ~ ":  " ~ $pid-file.IO.e;
    with $pid-file {
        lockfile-or-fail($pid-file); #or fail "WOLOLO";   
        "Created i think".say;
    }
    # setsid again to make PID == PGID
    fail "Can't detach" if setsid() < 0;
    umask(0);
    ($*OUT,$*ERR,$*IN)».close;
    $*OUT = open($stdout, :w) or fail "Can't open $stdout for writing";
    $*ERR = open($stderr, :w) or fail "Can't open $stderr for writing";
    if $daemonize-self {
        # clean up after you're done
        END { lockfile-remove("$pid-file") with $pid-file;};
        return 0; 
    } else {
        run-main-command(:@executable, :$shell, :$repeat);
        lockfile-remove("$pid-file") with $pid-file;
        exit 0;
    }
}

sub run-main-command(:@executable, :$shell, :$repeat) {
    "main comm".say;
    if $repeat {
        loop {
            if !$shell {
                run @executable, :out($*OUT), :err($*ERR);
            }
            else {
                shell @executable.join(' ');
            }
        }
    } else {
        if !$shell {
            run @executable, :out($*OUT), :err($*ERR);
        }
        else {
            shell @executable.join(' ');
        }
    }
}


sub accepts-signals(Int $pid --> Bool ) is export {
    kill($pid, 0) == 0 ?? True !! False;
}

sub is-alive(Int $pid) is export {
# alive if either kill 0 ok, or sending signals not permitted
    if kill($pid, 0) == 0 or cglobal('libc.so.6', 'errno', int32) == 1 {
        return True;
    } else {
        return False;
    }
}
#=any process from process group alive?
sub pg-alive(Int $pgid) is export {
    is-alive(-abs($pgid));
}
sub fork-or-fail is export {
    my $rv = fork();
    return $rv if $rv >= 0; 
    fail "Can't fork";
}

#=tries to terminate all processes from given Process Group
#=Int $pgid - PGID of processes to kill
#=Bool :$force - SIGKILL is sent instead SIGTERM
#=Bool :$verbose - be verbose
#=Num :$timeout - NOT IMPLEMENTED! fails if after $timeout seconds some processes still alive 
sub terminate-process-group(Int $pgid, Bool :$force, Bool :$verbose, Num :$timeout) is export {
    "Terminating PG $pgid".say if $verbose;;
    my $sig-num = $force ?? SignalNumbers::KILL !! SignalNumbers::TERM;
    while pg-alive($pgid) {
        kill(-abs($pgid),$sig-num);   
    }
}

#=terminates whole process group connected with pid-file, removes lockfile if succeeds
sub terminate-process-group-from-file(Str $pid-file, Bool :$force, Bool :$verbose, Num :$timeout) is export {
    if lockfile-valid($pid-file) {
        "Found valid lockfile, terminating".say if $verbose;
        my $pid = slurp($pid-file).Int;
        terminate-process-group($pid, :$force, :$timeout);
        return lockfile-remove($pid-file) unless pg-alive($pid);
        fail "some processes still alive";
    } else {
        fail "No valid lockfile";    
    }
}

sub pid-from-pidfile(Str $pid-file --> Int ) is export {
    fail ("File doesn't exist") unless $pid-file.IO.e;
    return slurp($pid-file).Int;
}

sub lockfile-or-fail($pid-file) is export {
    say $pid-file.IO.abspath ~ ":  " ~ $pid-file.IO.e;
    return lockfile-create($pid-file);
}

sub lockfile-valid($pid-file) is export {
    return False unless $pid-file.IO.abspath.IO.e;
    my $pid = pid-from-pidfile($pid-file); # || return False;
    return is-alive($pid);
}
sub lockfile-remove($pid-file) is export {
    try { 
        $pid-file.IO.unlink;
    }
}

sub lockfile-create($pid-file) is export {
    my $valid =  lockfile-valid($pid-file);
    fail ("Lockfile exists and valid") if $valid;
    fail ("Can't write to file $pid-file") unless $pid-file.IO.spurt($*PID);
    return True;
}

=begin pod

=head1 NAME

(WIP) UNIX::Daemonize - run external commands or Perl6 code as daemons

=head1 SYNOPSIS

  use UNIX::Daemonize;
  daemonize(<xcowsay mooo>, :repeat, :pid-file</var/lock/mycow>);

Then if you're not a fan of cows repeatedly jumping at you 

  terminate-process-group-from-file("/var/lock/mycow");

You can also daemonize code to be run after daemonize call (note no positional arguments):
    
  use UNIX::Daemonize;
  daemonize(:pid-file</var/lock/mycow>);
  Promise.in(15).then({exit 0;});
  loop { qq:x/xcowsay moo/; }


=head1 DESCRIPTION

UNIX::Daemonize is configurable daemonizing tool written in Perl 6.

Requirements:

 * POSIX compliant OS
 * Perl6
 * liblockfile1 
 * xcowsay to run demo above :)

...

=head1 BUGS / CONTRIBUTING

Let me know if you find any bug.

Even better if you could fork and correct it…

TODO: 

 * remove liblockfile dependency (?)

=head1 AUTHOR

Paweł Szulc <pawel_szulc@onet.pl>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
