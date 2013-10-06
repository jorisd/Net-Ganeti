package Net::Ganeti::Instance;

use strict;
use warnings;

sub new {
   my $class = shift;
   my $proto = ref($class) || $class;
   my $self = { @_ };
   bless($self, $proto);
   return $self;
}
}

sub status {

  my $self = shift;
  my $me = $self->name;
  
  my %instances = $self->{gnt}->instance_list;
  
  my $status = $instances{$me}->{data}->{status};
}

sub name {

   my $self = shift;
   
   return $self->{data}->{name};

}

1;