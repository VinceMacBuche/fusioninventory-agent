package FusionInventory::Agent::Task::Inventory::OS::Linux::Archs::ARM::CPU;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

sub isInventoryEnabled { 
    return -r '/proc/cpuinfo';
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};

    my $cpus = getCPUsFromProc(logger => $params->{logger});

    return unless $cpus;

    foreach my $cpu (@$cpus) {
        $inventory->addCPU({
            ARCH => 'ARM',
            TYPE =>  $cpu->{processor}
        });
    }

}

1;
