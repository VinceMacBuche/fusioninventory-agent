package FusionInventory::Agent::Task::Inventory::OS::AIX::Memory;

use strict;
use warnings;

sub isInventoryEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $memory (_getMemories()) {
        $inventory->addEntry(
            section => 'MEMORIES',
            entry   => $memory
        );
    }

    #Memory informations
    #lsdev -Cc memory -F 'name' -t totmem
    #lsattr -EOlmem0
    my $memorySize = 0;
    my (@lsdev, @lsattr, @grep);
    @lsdev=`lsdev -Cc memory -F 'name' -t totmem`;
    foreach (@lsdev){
        @lsattr=`lsattr -EOl$_`;
        foreach (@lsattr){
            if (! /^#/){
                # See: http://forge.fusioninventory.org/issues/399
                # TODO: the regex should be improved here
                /^(.+):(\d+)/;
                $memorySize += $2;
            }
        }
    }

    #Paging Space
    my $swapSize;
    @grep=`lsps -s`;
    foreach (@grep){
        if ( ! /^Total/){
            /^\s*(\d+)\w*\s+\d+.+/;
            $swapSize = $1;
        }
    }

    $inventory->setHardware(
        MEMORY => $memorySize,
        SWAP   => $swapSize 
    );

}

sub _getMemories {
    my ($logger) = @_;

    my @memories;
    my $capacity;
    my $description;
    my $numslots;
    my $speed;
    my $type;
    my $serial;
    my $mversion;
    my $caption;
    my $flag=0;

    # lsvpd
    my @lsvpd = getAllLines(command => 'lsvpd', logger => $logger);
    s/^\*// foreach (@lsvpd);

    $numslots = -1; 
    foreach (@lsvpd){
        if (/^DS (Memory DIMM.*)/) {
            $description = $1;
            $flag = 1;
            next;
        }
        next unless $flag;
        if (/^SZ (.*\S)/) {
            $capacity = $1;
        }
        if (/^PN (.*\S)/) {
            $type = $1;
        }
        # localisation slot dans type
        if (/^YL\s(.*\S)/) {
            $caption = "Slot " . $1;
        }
        if (/^SN (.*\S)/) {
            $serial = $1;
        }
        if (/^VK (.*\S)/) {
            $mversion = $1;
        }
        # On rencontre un champ FC alors c'est la fin pour ce device
        if (/^FC/) {
            $flag = 0;
            $numslots = $numslots +1;
            push @memories, {
                CAPACITY     => $capacity,
                DESCRIPTION  => $description,
                CAPTION      => $caption,
                NUMSLOTS     => $numslots,
                VERSION      => $mversion,
                TYPE         => $type,
                SERIALNUMBER => $serial,
            };
        };
    }

    $numslots = $numslots +1;
    # End of Loop
    # The last *FC ???????? missing
    push @memories, {
        CAPACITY     => $capacity,
        DESCRIPTION  => $description,
        CAPTION      => $caption,
        NUMSLOTS     => $numslots,
        VERSION      => $mversion,
        TYPE         => $type,
        SERIALNUMBER => $serial,
    };

    return @memories;
}

1;
