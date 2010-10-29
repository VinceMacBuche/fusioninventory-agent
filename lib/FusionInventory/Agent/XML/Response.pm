package FusionInventory::Agent::XML::Response;

use strict;
use warnings;

use XML::TreePP;

use FusionInventory::Logger;

sub new {
    my ($class, $params) = @_;

    die "no content parameters" unless $params->{content};

    my $tpp = XML::TreePP->new(
        force_array   => [ qw/OPTION PARAM/ ],
        attr_prefix   => '',
        text_node_key => 'content'
    );

    my $content = $tpp->parse($params->{content});
    die "content is not an XML message" unless ref $content eq 'HASH';
    die "content is an invalid XML message" unless $content->{REPLY};

    my $self = {
        parsedcontent => $content->{REPLY},
        logger  => $params->{logger} || FusionInventory::Logger->new(),
    };
    bless $self, $class;

    return $self;
}

sub getParsedContent {
    my $self = shift;


    return $self->{parsedcontent};
}

sub getOptionsInfoByName {
    my ($self, $name) = @_;

    my $parsedContent = $self->getParsedContent();

    return unless $parsedContent && $parsedContent->{OPTION};

    foreach my $option (@{$parsedContent->{OPTION}}) {
        next unless $option->{NAME} eq $name;
        return $option->{PARAM}->[0];
    }

    return;
}

1;
__END__

=head1 NAME

FusionInventory::Agent::XML::Response - Generic server message

=head1 DESCRIPTION

This is a generic message sent by the server to the agent.

=head1 METHODS

=head2 new($params)

The constructor. The following parameters are allowed, as keys of the $params
hashref:

=over

=item I<logger>

the logger object to use (default: a new stderr logger)

=item I<content>

the raw XML content

=back

=head2 getParsedContent

Get XML content, parsed as a perl data structure.

=head2 getOptionsInfoByName($name)

Get parameters of a specific option
