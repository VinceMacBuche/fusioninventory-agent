package FusionInventory::Agent::Task::Inventory::OS::Generic::Packaging::Pacman;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return can_run('pacman');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach(`pacman -Q`){
        /^(\S+)\s+(\S+)/;
        my $name = $1;
        my $version = $2;

        $inventory->addSoftware({
            NAME    => $name,
            VERSION => $version
        });
    }
}

1;
