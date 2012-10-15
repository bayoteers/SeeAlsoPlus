# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2012 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>

package Bugzilla::Extension::SeeAlsoPlus;
use strict;
use base qw(Bugzilla::Extension);

use Bugzilla::Extension::SeeAlsoPlus::Util;

our $VERSION = '0.01';

sub webservice {
    my ($self, $args) = @_;
    $args->{dispatch}->{'SeeAlsoPlus'} =
        "Bugzilla::Extension::SeeAlsoPlus::WebService";
}

__PACKAGE__->NAME;
