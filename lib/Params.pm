# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2013 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>

package Bugzilla::Extension::SeeAlsoPlus::Params;
use strict;
use warnings;

use Bugzilla::Config::Common;
use Bugzilla::Util qw(trim detaint_natural);

sub get_param_list {
    return (
        {
            name => 'sap_invalid_cert_urls',
            type => 'l',
            default => '',
            checker => \&_check_regexpses,
        },
        {
            name => 'sap_cache_timeout',
            type => 't',
            default => '86400',
            checker => \&_check_timeout,
        },
    );
}

sub _check_regexpses {
    my $value = shift;
    my $line = 1;
    for (split(/\n/, $value)) {
        eval {qr/$_/};
        return "Error on line $line: ".$@ if $@;
        $line++;
    }
    return "";
}

sub _check_timeout {
    my $value = shift;
    if (!detaint_natural($value)) {
        return "Value is not an integer";
    }
    return "";
}

1;
