package FusionInventory::Agent::Task::Inventory::OS::Linux::Softwares;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    my (%params) = @_;

    return !$params{config}->{no_software};
}

sub doInventory {
}

1;
