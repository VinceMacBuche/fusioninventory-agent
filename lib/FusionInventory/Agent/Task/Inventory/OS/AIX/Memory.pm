package FusionInventory::Agent::Task::Inventory::OS::AIX::Memory;

use strict;
use warnings;

sub isInventoryEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

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

    my @memories;
    my $capacity;
    my $description;
    my $numslots;
    my $speed;
    my $type;
    my $n;
    my $serial;
    my $mversion;
    my $caption;
    my $flag=0;
    #lsvpd
    my @lsvpd = `lsvpd`;
    # Remove * (star) at the beginning of lines
    s/^\*// foreach (@lsvpd);

    $numslots = -1; 
    foreach (@lsvpd){
        if(/^DS Memory DIMM/){
            $description = $_;
            $flag=1; (defined($n))?($n++):($n=0);
            $description =~ s/DS //;
            $description =~ s/\n//;
        }
        if((/^SZ (.+)/) && ($flag)) {$capacity = $1;}
        if((/^PN (.+)/) && ($flag)) {$type = $1;}
        # localisation slot dans type
        if((/^YL\s(.+)/) && ($flag)) {$caption = "Slot ".$1;}
        if((/^SN (.+)/) && ($flag)) {$serial = $1;}
        if((/^VK (.+)/) && ($flag)) {$mversion = $1};
        #print $numslots."\n";
        # On rencontre un champ FC alors c'est la fin pour ce device
        if((/^FC .+/) && ($flag)) {
            $flag=0;
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
