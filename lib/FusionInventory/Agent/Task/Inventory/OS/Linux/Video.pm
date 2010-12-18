package FusionInventory::Agent::Task::Inventory::OS::Linux::Video;

use strict;
use warnings;

use FusionInventory::Agent::Tools;

sub isInventoryEnabled {
    return 1;
}

sub _getDdcprobeData {
    my ($file) = @_;

    my $handle = getFileHandle(
        command => 'ddcprobe 2>&1',
        file => $file
    );

    return unless $handle;

    my $ddcprobeData;
    foreach (<$handle>) {
        s/[[:cntrl:]]//g;
        s/[^[:ascii:]]//g;
        $ddcprobeData->{$1} = $2 if /^(\S+):\s+(.*)/;
    }

    return $ddcprobeData;
}

sub _parseXorgFd {
    my ($file) = @_;

    my $handle = getFileHandle(
        file => $file
    );

    return unless $handle;

    my $data;
    foreach my $line (<$handle>) {
        if ($line =~ /Modeline\s"(\S+?)"/) {
            $data->{resolution}=$1 if !$data->{resolution};
        } elsif ($line =~ /Integrated Graphics Chipset:\s+(.*)/) {
            # Intel
            $data->{name}=$1;
        } elsif ($line =~ /Virtual screen size determined to be (\d+)\s*x\s*(\d+)/) {
            # Nvidia
            $data->{resolution}="$1x$2";
        } elsif ($line =~ /NVIDIA GPU\s*(.*?)\s*at/) {
            $data->{name}=$1;
        } elsif ($line =~ /VESA VBE OEM:\s*(.*)/) {
            $data->{name}=$1;
        } elsif ($line =~ /VESA VBE OEM Product:\s*(.*)/) {
            $data->{product}=$1;
        } elsif ($line =~ /VESA VBE Total Mem: (\d+)\s*(\w+)/i) {
            $data->{memory}=$1.$2;
        } elsif ($line =~ /RADEON\(0\): Chipset: "(.*?)"/i) {
            # ATI /Radeon
            $data->{name}=$1;
        } elsif ($line =~ /Virtual size is (\S+)/i) {
            # VESA / XFree86
            $data->{resolution}=$1;
        } elsif ($line =~ /Primary Device is: PCI (.+)/i) {
            $data->{pcislot}=$1;
            # mimic lspci pci slot format
            $data->{pcislot} =~ s/^00@//;
            $data->{pcislot} =~ s/(\d{2}):(\d{2}):(\d)$/$1:$2.$3/;
        } elsif ($line =~ /NOUVEAU\(0\): Chipset: "(.*)"/) {
            # Nouveau
            $data->{product}=$1;
        }
    }

    close $handle;

    return $data;
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $ddcprobeData = _getDdcprobeData();

    my $xOrgPid;
    foreach (`ps aux`) {
        if ((/\/usr(\/bin|\/X11R6\/bin)\/X/ || /Xorg/) && /^\S+\s+(\d+)/) {
            $xOrgPid = $1;
            last;
        }
    }

    my $xorgData;
    if ($xOrgPid) {
        $xorgData = _parseXorgFd("</proc/$xOrgPid/fd/0");
    }

    my $memory = $xorgData->{memory} || $ddcprobeData->{memory};
    if ($memory && $memory =~ s/kb$//i) {
        $memory = int($memory / 1024);
    }
    my $resolution = $xorgData->{resolution} || $ddcprobeData->{dtiming};
    if ($resolution) {
        $resolution =~ s/@.*//;
    }

    $inventory->addVideo({
        CHIPSET    => $xorgData->{product} || $ddcprobeData->{product},
        MEMORY     => $memory,
        NAME       => $xorgData->{name} || $ddcprobeData->{oem},
        PCISLOT    => $xorgData->{pcislot},
        RESOLUTION => $xorgData->{resolution} || $ddcprobeData->{dtiming}
        });

}

1;
