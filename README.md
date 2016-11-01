NAME
====

(WIP) UNIX::Daemonize - run external commands or Perl6 code as daemons

SYNOPSIS
========

    use UNIX::Daemonize;
    daemonize(<xcowsay mooo>, :repeat, :pid-file</var/lock/mycow>);

Then if you're not a fan of cows repeatedly jumping at you 

    terminate-process-group-from-file("/var/lock/mycow");

You can also daemonize code to be run after daemonize call (note no positional arguments):

    use UNIX::Daemonize;
    daemonize(:pid-file</var/lock/mycow>);
    Promise.in(15).then({exit 0;});
    loop { qq:x/xcowsay moo/; }

DESCRIPTION
===========

UNIX::Daemonize is configurable daemonizing tool written in Perl 6.

Requirements:

    * POSIX compliant OS (fork, umask, setsid …)
    * Perl6
    * xcowsay to run demo above :)

(WIP)

BUGS / CONTRIBUTING
===================

Let me know if you find any bug.

Even better if you could fork and correct it…

TODO: 

    * write spec.

AUTHOR
======

Paweł Szulc <pawel_szulc@onet.pl>

COPYRIGHT AND LICENSE
=====================

Copyright 2016 Paweł Szulc

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
