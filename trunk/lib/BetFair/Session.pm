

=head1 NAME

BetFair::Session

=head1 SYNOPSIS

This is a factory package to return a valid Betfair session token.

Betfair API mandates that every request to it's API requires a valid
session key. To obtain a session key from the API you need a Betfair account, 
ie. you essentially need to login via you client application.

So this package encapsulates this functionality and stores a key for any 
subsequent requests to other API methods.

=head1 TODO

This is simplistic at the moment. Each session lasts for twenty minutes only.
For every request you make, a new key is returned, so as long as you keep requests coming
you will never be logged out. So I can imagine we need to attach, say, a update_session_key()
method to the BetFair::Request method.

Also need to investigate the 'keepalive' method. Dunno what this is for.

=head1 DEPENDENCIES

This package uses use LWP::UserAgent and HTTP::Request.

=head1 AUTHOR

M Chadburn - July 2006

=cut

package BetFair::Session;

use strict;
use BetFair::Template;
use BetFair::Request;
use BetFair::Parser;
use LWP::UserAgent;
use HTTP::Request;
use BetFair::Trace qw( TRACE );

my $PACKAGE = 'BetFair::Session';
my $VERSION = '';

sub new
{
        my $class = $_[0];
	TRACE("$PACKAGE : Creating new Session", 1);
        my $objref = {
		key => _get_session( $_[1] )
                };
        bless $objref, $class;
	TRACE("$PACKAGE : Session Key is set to '$objref->{key}', something has gone wrong", 1) if $objref->{key} eq 0;
	die() if $objref->{key} eq 0;
        return $objref;
}

sub _get_session
{

 # populate login template 
 my $params = shift;
 my $t = new BetFair::Template;
 my $message = $t->populate( 'login', $params );

 # make the login request
 my $r = new BetFair::Request;
 $r->message( $message, 'login' );
 $r->request();

 # debug request response
 #print "response : " . $r->{response} if ( $DEBUG );

 # pluck session token from response

 my $x = new BetFair::Parser( { 'message' => $r->{response} } );
 my $session = $x->get_sessionToken();
 
 my $error = $x->get_responseError();

 return 0 if $error ne 'OK';

 return $session;

}

1;

