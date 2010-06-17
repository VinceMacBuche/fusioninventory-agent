package FusionInventory::Agent::Task::Ping;

use strict;
no strict 'refs';
use warnings;

use FusionInventory::Agent::Config;
use FusionInventory::Logger;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::XML::Query::SimpleMessage;
use FusionInventory::Agent::XML::Response::Prolog;
use FusionInventory::Agent::Network;

use FusionInventory::Agent::AccountInfo;

sub new {
    my ($class) = @_;

    my $self = {};
    bless $self, $class;

    my $storage = FusionInventory::Agent::Storage->new({
        target => {
            vardir => $ARGV[0],
        }
    });

    my $data = $storage->restore({ module => "FusionInventory::Agent" });
    $self->{data} = $data;
    $self->{myData} = $storage->restore();

    $self->{config} = $data->{config};
    $self->{target} = $data->{target};
    $self->{logger} = FusionInventory::Logger->new({
        config => $self->{config}
    });

    return $self;
}

sub main {
    my $self = FusionInventory::Agent::Task::Ping->new();

    if ($self->{target}->{'type'} ne 'server') {
        $self->{logger}->debug("No server. Exiting...");
        exit(0);
    }

    my $options = $self->{data}->{'prologresp'}->getOptionsInfoByName('PING');
    return unless $options;
    my $option = shift @$options;
    return unless $option;

    $self->{logger}->debug("Ping ID:". $option->{ID});

    my $network = $self->{network} = FusionInventory::Agent::Network->new ({
        logger => $self->{logger},
        config => $self->{config},
        target => $self->{target},
    });

    my $message = FusionInventory::Agent::XML::Query::SimpleMessage->new(                                                               
        {
            config => $self->{config},
            logger => $self->{logger},
            target => $self->{target},
            msg    => {
                QUERY => 'PING',
                ID    => $option->{ID},
            },
        }
    );
    $self->{logger}->debug("Pong!");
    $network->send( { message => $message } );

}

1;
