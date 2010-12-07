package FusionInventory::Agent::XML::Query;

use strict;
use warnings;

use XML::TreePP;

use FusionInventory::Logger;

sub new {
    my ($class, %params) = @_;

    die "no deviceid parameter" unless $params{deviceid};

    my $self = {
        logger   => $params{logger} || FusionInventory::Logger->new(),
        deviceid => $params{deviceid}
    };
    bless $self, $class;

    $self->{h} = {
        QUERY    => ['UNSET!'],
        DEVICEID => [$params{deviceid}]
    };

    return $self;
}

sub getContent {
    my ($self, $args) = @_;

    my $tpp = XML::TreePP->new(indent => 2);
    return $tpp->write( { REQUEST => $self->{h} } );
}

sub setAccountInfo {
    my ($self, %params) = @_;

    while (my ($key, $value) = each %params) {
        push @{$self->{h}->{CONTENT}->{ACCOUNTINFO}}, {
            KEYNAME  => $key,
            KEYVALUE => $value
        }
    }
}

1;
__END__

=head1 NAME

FusionInventory::Agent::XML::Query - Base class for agent messages

=head1 DESCRIPTION

This is an abstract class for all XML query messages sent by the agent to the
server.

=head1 METHODS

=head2 new(%params)

The constructor. The following parameters are allowed, as keys of the %params
hash:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<deviceid>

the agent identifier (mandatory)

=back

=head2 getContent

Get XML content.

=head2 setAccountInfo(%params)

Set account informations for this message.
