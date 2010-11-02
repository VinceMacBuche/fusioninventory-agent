package FusionInventory::Agent::Task::Inventory::OS::BSD::Archs::Alpha;

use strict;
use warnings;

use Config;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return $Config{'archname'} =~ /^alpha/;
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    # sysctl infos

    # example on *BSD: AlphaStation 255 4/232
    my $SystemModel = getSingleLine(command => 'sysctl -n hw.model');

    my $processorn = getSingleLine(command => 'sysctl -n hw.ncpu');

    # dmesg infos

    # NetBSD:
    # AlphaStation 255 4/232, 232MHz, s/n
    # cpu0 at mainbus0: ID 0 (primary), 21064A-2
    # OpenBSD:
    # AlphaStation 255 4/232, 232MHz
    # cpu0 at mainbus0: ID 0 (primary), 21064A-2 (pass 1.1)
    # FreeBSD:
    # AlphaStation 255 4/232, 232MHz
    # CPU: EV45 (21064A) major=6 minor=2

    my ($processort, $processors);
    for (`dmesg`) {
        if (/^cpu[^:]*:\s*(.*)$/i) { $processort = $1; }
        if (/$SystemModel,\s*(\S+)\s*MHz.*$/) { $processors = $1; }
    }

    $inventory->setBios ({
        SMANUFACTURER => 'DEC',
        SMODEL => $SystemModel,
    });

    $inventory->setHardware({
        PROCESSORT => $processort,
        PROCESSORN => $processorn,
        PROCESSORS => $processors
    });

}

1;
