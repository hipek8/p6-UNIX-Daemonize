use v6;
use Test;
use UNIX::Daemonize;
plan 4;
# /sbin/init should be alive ;)
subtest {
    ok is-alive(1);
};

subtest {
    my $pidlockfile = ".tmp.lock";
    daemonize(<sleep 2>, :pid-file($pidlockfile));
    # file isn't created immediately, wait a bit
    sleep 0.5;
    my Int $pid = pid-from-pidfile($pidlockfile);
    ok is-alive($pid), "Still alive";
    sleep 2;
    nok pg-alive($pid), "Dead";
    dies-ok {pid-from-pidfile($pidlockfile)}, "No lock";
};

subtest {
    my $pidlockfile = ".tmp.lock";
    daemonize(<sleep 2>, :pid-file($pidlockfile), :repeat);
    # file isn't created immediately, wait a bit
    sleep 0.5;
    my Int $pid = pid-from-pidfile($pidlockfile);
    ok is-alive($pid), "Daemon still alive";
    sleep 2;
    ok is-alive($pid), "Daemon is restarted";
    
    terminate-process-group-from-file($pidlockfile);
    sleep 0.5;
    nok pg-alive($pid), "Now dead";
    nok $pidlockfile.IO.e;
}, "Repeat parameter works";

subtest {
    my $pidlockfile = ".tmp.lock";
    daemonize(<sleep 3>, :pid-file($pidlockfile));
    dies-ok {daemonize(<sleep 3>, :pid-file($pidlockfile));}, "Wont create second";
    ok UNIX::Daemonize::lockfile-valid($pidlockfile);
    sleep 3;
    nok UNIX::Daemonize::lockfile-valid($pidlockfile);
}, "Won't create second daemon";

done-testing;
