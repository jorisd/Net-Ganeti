#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Ganeti' ) || print "Bail out!\n";
}

diag( "Testing Net::Ganeti $Net::Ganeti::VERSION, Perl $], $^X" );
