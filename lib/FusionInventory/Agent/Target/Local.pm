package FusionInventory::Agent::Target::Local;

use strict;
use warnings;
use base 'FusionInventory::Agent::Target';

sub new {
    my ($class, %params) = @_;

    die "no path parameter" unless $params{path};

    my $self = $class->SUPER::new(%params);

    $self->{path} = $params{path};

    $self->_init(
        vardir => $params{basevardir} . '/__LOCAL__',
    );

    return $self;
}

sub getDescription {
    my ($self) = @_;

    my $description = $self->SUPER::getDescription();

    $description->{type}        = 'local';
    $description->{destination} = $self->{path};

    return $description;
}

1;

__END__

=head1 NAME

FusionInventory::Agent::Target::Local - Local target

=head1 DESCRIPTION

This is a target for storing execution result in a local folder.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, in addition to those
from the base class C<FusionInventory::Agent::Target>, as keys of the %params
hash:

=over

=item I<path>

the output directory path (mandatory)

=back

=head2 getDescriptionString)

Return a string to display to user in a 'target' field.

