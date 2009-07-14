

=head1 NAME

BetFair::Session

=head1 SYNOPSIS

This is a factory package to return a valid Betfair session token.

Betfair API mandates that every request to it's API requires a valid
session key. To obtain a session key from the API you need a Betfair account, 
ie. you essentially need to login via your client application.

So this package encapsulates this functionality and stores a key for any 
subsequent requests to other API methods.

=head1 NOTES

This package will cache the session in ./log/session or other place defined by
the config file in order for the session to be shared across multiple scripts
and calls happening simultaneously. This cache also allows your session to be 
maintained over a log period of time without needing to login all the time.

If you use Betfair::submit_request then your session will be maintained and 
updated as required by internal calls back to this module. Otherwise you will 
need to make sure you keep your session updated as mandated by the Betfair API.

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
use POSIX qw(strftime);

my $PACKAGE = 'BetFair::Session';
my $VERSION = '';

my $conf = new BetFair::Config;


sub new {
    my $class = $_[0];
    TRACE("$PACKAGE : Creating new Session", 1);
    my $objref = {  key => _get_session( $_[1] )  };
    bless $objref, $class;
    TRACE("$PACKAGE : Session Key is set to '$objref->{key}', something has gone wrong", 1) if $objref->{key} eq 0;
    die() if $objref->{key} eq 0;
    return $objref;
}

sub _get_session
{
 
 # look for a cached session token
 my $cache = get_cached_session();
 return $cache if $cache;

 # populate login template 
 my $params = shift;
 my $t = new BetFair::Template;
 my $message = $t->populate( 'login', $params );

 # make the login request
 my $r = new BetFair::Request;
 $r->message( $message, 'login' );
 $r->request();

 # pluck session token from response
 my $x = new BetFair::Parser( { 'message' => $r->{response} } );
 my $session = $x->get_sessionToken();
 
 my $error = $x->get_responseError();

 if ($error ne 'OK') { 
   TRACE("$PACKAGE : Couldn't find session" . $r->{response}, 1);
   return 0;
 }
      
 write_cached_session( $session );
 return $session;

}

sub get_cached_session
 {
 
  # check cache (if it exists) before logging in, if we have a valid cached key we bypass the login sequence
  if ( $conf->{session} && -e $conf->{session} )
  {
      TRACE("$PACKAGE : inspecting local session cache", 1);
      
      open(SESSION, "<".$conf->{session}) || TRACE($!);
      my $cache = <SESSION>; # read 1st line in file
      my ( $timestamp, $key ) = split( /:/, $cache ); # TODO - possibly add 'username' to this
      close SESSION;
      
      # get current time. if less than a 20 minute difference between now and the session assume we have a valid session key
      my $gap = time - $timestamp;
      TRACE("$PACKAGE->get_sessionToken : difference between now and session cache time ($timestamp) is $gap seconds", 1);   
      TRACE("$PACKAGE->get_sessionToken : returning the cached key",1) if ( $gap < 1170 );
      return $key if ( $gap < 1170 ); # 19.5 minutes in seconds
      
  }
  else
  {
      TRACE("$PACKAGE->request log directory '$conf->{session}' does not exist (or logging is switched off)", 1)
  }

  return 0;
  
 }


sub write_cached_session
 {
  my $session = shift;
  if ( $conf->{session} )
  {
   open(SESSION, ">".$conf->{session}) || TRACE($!);
   print SESSION  time . ':' . $session;
   close SESSION;
   return 1;
  }
   
 }

1;

