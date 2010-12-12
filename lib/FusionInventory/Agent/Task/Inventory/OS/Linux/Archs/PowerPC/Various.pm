package FusionInventory::Agent::Task::Inventory::OS::Linux::Archs::PowerPC::Various;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return 1;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $SystemSerial = getSingleLine(file => '/proc/device-tree/serial-number');
    $SystemSerial =~ s/[^\,^\.^\w^\ ]//g; # I remove some unprintable char

    my $SystemModel = getSingleLine(file => '/proc/device-tree/model');
    $SystemModel =~ s/[^\,^\.^\w^\ ]//g;

    my $colorCode = getSingleLine(file => '/proc/device-tree/color-code');
    my ($color) = unpack "h7" , $colorCode;
    $SystemModel .= " color: $color" if $color;

    my $BiosVersion = getSingleLine(file => '/proc/device-tree/openprom/model');
    $BiosVersion =~ s/[^\,^\.^\w^\ ]//g;

    my ($BiosManufacturer, $SystemManufacturer);
    my $copyright = getSingleLine(file => '/proc/device-tree/copyright');
    if ($copyright && $copyright =~ /Apple/) {
        # What about the Apple clone?
        $BiosManufacturer = "Apple Computer, Inc.";
        $SystemManufacturer = "Apple Computer, Inc." 
    }

    $inventory->setBios(
        SMANUFACTURER => $SystemManufacturer,
        SMODEL        => $SystemModel,
        SSN           => $SystemSerial,
        BMANUFACTURER => $BiosManufacturer,
        BVERSION      => $BiosVersion,
    );

}

1;
