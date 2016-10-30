use NativeCall;
unit module UNIX::Daemonize::NativeSymbols;
sub fork() returns int32 is native is export {};
sub kill(int32, int32) returns int32 is native is export {};
sub setsid() returns int32 is native is export {};
sub getpgid(int32) returns int32 is native is export {};
sub umask(uint32) returns uint32 is native is export {};
sub lockfile_create(Str, int32, int32) returns int32 is native('lockfile') is export {};
sub lockfile_remove(Str) returns int32 is native('lockfile') is export {};
sub lockfile_touch(Str) returns int32 is native('lockfile') is export {};
sub lockfile_check(Str, int32) returns int32 is native('lockfile') is export {};

enum Lockfile-Return is export (
     L_SUCCESS  => 0,
     L_NAMELEN  => 1,
     L_TMPLOCK  => 2,
     L_TMPWRITE => 3,
     L_MAXTRYS  => 4,
     L_ERROR    => 5,
     L_MANLOCK  => 6
    );

enum SignalNumbers is export (
       HUP   =>  1,  
       INT   =>  2,  
       QUIT  =>  3,  
       ILL   =>  4,  
       ABRT  =>  6,  
       FPE   =>  8,  
       KILL  =>  9,  
       SEGV  => 11,  
       PIPE  => 13,  
       ALRM  => 14,  
       TERM  => 15,  
       USR1  => 16,
       USR2  => 17,
       CHLD  => 18,
       CONT  => 25,
       STOP  => 23,
       TSTP  => 24,
       TTIN  => 26,
       TTOU  => 27,
);
