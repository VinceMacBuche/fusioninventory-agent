package FusionInventory::Agent::Task::Inventory::OS::Solaris::Softwares;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    my (%params) = @_;

    return 
        !$params{config}->{no_software} &&
        can_run('pkginfo');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $handle = getFileHandle(
        command => 'pkginfo -l',
        logger  => $logger,
    );

    return unless $handle;

    my $software;
    while (my $line = <$handle>) {
        if ($line =~ /^\s*$/) {
            $inventory->addEntry(
                section => 'SOFTWARES',
                entry   =>  $software
            );
            undef $software;
        } elsif ($line =~ /PKGINST:\s+(.+)/) {
            $software->{NAME} = $1;
        } elsif ($line =~ /VERSION:\s+(.+)/) {
            $software->{VERSION} = $1;
        } elsif ($line =~ /VENDOR:\s+(.+)/) {
            $software->{PUBLISHER} = $1;
        } elsif ($line =~  /DESC:\s+(.+)/) {
            $software->{COMMENTS} = $1;
        }
    }

    close $handle;
}

1;
