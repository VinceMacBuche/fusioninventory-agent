package FusionInventory::Agent::Task::Inventory::OS::Linux::Archs::PowerPC::CPU;

use strict;
use warnings;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Linux;

#processor       : 0
#cpu             : POWER4+ (gq)
#clock           : 1452.000000MHz
#revision        : 2.1
#
#processor       : 1
#cpu             : POWER4+ (gq)
#clock           : 1452.000000MHz
#revision        : 2.1
#
#timebase        : 181495202
#machine         : CHRP IBM,7029-6C3
#
#

sub isInventoryEnabled {
    return -r '/proc/cpuinfo';
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

        my $speed;
        if (
            $cpu->{clock} &&
            $cpu->{clock} =~ /(\d+)/
        ) {
            $speed = $1;
        }

        my $manufacturer;
        if ($cpu->{machine} &&
            $cpu->{machine} =~ /IBM/
        ) {
            $manufacturer = 'IBM';
        }

        push @cpus, {
            NAME         => $cpu->{cpu},
            MANUFACTURER => $manufacturer,
            SPEED        => $speed
        };
    }

    return @cpus;
}

1;
