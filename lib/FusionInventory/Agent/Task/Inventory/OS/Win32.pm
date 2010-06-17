package FusionInventory::Agent::Task::Inventory::OS::Win32;

use strict;
use vars qw($runAfter);

use English qw(-no_match_vars);

$runAfter = ["FusionInventory::Agent::Task::Inventory::OS::Generic"];

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(getWmiProperties encodeFromWmi encodeFromRegistry);

use Encode;

# We don't need to encode to UTF-8 on Win7
sub encodeFromWmi {
    my ($string) = @_;

#  return (Win32::GetOSName() ne 'Win7')?encode("UTF-8", $string):$string; 
    encode("UTF-8", $string); 

}

sub encodeFromRegistry {
    my ($string) = @_;

    encode("UTF-8", $string); 

}

sub getWmiProperties {
    my $wmiClass = shift;
    my @keys = @_;

    eval {' 
        use Win32::OLE qw(in CP_UTF8);
        use Win32::OLE::Const;

        Win32::OLE->Option(CP => CP_UTF8);

        use Encode qw(encode)';
    };
    if ($@) {
        print "STDERR, Failed to load Win32::OLE: $@\n";
        return;
    }

    my $WMIServices = Win32::OLE->GetObject(
            "winmgmts:{impersonationLevel=impersonate,(security)}!//./" );


    if (!$WMIServices) {
        print STDERR Win32::OLE->LastError();
    }


    my @properties;
    foreach my $properties ( Win32::OLE::in( $WMIServices->InstancesOf(
                    $wmiClass ) ) )
    {
        my $tmp;
        foreach (@keys) {
            my $val = $properties->{$_};
            $tmp->{$_} = encodeFromWmi($val);
        }
        push @properties, $tmp;
    }

    return @properties;
}


sub isInventoryEnabled { return $OSNAME =~ /^MSWin32$/ }

sub doInventory {

}

1;
