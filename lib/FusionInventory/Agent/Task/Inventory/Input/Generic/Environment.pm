package FusionInventory::Agent::Task::Inventory::Input::Generic::Environment;

use English qw(-no_match_vars);

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isEnabled {
    # We use WMI for Windows because of charset issue
    return $OSNAME ne 'MSWin32';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    foreach my $key (keys %ENV) {
        $inventory->addEntry(
            section => 'ENVS',
            entry   => {
                KEY => $key,
                VAL => $ENV{$key}
            }
        );
    }
}

1;
