package FusionInventory::Agent::Task::Inventory::Virtualization::Virtuozzo;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return can_run('vzlist');
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};
    my $logger = $params->{logger};

    my $command =
        'vzlist --all --no-header -o hostname,ctid,cpulimit,status,ostemplate';

    my $handle;
    if (!open $handle, '-|', $command) {
        $logger->error("Can't run command $command");
        return;
    }

    while (my $line = <$handle>) {
        # no service containers in glpi
        next if $INPUT_LINE_NUMBER eq 1;

        chomp $line; 
        my @params = split(/[ \t]+/, $line);
        my $name   = $params[0];
        my $uuid   = $params[1];
        my $cpus   = $params[2];
        my $status = $params[3];
        my $subsys = $params[4];
        my $mem    = 0;

        my $subhandle;
        if (open $subhandle, '<', "/etc/vz/conf/$uuid.conf") {
            while (my $subline = <$subhandle>) {
                next unless $subline =~ /^SLMMEMORYLIMIT="\d+:(\d+)"$/;
                $mem = $1 / 1024 / 1024;
                last;
            }
            close $subhandle;
        }
 
        $inventory->addVirtualMachine({
            NAME      => $name,
            VCPU      => $cpus,
            UUID      => $uuid,
            MEMORY    => $mem,
            STATUS    => $status,
            SUBSYSTEM => $subsys,
            VMTYPE    => "Virtuozzo",
        });

    }

    close $handle;
}

1;

