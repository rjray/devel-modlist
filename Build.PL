#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
    module_name       => 'Devel::Modlist',
    license           => 'perl',
    requires          => { perl => '5.006' },
    build_requires    => { Test::More => 0 },
    # This *should* be "build_recommends", since it is only for the tests
    recommends        => { Test::Pod => 0, Test::Pod::Coverage => 0,
                           Module::Signature => 0 },
    dist_author       => 'Randy J. Ray <rjray@blackperl.com>',
    dist_abstract     => 'Collect a list of modules loaded at compile-time',
    dist_version_from => 'lib/Devel/Modlist.pm',
    sign              => 'here, please',
);

$build->add_to_cleanup(qw(META.yml Devel-Modlist-*));
$build->create_build_script;
