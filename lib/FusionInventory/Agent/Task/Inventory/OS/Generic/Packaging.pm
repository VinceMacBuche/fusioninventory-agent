package FusionInventory::Agent::Task::Inventory::OS::Generic::Packaging;

use strict;
use warnings;

sub isInventoryEnabled {
    my (%params) = @_;

    return !$params{no_software};
}

sub doInventory { }

1;
