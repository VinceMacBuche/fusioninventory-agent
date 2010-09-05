package FusionInventory::Agent::Task::Inventory::OS::Generic::Environment;

use English qw(-no_match_vars);

use strict;
use warnings;

sub isInventoryEnabled {
# We use WMI for Windows because of charset issue
    return $OSNAME ne 'MSWin32';
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    foreach my $key (keys %ENV) {
        $inventory->addEnv({
            KEY => $key,
            VAL => $ENV{$key}
        });
    }
}

1;
