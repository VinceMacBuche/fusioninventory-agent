package FusionInventory::Agent::Task::Inventory::OS::Linux::Archs::MIPS;

use strict;
use warnings;

use Config;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

sub isInventoryEnabled { 
    return
        $Config{archname} =~ /^mips/ &&
        -r '/proc/cpuinfo';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $cpu (_getCPUsFromProc($logger, '/proc/cpuinfo')) {
        $inventory->addCPU($cpu);
    }
}

sub _getCPUsFromProc {
    my ($logger, $file) = @_;

    my @cpus;
    foreach my $cpu (getCPUsFromProc(logger => $logger, file => $file)) {

       push @cpus, {
            ARCH => 'MIPS',
            NAME => $cpu->{'cpu model'},
        };
    }

    return @cpus;
}


1;
