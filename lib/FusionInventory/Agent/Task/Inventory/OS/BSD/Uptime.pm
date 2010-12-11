package FusionInventory::Agent::Task::Inventory::OS::BSD::Uptime;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    my $boottime = getSingleLine(command => 'sysctl -n kern.boottime');
    return $boottime;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $boottime = getSingleLine(command => 'sysctl -n kern.boottime');
    $boottime = $1 if $boottime =~ /sec\s*=\s*(\d+)/;
    my $currenttime = time();
    my $uptime = $currenttime - $boottime;

    # ISO format string conversion
    $uptime = getFormatedGmTime($uptime);

    my $DeviceType = getSingleLine(command => 'uname -m');
    $inventory->setHardware({ DESCRIPTION => "$DeviceType/$uptime" });
}

1;
