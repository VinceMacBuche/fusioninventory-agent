package FusionInventory::Agent::Task::Inventory::OS::MacOS::Drives;

use strict;
use warnings;

use FusionInventory::Agent::Tools::Unix;

sub isInventoryEnabled {
    return 1;
}

my %unitMatrice = (
    Ti => 1000*1000,
    GB => 1024*1024,
    Gi => 1000,
    GB => 1024,
    Mi => 1,
    MB => 1,
    Ki => 0.001,
    KB => 0.001,
);

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my @types = 
        grep { ! /^(?:fdesc|devfs|procfs|linprocfs|linsysfs|tmpfs|fdescfs)$/ }
        getFilesystemsTypesFromMount(logger => $logger);

    my @drives;
    foreach my $type (@types) {
        push @drives, getFilesystemsFromDf(
            logger => $logger,
            command => "df -P -k -t $type"
        );
    }

    my %diskUtilDevices;
    foreach (`diskutil list`) {
        if (/\d+:\s+.*\s+(\S+)/) {
            my $deviceName = "/dev/$1";
            foreach (`diskutil info $1`) {
                $diskUtilDevices{$deviceName}->{$1} = $2 if /^\s+(.*?):\s*(\S.*)/;
            }
        }
    }

    my %drives;

    foreach my $deviceName (keys %diskUtilDevices) {
        my $device = $diskUtilDevices{$deviceName};
        my $size;

        my $isHardDrive;

        if ((defined($device->{'Part Of Whole'}) && ($device->{'Part Of Whole'} eq $device->{'Device Identifier'}))) {
            # Is it possible to have a drive without partition?
            $isHardDrive = 1;
        }

        if ($device->{'Total Size'} =~ /(\S*)\s(\S+)\s+\(/) {
            if ($unitMatrice{$2}) {
                $size = $1*$unitMatrice{$2};
            } else {
                $logger->error("$2 unit is not defined");
            }
        }


        if (!$isHardDrive) {
            $drives{$deviceName}->{TOTAL} = $size;
            $drives{$deviceName}->{SERIAL} = $device->{'Volume UUID'} || $device->{'UUID'};
            $drives{$deviceName}->{FILESYSTEM} = $device->{'File System'} || $device->{'Partition Type'};
            $drives{$deviceName}->{VOLUMN} = $deviceName;
            $drives{$deviceName}->{LABEL} = $device->{'Volume Name'};
#        } else {
#            $storages{$deviceName}->{DESCRIPTION} = $device->{'Protocol'};
#            $storages{$deviceName}->{DISKSIZE} = $size;
#            $storages{$deviceName}->{MODEL} = $device->{'Device / Media Name'};
        }
    }



    foreach my $deviceName (keys %drives) {
        $inventory->addDrive($drives{$deviceName});
    }
#    foreach my $deviceName (keys %storages) {
#        $inventory->addStorage($storags{$deviceName});
#    }

}
1;
