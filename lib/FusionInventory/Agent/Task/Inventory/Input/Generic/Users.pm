package FusionInventory::Agent::Task::Inventory::Input::Generic::Users;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isEnabled {
    return 
        canRun('who') ||
        canRun('last');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getFileHandle(
        logger  => $logger,
        command => 'who'
    );

    if ($handle) {
        while (my $line = <$handle>) {
            next unless $line =~ /^(\S+)/;
            $inventory->addEntry(
                section => 'USERS',
                entry   => {
                    LOGIN => $1
                },
                noDuplicated => 1
            );
        }
        close $handle;
    }

    my ($lastUser, $lastDate);
    my $last = getFirstLine(command => 'last -R');
    if ($last &&
        $last =~ /^(\S+) \s+ \S+ \s+ (\S+ \s+ \S+ \s+ \S+ \s+ \S+)/x
    ) {
        $lastUser = $1;
        $lastDate = $2;
    }

    $inventory->setHardware({
        LASTLOGGEDUSER     => $lastUser,
        DATELASTLOGGEDUSER => $lastDate
    });

}

1;