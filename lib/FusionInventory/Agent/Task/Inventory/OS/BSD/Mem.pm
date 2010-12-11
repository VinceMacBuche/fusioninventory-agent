package FusionInventory::Agent::Task::Inventory::OS::BSD::Mem;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled { 	
    return
        can_run('sysctl') &&
        can_run('swapctl');
};

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    # Swap
    my $SwapFileSize;
    my @bsd_swapctl = `swapctl -sk`;
    for (@bsd_swapctl) {
        $SwapFileSize = $1 if /total:\s*(\d+)/i;
    }

    # RAM
    my $PhysicalMemory = getSingleLine(command => 'sysctl -n hw.physmem');
    $PhysicalMemory = $PhysicalMemory / 1024;

    # Send it to inventory object
    $inventory->setHardware({
        MEMORY => sprintf("%i", $PhysicalMemory / 1024),
        SWAP   => sprintf("%i", $SwapFileSize / 1024),
    });
}
1;
