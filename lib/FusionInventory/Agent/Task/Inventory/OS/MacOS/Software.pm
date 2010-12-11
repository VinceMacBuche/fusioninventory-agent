package FusionInventory::Agent::Task::Inventory::OS::MacOS::Software;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    my (%params) = @_;

    return
        !$params{no_software} &&
        can_load("Mac::SysProfile");
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};

    my $prof = Mac::SysProfile->new();
    my $apps = $prof->gettype('SPApplicationsDataType'); # might need to check version of darwin

    return unless($apps && ref($apps) eq 'HASH');

    # for each app, normalize the information, then add it to the inventory stack
    foreach my $app (keys %$apps){
        my $a = $apps->{$app};
        my $kind = $a->{'Kind'} ? $a->{'Kind'} : 'UNKNOWN';
        my $comments = '['.$kind.']';
        $inventory->addSoftware({
            NAME      => $app,
            VERSION   => $a->{'Version'} || 'unknown',
            COMMENTS  => $comments,
            PUBLISHER => $a->{'Get Info String'} || 'unknown',
        });
    }
}

1;
