package FusionInventory::Agent::Task::Inventory::OS::MacOS;

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isEnabled {
    return $OSNAME eq 'darwin';
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my ($OSName, $OSVersion);

    # if we can load the system profiler, gather the information from that
    if (canLoad("Mac::SysProfile")) {
        my $prof = Mac::SysProfile->new();
        my $info = $prof->gettype('SPSoftwareDataType');
        return unless ref $info eq 'HASH';

        $info = $info->{'System Software Overview'};

        my $SystemVersion = $info->{'System Version'};
        if ($SystemVersion =~ /^(.*?)\s+(\d+.*)/) {
            $OSName = $1;
            $OSVersion = $2;
        } else {
            # Default values
            $OSName = "Mac OS X";
        }

    } else {
        # we can't load the system profiler, use the basic BSD stype information
        # Operating system informations
        $OSName = getFirstLine(command => 'uname -s');
        $OSVersion = getFirstLine(command => 'uname -r');
    }

    # add the uname -v as the comment, not really needed, but extra info
    # never hurt
    my $OSComment = getFirstLine(command => 'uname -v');
    my $KernelVersion = getFirstLine(command => 'uname -r');

    $inventory->setHardware({
        OSNAME     => $OSName,
        OSCOMMENTS => $OSComment,
        OSVERSION  => $OSVersion,
    });

    $inventory->setOperatingSystem({
        NAME                 => "MacOSX",
        VERSION              => $OSVersion,
        KERNEL_VERSION       => $KernelVersion,
        FULL_NAME            => $OSName
    });
}

1;
