package FusionInventory::Agent::Task::Inventory::OS::Linux::Storages::ServeRaid;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

# Tested on 2.6.* kernels
#
# Cards tested :
#
# IBM ServeRAID-6M 
# IBM ServeRAID-6i

sub isInventoryEnabled {
    return can_run('ipssend');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach (`ipssend GETVERSION 2>/dev/null`) {

# Example Output :
# Found 1 IBM ServeRAID controller(s).
#----------------------------------------------------------------------
#ServeRAID Controller(s) Version Information
#----------------------------------------------------------------------
#   Controlling BIOS version       : 7.00.14
        #
#ServeRAID Controller Number 1
#   Controller type                : ServeRAID-6M
#   Controller slot information    : 2
#   Actual BIOS version            : 7.00.14
#   Firmware version               : 7.00.14
#   Device driver version          : 7.10.18
        next unless /ServeRAID Controller Number\s(\d*)/;
        my $slot = $1;

        my $storage;

        foreach (`ipssend GETCONFIG $slot PD 2>/dev/null`) {
# Example Output :
#   Channel #1:
#      Target on SCSI ID 0
#         Device is a Hard disk
#         SCSI ID                  : 0
#         PFA (Yes/No)             : No
#         State                    : Online (ONL)
#         Size (in MB)/(in sectors): 34715/71096368
#         Device ID                : IBM-ESXSCBR036C3DFQDB2Q6CDKM
#         FRU part number          : 32P0729

            if (/Size.*:\s(\d*)\/(\d*)/) {
                $storage->{DISKSIZE} = $1;
            } elsif (/Device ID.*:\s(.*)/) {
                $storage->{SERIALNUMBER} = $1;
            } elsif (/FRU part number.*:\s(.*)/) {
                $storage->{MODEL} = $1;
                $storage->{MANUFACTURER} = getCanonicalManufacturer(
                    $storage->{SERIALNUMBER}
                );
                $storage->{NAME} = $storage->{MANUFACTURER} . ' ' . $storage->{MODEL};
                $storage->{DESCRIPTION} = 'SCSI';
                $storage->{TYPE} = 'disk';

                $inventory->addStorage($storage);
                undef $storage;
            }
        }
    }
}

1;

