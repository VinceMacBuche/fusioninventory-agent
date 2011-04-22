#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FusionInventory::Agent::Task::Inventory::OS::AIX::Modems;

my %tests = (
    sample1 => []
);

plan tests => scalar keys %tests;

foreach my $test (keys %tests) {
    my $file = "resources/lsdev/$test.adapter";
    my @modems = FusionInventory::Agent::Task::Inventory::OS::AIX::Modems::_getModems(file => $file);
    is_deeply(\@modems, $tests{$test}, "modems: $test");
}
