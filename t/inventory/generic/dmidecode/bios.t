#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FusionInventory::Agent::Logger;
use FusionInventory::Agent::Task::Inventory::OS::Generic::Dmidecode::Bios;

my %tests = (
    'freebsd-6.2' => {
        bios => {
          'MMANUFACTURER' => undef,
          'SSN' => undef,
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => undef,
          'MSN' => undef,
          'SMODEL' => undef,
          'SMANUFACTURER' => undef,
          'BDATE' => undef,
          'MMODEL' => 'CN700-8237R',
          'BVERSION' => undef
        },
        hardware => {
            UUID     => undef,
        }
    },
    'freebsd-8.1' => {
        bios => {
          'MMANUFACTURER' => 'Hewlett-Packard',
          'SSN' => 'CNF01207X6',
          'SKUNUMBER' => 'WA017EA#ABF',
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'Hewlett-Packard',
          'MSN' => 'CNF01207X6',
          'SMODEL' => 'HP Pavilion dv6 Notebook PC',
          'SMANUFACTURER' => 'Hewlett-Packard',
          'BDATE' => '05/17/2010',
          'MMODEL' => '3659',
          'BVERSION' => 'F.1C'
        },
        hardware => {
            UUID => '30464E43-3231-3730-5836-C80AA93F35FA'
        },
    },
    'linux-2.6' => {
        bios => {
          'MMANUFACTURER' => 'Dell Inc.',
          'SSN' => 'D8XD62J',
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'Dell Inc.',
          'MSN' => '.D8XD62J.CN4864363E7491.',
          'SMODEL' => 'Latitude D610',
          'SMANUFACTURER' => 'Dell Inc.',
          'BDATE' => '10/02/2005',
          'MMODEL' => '0XD762',
          'BVERSION' => 'A06'
        },
        hardware => {
            UUID     => '44454C4C-3800-1058-8044-C4C04F36324A',
        }
    },
    'openbsd-3.7' => {
        bios => {
          'MMANUFACTURER' => 'Tekram Technology Co., Ltd.',
          'SSN' => undef,
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'Award Software International, Inc.',
          'MSN' => undef,
          'SMODEL' => 'VT82C691',
          'SMANUFACTURER' => 'VIA Technologies, Inc.',
          'BDATE' => '02/11/99',
          'MMODEL' => 'P6PROA5',
          'BVERSION' => '4.51 PG'
        },
        hardware => {
            UUID     => undef,
        }
    },
    'openbsd-3.8' => {
        bios => {
          'MMANUFACTURER' => 'Dell Computer Corporation',
          'SSN' => '2K1012J',
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'Dell Computer Corporation',
          'MSN' => '..CN717035A80217.',
          'SMODEL' => 'PowerEdge 1800',
          'SMANUFACTURER' => 'Dell Computer Corporation',
          'BDATE' => '09/21/2005',
          'MMODEL' => '0P8611',
          'BVERSION' => 'A05'
        },
        hardware => {
            UUID     => '44454C4C-4B00-1031-8030-B2C04F31324A',
        }
    },
    'rhel-2.1' => {
        bios => {
          'MMANUFACTURER' => undef,
          'SSN' => 'KBKGW40',
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'IBM',
          'MSN' => 'NA60B7Y0S3Q',
          'SMODEL' => '-[84803AX]-',
          'SMANUFACTURER' => 'IBM',
          'BDATE' => undef,
          'MMODEL' => undef,
          'BVERSION' => '-[JPE130AUS-1.30]-'
        },
        hardware => {
            UUID     => undef,
        }
    },
    'rhel-3.4' => {
        bios => {
          'MMANUFACTURER' => 'IBM',
          'SSN' => 'KDXPC16',
          'SKUNUMBER' => undef,
          'ASSETTAG' => '12345678901234567890123456789012',
          'BMANUFACTURER' => 'IBM',
          'MSN' => '#A123456789',
          'SMODEL' => 'IBM eServer x226-[8488PCR]-',
          'SMANUFACTURER' => 'IBM',
          'BDATE' => '08/25/2005',
          'MMODEL' => 'MSI-9151 Boards',
          'BVERSION' => 'IBM BIOS Version 1.57-[PME157AUS-1.57]-'
        },
        hardware => {
            UUID     => 'A8346631-8E88-3AE3-898C-F3AC9F61C316',
        }
    },
    'rhel-3.9' => {
        bios => {
          'MMANUFACTURER' => undef,
          'SSN' => '0',
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'innotek GmbH',
          'MSN' => undef,
          'SMODEL' => 'VirtualBox',
          'SMANUFACTURER' => 'innotek GmbH',
          'BDATE' => '12/01/2006',
          'MMODEL' => undef,
          'BVERSION' => 'VirtualBox'
        },
        hardware => {
	    UUID     => 'AE698CFC-492A-4C7B-848F-8C17D24BC76E',
        }
    },

    'rhel-4.3' => {
        bios => {
          'MMANUFACTURER' => 'IBM',
          'SSN' => 'KDMAH1Y',
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'IBM',
          'MSN' => '48Z1LX',
          'SMODEL' => '-[86494jg]-',
          'SMANUFACTURER' => 'IBM',
          'BDATE' => '03/14/2006',
          'MMODEL' => 'MS-9121',
          'BVERSION' => '-[OQE115A]-'
        },
        hardware => {
            UUID => '0339D4C3-44C0-9D11-A20E-85CDC42DE79C',
        }
    },
    'rhel-4.6' => {
        bios => {
          'MMANUFACTURER' => undef,
          'SSN' => 'GB8814HE7S',
          'SKUNUMBER' => undef,
          'ASSETTAG' => undef,
          'BMANUFACTURER' => 'HP',
          'MSN' => undef,
          'SMODEL' => 'ProLiant ML350 G5',
          'SMANUFACTURER' => 'HP',
          'BDATE' => '01/24/2008',
          'MMODEL' => undef,
          'BVERSION' => 'D21'
        },
        hardware => {
            UUID => '34313236-3435-4742-3838-313448453753',
        }
    },
    'windows' => {
        bios => {
          'MMANUFACTURER' => 'TOSHIBA',
          'SSN' => 'X2735244G',
          'SKUNUMBER' => undef,
          'ASSETTAG' => '0000000000',
          'BMANUFACTURER' => 'TOSHIBA',
          'MSN' => '$$T02XB1K9',
          'SMODEL' => 'Satellite 2410',
          'SMANUFACTURER' => 'TOSHIBA',
          'BDATE' => '08/13/2002',
          'MMODEL' => 'Portable PC',
          'BVERSION' => 'Version 1.10'
        },
        hardware => {
            UUID     => '7FB4EA00-07CB-18F3-8041-CAD582735244',
        }
    },
    'linux-1' => {
        bios => {
          'MMANUFACTURER' => 'ASUSTeK Computer INC.',
          'SSN' => 'System Serial Number',
          'SKUNUMBER' => 'To Be Filled By O.E.M.',
          'ASSETTAG' => 'Asset-1234567890',
          'BMANUFACTURER' => 'American Megatrends Inc.',
          'MSN' => 'MS1C93BB0H00980',
          'SMODEL' => 'System Product Name',
          'SMANUFACTURER' => 'System manufacturer',
          'BDATE' => '04/07/2009',
          'MMODEL' => 'P5Q',
          'BVERSION' => '2102'
        },
        hardware => {
            UUID => '40EB001E-8C00-01CE-8E2C-00248C590A84',
        }

    }
);

plan tests => (scalar keys %tests) * 2;

my $logger = FusionInventory::Agent::Logger->new();

foreach my $test (keys %tests) {
    my $file = "resources/dmidecode/$test";
    my ($bios, $hardware) = FusionInventory::Agent::Task::Inventory::OS::Generic::Dmidecode::Bios::_getBiosHardware($logger, $file);
    is_deeply($bios, $tests{$test}->{bios}, $test);
    is_deeply($hardware, $tests{$test}->{hardware}, $test);

}