package FusionInventory::Agent::Task::Inventory::OS::Solaris::Memory;

use strict;
use warnings;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Solaris;

sub isInventoryEnabled {
    return can_run('memconf');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $capacity;
    my $description;
    my $numslots;
    my $speed = undef;
    my $type = undef;
    my $banksize;
    my $module_count=0;
    my $empty_slots;
    my $flag=0;
    my $flag_mt=0;
    my $caption;
    my $class=0;
    # for debug only
    my $j=0;

    my $class = getClass();

    if ($class == 0) {
        $logger->debug("sorry, unknown model, could not detect memory configuration");
    }

    if ($class == 1) {
        foreach(`memconf 2>&1`) {
            # if we find "empty groups:", we have reached the end and indicate that by setting flag = 0
            if (/^empty \w+:\s(\S+)/) {
                $flag = 0;
                if ($1 eq "None"){$empty_slots = 0;}
            }
            # grep the type of memory modules from heading
            if ($flag_mt && /^\s*\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/) {$flag_mt=0; $description = $1;}

            # only grap for information if flag = 1
            if ($flag && /^\s*(\S+)\s+(\S+)/) { $caption = "Board " . $1 . " MemCtl " . $2; }
            if ($flag && /^\s*\S+\s+\S+\s+(\S+)/) { $numslots = $1; }
            if ($flag && /^\s*\S+\s+\S+\s+\S+\s+(\d+)/) { $banksize = $1; }
            if ($flag && /^\s*\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\d+)/) { $capacity = $1; }
            if ($flag) {
                for (my $i = 1; $i <= ($banksize / $capacity); $i++) {
                    $module_count++;
                    $inventory->addMemory({
                        CAPACITY => $capacity,
                        DESCRIPTION => $description,
                        CAPTION => $caption,
                        SPEED => $speed,
                        TYPE => $type,
                        NUMSLOTS => $numslots
                    })
                }
            }
            # this is the caption line
            if (/^\s+Logical  Logical  Logical/) { $flag_mt = 1; }
            # if we find "---", we set flag = 1, and in next line, we start to look for information
            if (/^-+/){ $flag = 1; }
        }
    }

    if ($class == 2) {
        foreach(`memconf 2>&1`) {
            # if we find "empty sockets:", we have reached the end and indicate that by resetting flag = 0
            # emtpy sockets is follow by a list of emtpy slots, where we extract the slot names
            if (/^empty sockets:\s*(\S+)/) {
                $flag = 0;
                # cut of first 15 char containing the string empty sockets:
                substr ($_,0,15) = "";
                $capacity = "empty";
                $numslots = 0;
                foreach my $caption (split) {
                    if ($caption eq "None") {
                        $empty_slots = 0;
                        # no empty slots -> exit loop
                        last;
                    }
                    $empty_slots++;
                    $inventory->addMemory({
                            CAPACITY => $capacity,
#                            DESCRIPTION => $description,
                            CAPTION => $caption,
                            SPEED => $speed,
                            TYPE => $type,
                            NUMSLOTS => $numslots
                        })
                }
            }
            if (/.*Memory Module Groups.*/) {
                $flag = 0;
                $flag_mt = 0;
            }
            # we only grap for information if flag = 1
            if ($flag && /^\s*\S+\s+\S+\s+(\S+)/){ $caption = $1; }
            if ($flag && /^\s*(\S+)/){ $numslots = $1; }
            if ($flag && /^\s*\S+\s+\S+\s+\S+\s+(\d+)/){ $capacity = $1; }
            if ($flag) {
                $module_count++;
                $inventory->addMemory({
                        CAPACITY => $capacity,
#                        DESCRIPTION => "DIMM",
                        CAPTION => "Ram slot ".$numslots,
                        SPEED => $speed,
                        TYPE => $type,
                        NUMSLOTS => $numslots
                    })
            }
            # this is the caption line
#            if (/^ID       ControllerID/) { $description = $1;}
            # if we find "---", we set flag = 1, and in next line, we start to look for information
            if (/^-+/) {
                $flag = 1;
            }
        }
    }

    if ($class == 3) {
        foreach(`memconf 2>&1`) {
            if (/^empty sockets:\s*(\S+)/) {
                # cut of first 15 char containing the string empty sockets:
                substr ($_,0,15) = "";
                $capacity = "empty";
                $numslots = 0;
                foreach my $caption (split) {
                    if ($caption eq "None") {
                        $empty_slots = 0;
                        # no empty slots -> exit loop
                        last;
                    }
                    $empty_slots++;
                    $inventory->addMemory({
                        CAPACITY => $capacity,
                        DESCRIPTION => $description,
                        CAPTION => $caption,
                        SPEED => $speed,
                        TYPE => $type,
                        NUMSLOTS => $numslots
                    })
                }
            }
            if (/^socket\s+(\S+) has a (\d+)MB\s+\(\S+\)\s+(\S+)/) {
                $caption = $1;
                $description = $3;
                $type = $3;
                $numslots = 0;
                $capacity = $2;
                $module_count++;
                $inventory->addMemory({
                    CAPACITY => $capacity,
                    DESCRIPTION => $description,
                    CAPTION => $caption,
                    SPEED => $speed,
                    TYPE => $type,
                    NUMSLOTS => $numslots
                })
            }
        }
    }

    if ($class == 4) {
        foreach(`memconf 2>&1`) {
            # if we find "empty sockets:", we have reached the end and indicate that by resetting flag = 0
            # emtpy sockets is follow by a list of emtpy slots, where we extract the slot names
            if (/^empty sockets:\s*(\S+)/) {
                $flag = 0;
                # cut of first 15 char containing the string empty sockets:
                substr ($_,0,15) = "";
                $capacity = "empty";
                $numslots = 0;
                foreach my $caption (split) {
                    if ($caption eq "None") {
                        $empty_slots = 0;
                        # no empty slots -> exit loop
                        last;
                    }
                    $empty_slots++;
                    $inventory->addMemory({
                        CAPACITY => $capacity,
                        DESCRIPTION => $description,
                        CAPTION => $caption,
                        SPEED => $speed,
                        TYPE => $type,
                        NUMSLOTS => $numslots
                    })
                }
            }

            # we only grap for information if flag = 1
            # socket MB/CMP0/BR0/CH0/D0 has a Samsung 501-7953-01 Rev 05 2GB FB-DIMM
            if (/^socket\s+(\S+) has a (.+)\s+(\S+)GB\s+(\S+)$/i) {
                $caption = $1;
                $description = $2;
                $type = $4;
                $numslots = 0;
                $capacity = $3 * 1024;
                $module_count++;
                $inventory->addMemory({
                    CAPACITY => $capacity,
                    DESCRIPTION => $description,
                    CAPTION => $caption,
                    SPEED => $speed,
                    TYPE => $type,
                    NUMSLOTS => $numslots
                })
            }
        }
    }

    if ($class ==  5) {
        foreach(`memconf 2>&1`) {
            # if we find "empty sockets:", we have reached the end and indicate that by resetting flag = 0
            # emtpy sockets is follow by a list of emtpy slots, where we extract the slot names
            if (/^total memory:\s*(\S+)/) { $flag = 0;}

            if ($flag_mt && /^\s+\S+\s+\S+\s+\S+\s+(\S+)/) {$flag_mt=0;  $description = $1;}

            if ($flag && /^\s(\S+)\s+(\S+)/) { $numslots = "LSB " . $1 . " Group " . $2; }
            if ($flag && /^\s(\S+)\s+(\S+)/) { $caption = "LSB " . $1 . " Group " . $2; }
            if ($flag && /^\s+\S+\s+\S\s+\S+\s+\S+\s+(\d+)/) { $capacity = $1; }
            if ($flag && /^\s+\S+\s+\S\s+(\d+)/) { $banksize = $1; }
            if ($flag && $capacity > 1 ) {
                for (my $i = 1; $i <= ($banksize / $capacity); $i++) {
                    $inventory->addMemory({
                        CAPACITY => $capacity,
                        DESCRIPTION => $description,
                        CAPTION => $caption,
                        SPEED => $speed,
                        TYPE => $type,
                        NUMSLOTS => $module_count
                    })
                }
                $module_count++;
            }
            #Caption Line
            if (/^Sun Microsystems/) {
                $flag_mt=1;
                $flag=1;
            }
        }
    }
    if ($class == 6) {
        foreach(`memconf 2>&1`) {
            if (/^empty memory sockets:\s*(\S+)/) {
                # cut of first 22 char containing the string empty sockets:
                substr ($_,0,22) = "";
                $capacity = "0";
                $numslots = 0;
                foreach my $caption (split(/, /,$_)) {
                    if ($caption eq "None") {
                        $empty_slots = 0;
                        # no empty slots -> exit loop
                        last;
                    }
                    $empty_slots++;
                    $inventory->addMemory({
                        CAPACITY => $capacity,
                        DESCRIPTION => "empty",
                        CAPTION => $caption,
                        SPEED => 'n/a',
                        TYPE => 'n/a',
                        NUMSLOTS => $numslots
                    })
                }
            }
            if (/^socket DIMM(\d+):\s+(\d+)MB\s(\S+)/) {
                $caption = "DIMM$1";
                $description = "DIMM$1";
                $numslots = $1;
                $capacity = $2;
                $type = $3;
                $module_count++;
                $inventory->addMemory({
                    CAPACITY => $capacity,
                    DESCRIPTION => $description,
                    CAPTION => $caption,
                    SPEED => $speed,
                    TYPE => $type,
                    NUMSLOTS => $numslots
                })
            }
        }
    }

    if ($class == 7) {
        foreach (`prctl -n project.max-shm-memory $$ 2>&1`) {
            $description = $1 if /^project.(\S+)$/;
            $capacity = $1 if /^\s*system+\s*(\d+).*$/;
            if ($description && $capacity){
                $capacity = $capacity * 1024;
                $numslots = 1 ;
                $description = "Memory Allocated";
                $caption = "Memory Share";
                $inventory->addMemory({
                    CAPACITY => $capacity,
                    DESCRIPTION => $description,
                    CAPTION => $caption,
                    SPEED => $speed,
                    TYPE => $type,
                    NUMSLOTS => $numslots
                })
            }
        }
    }

}

1;
