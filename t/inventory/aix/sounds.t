#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use FusionInventory::Agent::Task::Inventory::OS::AIX::Sounds;

my %tests = (
    sample1 => []
);

plan tests => scalar keys %tests;

foreach my $test (keys %tests) {
    my $file = "resources/lsdev/$test.adapter";
    my @sounds = FusionInventory::Agent::Task::Inventory::OS::AIX::Sounds::_getSounds(file => $file);
    is_deeply(\@sounds, $tests{$test}, "sounds: $test");
}
