package FusionInventory::Agent::Task::Inventory::Input::Generic::Screen;
#     Copyright (C) 2005 Mandriva
#     Copyright (C) 2007 Gonéri Le Bouder <goneri@rulezlan.org> 
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.

#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.

#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#
# Some part come from Mandriva's (great) monitor-edid
# http://svn.mandriva.com/cgi-bin/viewvc.cgi/soft/monitor-edid/trunk/
#
use strict;
use warnings;

use English qw(-no_match_vars);
use MIME::Base64;
use UNIVERSAL::require;

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Tools::Screen;

sub isEnabled {

    return
        $OSNAME eq 'MSWin32'                 ||
        canRun('monitor-get-edid-using-vbe') ||
        canRun('monitor-get-edid')           ||
        canRun('get-edid');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    foreach my $screen (_getScreens($logger)) {

        if ($screen->{edid}) {
            my $edid = parseEdid($screen->{edid});
            if (my $err = checkParsedEdid($edid)) {
                $logger->debug("check failed: bad edid: $err");
            } else {
                $screen->{CAPTION} =
                    $edid->{monitor_name};
                $screen->{DESCRIPTION} =
                    $edid->{week} . "/" . $edid->{year};
                $screen->{MANUFACTURER} =
                    getManufacturerFromCode($edid->{manufacturer_name});
                $screen->{SERIAL} = $edid->{serial_number2}->[0];
            }
            $screen->{BASE64} = encode_base64($screen->{edid});
        }

        $inventory->addEntry(
            section => 'MONITORS',
            entry   => $screen
        );
    }
}

sub _getScreensFromWindows {
    my ($logger) = @_;

    my $devices = {};
    my $Registry;
    eval {
        require FusionInventory::Agent::Tools::Win32;
        require Win32::TieRegistry;
        Win32::TieRegistry->import(
                Delimiter   => '/',
                ArrayValues => 0,
                TiedRef     => \$Registry
                );
    };
    if ($EVAL_ERROR) {
        print "Failed to load Win32::OLE and Win32::TieRegistry\n";
        return;
    }

    use constant wbemFlagReturnImmediately => 0x10;
    use constant wbemFlagForwardOnly => 0x20;

# Vista and upper, able to get the second screen
    my $WMIServices = Win32::OLE->GetObject(
            "winmgmts:{impersonationLevel=impersonate,authenticationLevel=Pkt}!//./root/wmi" );

    foreach my $properties ( Win32::OLE::in( $WMIServices->InstancesOf(
                    "WMIMonitorID" ) ) )
    {

        next unless $properties->{InstanceName};
        my $PNPDeviceID = $properties->{InstanceName};
        $PNPDeviceID =~ s/_\d+//;
        $devices->{lc($PNPDeviceID)} = {};
    }

# The generic Win32_DesktopMonitor class, the second screen will be missing
    foreach my $objItem (getWmiProperties('Win32_DesktopMonitor', qw/
                Caption MonitorManufacturer MonitorType PNPDeviceID
                /)) {


        next unless $objItem->{"Availability"};
        next unless $objItem->{"PNPDeviceID"};
        next unless $objItem->{"Availability"} == 3;
        my $name = $objItem->{"Caption"};

        $devices->{lc($objItem->{"PNPDeviceID"})} = { name => $name, type => $objItem->{MonitorType}, manufacturer => $objItem->{MonitorManufacturer}, caption => $objItem->{Caption} };

    }

    my @ret;
    foreach my $PNPDeviceID (keys %{$devices}) {


        my $machKey;
        {
            my $KEY_WOW64_64KEY = 0x100;

            my $access;

            if (FusionInventory::Agent::Tools::Win32::is64bit()) {
                $access = Win32::TieRegistry::KEY_READ() | $KEY_WOW64_64KEY;
            } else {
                $access = Win32::TieRegistry::KEY_READ();
            }

# Win32-specifics constants can not be loaded on non-Windows OS
            no strict 'subs';
            $machKey = $Registry->Open('LMachine', {
                    Access => $access
                    } ) or $logger->fault("Can't open HKEY_LOCAL_MACHINE key: $EXTENDED_OS_ERROR");

        }

        $devices->{$PNPDeviceID}{edid} =
            $machKey->{"SYSTEM/CurrentControlSet/Enum/".$PNPDeviceID."/Device Parameters/EDID"} || '';
        $devices->{$PNPDeviceID}{edid} =~ s/^\s+$//;

        push @ret, $devices->{$PNPDeviceID};
    }
    return @ret;

}



sub _getScreens {
    my ($logger) = @_;

    my @screens;

    if ($OSNAME eq 'MSWin32') {

        return _getScreensFromWindows($logger);

    } else {
        # Mandriva
        my $raw_edid =
            getFirstLine(command => 'monitor-get-edid-using-vbe') ||
            getFirstLine(command => 'monitor-get-edid');

        if (!$raw_edid) {
            foreach (1..5) { # Sometime get-edid return an empty string...
                $raw_edid = getFirstLine(command => 'get-edid');
                last if $raw_edid && (length($raw_edid) == 128 || length($raw_edid) == 256);
            }
        }
        return unless length($raw_edid) == 128 || length($raw_edid) == 256;

        push @screens, { edid => $raw_edid };
    }

    return @screens;
}

1;