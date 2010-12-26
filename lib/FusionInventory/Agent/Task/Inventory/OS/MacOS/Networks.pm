package FusionInventory::Agent::Task::Inventory::OS::MacOS::Networks;

# I think I hijacked most of this from the BSD/Linux modules

use strict;
use warnings;

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;
use FusionInventory::Agent::Regexp;

sub isInventoryEnabled {
    return can_run('ifconfig');
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger = $params{logger};

    # set list of network interfaces
    my $routes = _getRoutes($logger);
    my @interfaces = _getInterfaces($logger);
    foreach my $interface (@interfaces) {
        $inventory->addNetwork($interface);
    }

    # set global parameters
    my @ip_addresses =
        grep { ! /^127/ }
        grep { $_ }
        map { $_->{IPADDRESS} }
        @interfaces;

    $inventory->setHardware(
        IPADDR         => join('/', @ip_addresses),
        DEFAULTGATEWAY => $routes->{default}
    );
}

sub _getRoutes {
    my ($logger) = @_;

    my $routes;
    foreach my $line (`netstat -nr -f inet`) {
        next unless $line =~ /^default\s+(\S+)/i;
        $routes->{default} = $1;
    }

    return $routes;
}

sub _getInterfaces {
    my ($logger) = @_;

    my @interfaces = _parseIfconfig(
        command => '/sbin/ifconfig -a',
        logger  =>  $logger
    );

    foreach my $interface (@interfaces) {
        $interface->{IPSUBNET} = getSubnetAddress(
            $interface->{IPADDRESS},
            $interface->{IPMASK}
        );
    }

    return @interfaces;
}
sub _parseIfconfig {

    my $handle = getFileHandle(@_);
    return unless $handle;

    my @interfaces;
    my $interface;

    while (my $line = <$handle>) {
        if ($line =~ /^(\S+):/) {
            # new interface
            push @interfaces, $interface if $interface;
            $interface = {
                STATUS      => 'Down',
                DESCRIPTION => $1,
                VIRTUALDEV  => 1
            };
        }

        if ($line =~ /inet ($ip_address_pattern)/) {
            $interface->{IPADDRESS} = $1;
        }
        if ($line =~ /inet6 (\S+)/) {
            $interface->{IPADDRESS6} = $1;
            # Drop the interface from the address. e.g:
            # fe80::1%lo0
            # fe80::214:51ff:fe1a:c8e2%fw0
            $interface->{IPADDRESS6} =~ s/%.*$//;
        }
        if ($line =~ /netmask (\S+)/) {
            # In BSD, netmask is given in hex form
            my $ipmask = $1;
            if ($ipmask =~ /^0x(\w{2})(\w{2})(\w{2})(\w{2})$/) {
                $interface->{IPMASK} =
                    hex($1) . '.' .
                    hex($2) . '.' .
                    hex($3) . '.' .
                    hex($4);
            }
        }
        if ($line =~ /(?:address:|ether|lladdr) ($mac_address_pattern)/) {
            $interface->{MACADDR} = $1;
        }
        if ($line =~ /mtu (\S+)/) {
            $interface->{MTU} = $1;
        }
        if ($line =~ /media (\S+)/) {
            $interface->{TYPE} = $1;
        }
        if ($line =~ /status:\s+active/i) {
            $interface->{STATUS} = 'Up';
        }
        if ($line =~ /supported\smedia:/) {
            $interface->{VIRTUALDEV} = 0;
        }
    }
    push @interfaces, $interface if $interface;
    close $handle;

    return @interfaces;
}

1;
