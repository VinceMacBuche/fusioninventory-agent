package FusionInventory::Agent::Task::Inventory::OS::Linux::iLO;

use strict;
use warnings;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Regexp;

sub isInventoryEnabled {
    return unless can_run("hponcfg");
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getFileHandle(
        logger => $logger,
        command => 'hponcfg -aw -'
    );

    return unless $handle;

    my $ipmask;
    my $ipgateway;
    my $speed;
    my $ipsubnet;
    my $ipaddress;
    my $status;

    while (my $line = <$handle>) {
        if ($line =~ /<IP_ADDRESS VALUE="($ip_address_pattern)"\/>/) {
            $ipaddress = $1;
        }
        if ($line =~ /<SUBNET_MASK VALUE="($ip_address_pattern))"\/>/) {
            $ipmask = $1;
        }
        if ($line =~ /<GATEWAY_IP_ADDRESS VALUE="($ip_address_pattern)"\/>/) {
            $ipgateway = $1;
        }
        if ($line =~ /<NIC_SPEED VALUE="([0-9]+)"\/>/) {
            $speed = $1;
        } 
        if ($line =~ /<ENABLE_NIC VALUE="(.)"\/>/) {
            $status = 'Up' if $1 =~ /Y/i;
        }
    }
    close $handle;
    $ipsubnet = getSubnetAddress($ipaddress, $ipmask);

    # Some cleanups
    if ( $ipaddress eq '0.0.0.0' ) { $ipaddress = "" }
    if ( not $ipaddress and not $ipmask and $ipsubnet eq '0.0.0.0' ) { $ipsubnet = "" }
    if ( not $status ) { $status = 'Down' }

    $inventory->addEntry(
        section => 'NETWORKS',
        entry   => {
            DESCRIPTION => 'Management Interface - HP iLO',
            IPADDRESS   => $ipaddress,
            IPMASK      => $ipmask,
            IPSUBNET    => $ipsubnet,
            STATUS      => $status,
            TYPE        => 'Ethernet',
            SPEED       => $speed,
            IPGATEWAY   => $ipgateway,
            MANAGEMENT  => 'iLO',
        }
    );
}

1;
