package Net::Ganeti;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw/ instance_list 
                     instance_add
                     instance_remove
                     instance_start
                     instance_stop
                  /;

=head1 NAME

Net::Ganeti - Control your Ganeti Cluster with Net::Ganeti !

This module is a standalone version of Rex's Ganeti recipe :
 
  https://github.com/krimdomu/rex-recipes/tree/0.41/Rex/Cloud/Ganeti

=head1 VERSION

Version 0.01

=cut

use Carp;
use JSON;
use LWP::UserAgent;

use Net::Ganeti::Instance;
use Net::Ganeti::Job;

our $VERSION = '0.01';

=head1 SYNOPSIS

This module uses Ganeti's RAPI to control it.

    use Net::Ganeti;

    # Connect to the cluster.
    # Username and password are required. Patches are welcome otherwise :)
    
    my $gnt = Net::Ganeti->new( user => 'admin',
                                pass => 'secret',
                                host => 'https://10.0.0.1:5080',
                              );
    
    # Returns a hashref. Keys are Instances' name. Values are Net::Ganeti::Instance
    my $instances = $gnt->instance_list;
    
    # Will scan the instances list, and restart any stopped instance.
    foreach my $instance (keys %{$instances}) {
    
       say "$instance is " . $instance->status;
    
       if($instance->status ne 'running') {
          print " restarting... "
          my $jobstatus = $gnt->instance_start($instance);
          
          if($instance->status eq 'running') {
             say 'Success !';
          } else {
             say "Error (job had status $jobstatus)";
          }
       }
       
    }

=cut

sub new {
   my $class = shift;
   my %options = @_;
   
   my $self = { 
                  ua => LWP::UserAgent->new(),
                  %options,
              };

   die "Missing HTTP user" unless defined $self->{user};
   die "Missing HTTP pass" unless defined $self->{pass};

   $self->{ua}->credentials( $self->{host},
                             'Ganeti Remote API',
                             $self->{user},
                             $self->{pass},
                           );
                           
   # this header is required
   $self->{ua}->default_header(Accept => 'application/json');
              
   bless $self, $class;
   
}

sub _request {

   my $self = shift;
   my ($method, $url, $body) = @_;
   
   my $response;
   
   if ($method =~ /^(GET|PUT|DELETE)$/) {
      my $response = $self->{ua}->request($method, $self->{host} . $url);

      if ($response->is_success) {
          return $response->decoded_content;
      }
      else {
          die $response->status_line;
      }
   } elsif($method =~ /^POST$/) {
      $self->{ua}->post($self->{host} . $url,
                        'Content-Type' => 'application/json',
                        Content => $body,
                       );
   } else {
      croak("$method not supported");
   }

}

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 instance_list

Returns a hash containing for keys the instance name, and for values instance data

=cut

sub instance_list {

   my $self = shift;
   my $data = decode_json $self->_request('GET', '/2/instances?bulk=1');
   
   my %ret;

   for my $vm (@{$data}) {
      my $name = $vm->{name};
      $ret{$name} = Net::Ganeti::Instance->new( gnt  => $self,
                                                data => $vm,
                                              );
   }

   return %ret;
}

=head2 instance_add

Add a new instance.

Currently, you must feed it JSON data compatible with Ganeti.

Not really handy, I will add some shortcuts with common features people want.

The function returns the status of the job responsible for the add operation.

=cut

sub instance_add {

   my ($self, %option) = @_;

   my $json = encode_json \%option;
   
   $json->{__version__} = 1; # mandatory!
   
   my $jobid = $self->_request('POST', '/2/instances', $json);
   
   my $job = Net::Ganeti::Job->new( gnt  => $self,
                                    data => { id => $jobid },
                                  );
                                  
   my $state = $job->wait;
   
   return $state;
}

=head2 instance_remove

Removes an instance from the cluster. Be careful, no warnings !!

=cut
sub instance_remove {

   my ($self, $name) = @_;
   
   $name = $name->name if(ref($name));

   my $jobid = $self->_request('DELETE', "/2/instances/$name");
   
   my $job = Net::Ganeti::Job->new( gnt  => $self,
                                    data => { id => $jobid },
                                  );
   my $state = $job->wait;
   
   return $state;             
}

=head2 instance_start

Starts an instance.

You can pass for argument either the instance name, or a Net::Ganeti::Instance object.

=cut

sub instance_start {

   my ($self, $name) = @_;

   $name = $name->name if(ref($name));

   my $jobid = $self->_request('PUT', "/2/instances/$name/startup");
   
   my $job = Net::Ganeti::Job->new( gnt  => $self,
                                    data => { id => $jobid },
                                  );
   my $state = $job->wait;
   
   return $state;
}

=head2 instance_stop

Stops an instance.

You can pass for argument either the instance name, or a Net::Ganeti::Instance object.

=cut
sub instance_stop {

   my ($self, $name) = @_;

   $name = $name->name if(ref($name));

   my $jobid = $self->_request('PUT', "/2/instances/$name/shutdown")
   
   my $job = Net::Ganeti::Job->new( gnt  => $self,
                                    data => { id => $jobid },
                                  );
   my $state = $job->wait;
   
   return $state;
}

sub _job_info {
   my ($self, $id) = @_;
   
   my $data = decode_json $self->_request('GET', "/2/jobs/$id");
                                      
   return Net::Ganeti::Job->new( gnt  => $self,
                                  data => $data,
                                );
   
}

=head1 AUTHOR

Joris, C<< <jorisd at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-ganeti at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-Ganeti>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::Ganeti


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-Ganeti>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-Ganeti>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-Ganeti>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-Ganeti/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Joris.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Net::Ganeti