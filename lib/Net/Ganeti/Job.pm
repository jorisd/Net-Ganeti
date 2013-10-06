package Net::Ganeti::Job;

use strict;
use warnings;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };
   
   bless($self, $proto);
   return $self;
}

sub wait {

   my $self = shift;
   
   # there should be some kind of timeout to prevent looping if something
   # unknown happens to the job...
   
   while(my $state = $self->status) {
      Rex::Logger::debug('job '. $self->id .' has state: '. $state);
      
      if($state =~ /(?:waiting|running)/) {
         sleep 3; # let's wait some more
         next;
      }
      
      return $state;
   }
   return; # shouldn't be here, ever.

}


sub status {
   my $self = shift;
   
   $self->_get_info;
   # FIXME : Add some checks to make sure the job is still here
   #         if (exists $self->{data}->{status};)
   #         set to "error" to stop the mess.
   return $self->{data}->{status};
}

sub id {

  my $self = shift;
  
  return $self->{data}->{id};
   
}

sub _get_info {
   my $self = shift;

   my $refreshed_job = $self->{gnt}->_job_info($self->id);

   $self->{data} = $refreshed_job->{data};
      
}
1;
