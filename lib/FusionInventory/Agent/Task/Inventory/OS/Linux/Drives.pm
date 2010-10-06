package FusionInventory::Agent::Task::Inventory::OS::Linux::Drives;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return 
        can_run ('df') ||
        can_run ('lshal');
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};
    my $logger = $params->{logger};

    # start with df command
    my $drives = getFilesystemsFromDf($logger, 'df -P -T -k', '-|');

    # filter undesirable FS
    $drives = [ grep {
        $_->{FILESYSTEM} !~ /^(tmpfs|usbfs|proc|devpts|devshm|udev)$/;
    } @$drives ];

# get additional informations
    if (can_run('blkid')) {
        # use blkid if available, as it is filesystem-independant
        foreach my $drive (@$drives) {
            my $line = `blkid $drive->{VOLUMN} 2> /dev/null`;
            $drive->{SERIAL} = $1 if $line =~ /\sUUID="(\S*)"\s/;
        }
    } else {
        # otherwise fallback to filesystem-dependant utilities
        my $has_dumpe2fs   = can_run('dumpe2fs');
        my $has_xfs_db     = can_run('xfs_db');
        my $has_dosfslabel = can_run('dosfslabel');
        my %months = (
            Jan => 1,
            Fev => 2,
            Mar => 3,
            Apr => 4,
            May => 5,
            Jun => 6,
            Jul => 7,
            Aug => 8,
            Sep => 9,
            Oct => 10,
            Nov => 11,
            Dec => 12,
        );

        foreach my $drive (@$drives) {
            if ($drive->{FILESYSTEM} =~ /^ext(2|3|4|4dev)/ && $has_dumpe2fs) {
                foreach my $line (`dumpe2fs -h $drive->{VOLUMN} 2> /dev/null`) {
                    if ($line =~ /Filesystem UUID:\s+(\S+)/) {
                        $drive->{SERIAL} = $1;
                    } elsif ($line =~ /Filesystem created:\s+\w+\s+(\w+)\s+(\d+)\s+([\d:]+)\s+(\d{4})$/) {
                        $drive->{CREATEDATE} = "$4/$months{$1}/$2 $3";
                    } elsif ($line =~ /Filesystem volume name:\s*(\S.*)/) {
                        $drive->{LABEL} = $1 unless $1 eq '<none>';
                    }
                }
                next;
            }

            if ($drive->{FILESYSTEM} eq 'xfs' && $has_xfs_db) {
                foreach my $line (`xfs_db -r -c uuid $drive->{VOLUMN}`) {
                    $drive->{SERIAL} = $1 if $line =~ /^UUID =\s+(\S+)/;
                }
                foreach my $line (`xfs_db -r -c label $drive->{VOLUMN}`) {
                    $drive->{LABEL} = $1 if $line =~ /^label =\s+"(\S+)"/;
                }
                next;
            }

            if ($drive->{FILESYSTEM} eq 'vfat' && $has_dosfslabel) {
                $drive->{LABEL} = `dosfslabel $drive->{VOLUMN}`;
                chomp $drive->{LABEL};
                next;
            }
        }
    }

    # complete with hal if available
    if (can_run ("lshal")) {
       # index devices by name for comparaison
        my %drives = map { $_->{VOLUMN} => $_ } @$drives;

        # complete with hal for missing bits
        foreach my $drive (_getFromHal()) {
            my $name = $drive->{VOLUMN};
            foreach my $key (keys %$drive) {
                $drives{$name}->{$key} = $drive->{$key}
                    if !$drives{$name}->{$key};
            }
        }
    }

    foreach my $drive (@$drives) {
        $inventory->addDrive($drive);
    }
}

sub _getFromHal {
    my $devices = _parseLshal('/usr/bin/lshal', '-|');
    return @$devices;
}

sub _parseLshal {
    my ($file, $mode) = @_;

    my $handle;
    if (!open $handle, $mode, $file) {
        warn "Can't open $file: $ERRNO";
        return;
    }

   my $devices = [];
   my $device = {};

    while (my $line = <$handle>) {
        chomp $line;
        if ($line =~ m{^udi = '/org/freedesktop/Hal/devices/(volume|block).*}) {
            $device = {};
            next;
        }

        next unless defined $device;

        if ($line =~ /^$/) {
            if ($device->{ISVOLUME}) {
                delete($device->{ISVOLUME});
                push(@$devices, $device);
            }
            undef $device;
        } elsif ($line =~ /^\s+ block.device \s = \s '([^']+)'/x) {
            $device->{VOLUMN} = $1;
        } elsif ($line =~ /^\s+ volume.fstype \s = \s '([^']+)'/x) {
            $device->{FILESYSTEM} = $1;
        } elsif ($line =~ /^\s+ volume.label \s = \s '([^']+)'/x) {
            $device->{LABEL} = $1;
        } elsif ($line =~ /^\s+ volume.uuid \s = \s '([^']+)'/x) {
            $device->{SERIAL} = $1;
        } elsif ($line =~ /^\s+ storage.model \s = \s '([^']+)'/x) {
            $device->{TYPE} = $1;
         } elsif ($line =~ /^\s+ volume.size \s = \s (\S+)/x) {
            my $value = $1;
            $device->{TOTAL} = int($value/(1024*1024) + 0.5);
        } elsif ($line =~ /block.is_volume\s*=\s*true/i) {
            $device->{ISVOLUME} = 1;
        }
    }
    close $handle;

    return $devices;
}

1;
