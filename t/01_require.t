#!/usr/local/bin/perl -w

no warnings 'portable';
use 5.6.0;
use strict;
use warnings;

print "1..7\n";

require DNS::Config;
print "ok 1\n";

require DNS::Config::File;
print "ok 2\n";

require DNS::Config::File::Bind9;
print "ok 3\n";

require DNS::Config::Server;
print "ok 4\n";

require DNS::Config::Statement;
print "ok 5\n";

require DNS::Config::Statement::Zone;
print "ok 6\n";

require DNS::Config::Statement::Options;
print "ok 7\n";

