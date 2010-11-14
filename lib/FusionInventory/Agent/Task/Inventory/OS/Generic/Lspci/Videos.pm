package FusionInventory::Agent::Task::Inventory::OS::Generic::Lspci::Videos;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Unix;

sub isInventoryEnabled {
    return 0 if $OSNAME =~ /^mswin/i;
    return 0 if $OSNAME =~ /^linux/i;
    return 1;
}

sub doInventory {
    my $params = shift;
    my $inventory = $params->{inventory};
    my $logger    = $params->{logger};

    foreach my $video (_getVideoControllers($logger)) {
        $inventory->addVideo($video);
    }
}

sub _getVideoControllers {
     my ($logger, $file) = @_;

    my @videos;

    foreach my $controller (getControllersFromLspci(
        logger => $logger, file => $file
    )) {
        next unless $controller->{NAME} =~ /graphics|vga|video|display/i;
        push @videos, {
            CHIPSET => $controller->{NAME},
            NAME    => $controller->{MANUFACTURER},
        };
    }

    return @videos;
}

1;
