package FusionInventory::Agent::Task::Inventory::OS::Win32::CPU;

use strict;
use warnings;

use English qw(-no_match_vars);
use Win32;
use Win32::TieRegistry (
    Delimiter   => '/',
    ArrayValues => 0,
    qw/KEY_READ/
);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Win32;

# the CPU description in WMI is false, we use the registry instead
# Hardware\Description\System\CentralProcessor\1
# thank you Nicolas Richard 
sub getCPUInfoFromRegistry {
    my ($logger, $cpuId) = @_;

    my $machKey= $Registry->Open('LMachine', {
        Access=> KEY_READ | KEY_WOW64_64
    }) or die "Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR";

    my $data =
        $machKey->{"Hardware/Description/System/CentralProcessor/".$cpuId};

    my $info;

    foreach my $tmpkey (%$data) {
        next unless $tmpkey =~ /^\/(.*)/;
        my $key = $1;

        $info->{$key} = $data->{$tmpkey};
    }

    return $info;
}



sub isInventoryEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $serial;
    my $id;
    my $speed;

    my $vmsystem;

# http://forge.fusioninventory.org/issues/379
    my(@osver) = Win32::GetOSVersion();
    my $isWin2003 = ($osver[4] == 2 && $osver[1] == 5 && $osver[2] == 2);


    my $dmidecodeCpu = getCpusFromDmidecode();

    my $cpuId = 0;
    foreach my $object (getWmiObjects(
        class      => 'Win32_Processor',
        properties => [ qw/NumberOfCores ProcessorId MaxClockSpeed/ ]
    )) {

        my $info = getCPUInfoFromRegistry($logger, $cpuId);

#        my $cache = $object->{L2CacheSize}+$object->{L3CacheSize};
        my $core = $object->{NumberOfCores};
        my $description = $info->{Identifier};
        my $name = $info->{ProcessorNameString};
        my $manufacturer = $info->{VendorIdentifier};
        my $id = $dmidecodeCpu->[$cpuId]->{ID} || $object->{ProcessorId};
        my $serial = $dmidecodeCpu->[$cpuId]->{SERIAL};
        my $speed = $dmidecodeCpu->[$cpuId]->{SPEED} || $object->{MaxClockSpeed};

        if ($manufacturer) {
            $manufacturer =~ s/Genuine//;
            $manufacturer =~ s/(TMx86|TransmetaCPU)/Transmeta/;
            $manufacturer =~ s/CyrixInstead/Cyrix/;
            $manufacturer=~ s/CentaurHauls/VIA/;
        }
        if ($serial) {
            $serial =~ s/\s//g;
        }

        if ($name) {
            $name =~ s/^\s+//;
            $name =~ s/\s+$//;

            $vmsystem = "QEMU"if $name =~ /QEMU/i;

            if ($name =~ /([\d\.]+)s*(GHZ)/i) {
                $speed = {
                    ghz => 1000,
                    mhz => 1,
                }->{lc($2)}*$1;
            }

        }

        $inventory->addCPU({
#           CACHE        => $cache,
            CORE         => $core,
            DESCRIPTION  => $description,
            NAME         => $name,
            MANUFACTURER => $manufacturer,
            SERIAL       => $serial,
            SPEED        => $speed,
	    ID           => $id
        });

        $cpuId++;
    }

    if ($vmsystem) {
        $inventory->setHardware(
            VMSYSTEM => $vmsystem 
        );
    }

}
1;
