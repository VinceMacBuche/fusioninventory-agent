package FusionInventory::Agent::Worker;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent;
use FusionInventory::Agent::Config;
use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Storage;
use FusionInventory::Agent::Target::Local;
use FusionInventory::Agent::Target::Stdout;
use FusionInventory::Agent::Target::Server;
use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Transmitter;
use FusionInventory::Agent::XML::Query::Prolog;

sub new {
    my ($class, %params) = @_;

    my $self = {
        confdir => $params{confdir},
        datadir => $params{datadir},
        vardir  => $params{vardir},
        debug   => $params{debug}
    };
    bless $self, $class;

    my $config = FusionInventory::Agent::Config->new(
        directory => $params{confdir},
        file      => $params{conffile},
    );
    $self->{config} = $config;

    my $logger = FusionInventory::Agent::Logger->new(
        %{$config->getBlock('logger')},
        backends => [ $config->getValues('logger.backends') ],
        debug    => $self->{debug}
    );
    $self->{logger} = $logger;

    if ($REAL_USER_ID != 0) {
        $logger->info("You should run this program as super-user.");
    }

    $logger->debug("Configuration directory: $self->{confdir}");
    $logger->debug("Data directory: $self->{datadir}");
    $logger->debug("Storage directory: $self->{vardir}");

    my $hostname = getHostname();

    my $storage = FusionInventory::Agent::Storage->new(
        logger    => $logger,
        directory => $self->{vardir}
    );
    my $data = $storage->restore();

    if (
        !defined($data->{previousHostname}) ||
        $data->{previousHostname} ne $hostname
    ) {
        my ($year, $month , $day, $hour, $min, $sec) =
            (localtime(time()))[5,4,3,2,1,0];
        $data->{deviceid} = sprintf "%s-%02d-%02d-%02d-%02d-%02d-%02d",
            $hostname, ($year + 1900), ($month + 1), $day, $hour, $min, $sec;
        $data->{previousHostname} = $hostname;
        $storage->save(data => $data);
    }
    $self->{deviceid} = $data->{deviceid};

    $logger->debug("FusionInventory Agent initialised");

    return $self;
}

sub run {
    my ($self, %params) = @_;

    die 'No target' unless $params{target};
    die 'No task' unless $params{task};

    my $config = $self->{config};
    my $logger = $self->{logger};

    # target selection
    my $target_config = $config->getBlock($params{target});
    die "No configuration section for target $params{target}, aborting"
        unless keys %$target_config;

    my $target_type = $target_config->{type}
        or die "No type for target $params{target}, aborting";

    my $target;
    SWITCH: {
        if ($target_type eq 'stdout') {
            $target = FusionInventory::Agent::Target::Stdout->new(
                id         => $params{target},
                logger     => $logger,
                basevardir => $self->{vardir},
                period     => $target_config->{delaytime},
                format     => $target_config->{format}
            );
            last SWITCH;
        }

        if ($target_type eq 'local') {
            $target = FusionInventory::Agent::Target::Local->new(
                id         => $params{target},
                logger     => $logger,
                basevardir => $self->{vardir},
                period     => $target_config->{delaytime},
                path       => $target_config->{path},
                format     => $target_config->{format}
            );
            last SWITCH;
        }

        if ($target_type eq 'server') {
            $target = FusionInventory::Agent::Target::Server->new(
                id         => $params{target},
                logger     => $logger,
                basevardir => $self->{vardir},
                period     => $target_config->{delaytime},
                url        => $target_config->{url},
                format     => $target_config->{format},
                tag        => $target_config->{tag},
                user       => $target_config->{user},
                password   => $target_config->{password},
                proxy      => $target_config->{proxy},
                cacertdir  => $target_config->{'ca-cert-dir'},
                cacertfile => $target_config->{'ca-cert-file'},
                sslcheck   => $target_config->{'ssl-check'},
            );
            last SWITCH;
        }

        die "Invalid type $target_type for target $params{target}, aborting";
    }

    # task selection
    my $task_config = $config->getBlock($params{task});
    die "No configuration section for task $params{task}, aborting"
        unless keys %$task_config;

    my $task_type = $task_config->{type}
        or die "No type for task $params{task}, aborting";

    my $class = 'FusionInventory::Agent::Task::' . ucfirst($task_type);

    if (!$class->require()) {
        $logger->fatal("Class $class is not installed.");
    }
    if (!$class->isa('FusionInventory::Agent::Task')) {
        $logger->fatal("Class $class is not a FusionInventory task.");
    }

    $logger->info("Running task $params{task} for target $params{target}");

    my $task = $class->new(
        logger      => $logger,
        config      => $config,
        confdir     => $self->{confdir},
        datadir     => $self->{datadir},
    );

    # run task
    $task->run(
        target   => $target,
        deviceid => $self->{deviceid},
        token    => $self->{token},
        debug    => $self->{debug},
    );

}

1;

__END__

=head1 NAME

FusionInventory::Worker - Fusion Inventory worker

=head1 DESCRIPTION

A worker object run a single task against a single target.

=head1 METHODS

=head2 new(%params)

The constructor.

=head2 run(%params)

Run the worker.
