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

use Bugzilla::Install::Filesystem;

use Bugzilla::Extension::SeeAlsoPlus::Util;
use Bugzilla::Extension::SeeAlsoPlus::RemoteBugzilla;

our $VERSION = '0.01';

sub config_add_panels {
    my ($self, $args) = @_;
    $args->{panel_modules}->{SeeAlsoPlus} =
            "Bugzilla::Extension::SeeAlsoPlus::Params";
}

sub install_filesystem {
    my ($self, $args) = @_;
    $args->{create_dirs}->{cache_base_dir()} =
            Bugzilla::Install::Filesystem::DIR_CGI_WRITE;
}

sub template_before_process {
    my ($self, $args) = @_;
    if ($args->{file} eq 'global/header.html.tmpl') {
        my $vars = $args->{vars};
        if ($vars->{template}->name eq 'bug/show.html.tmpl' ||
            $vars->{template}->name eq 'bug/process/results.html.tmpl')
        {
            $vars->{javascript_urls} ||= [];
            push(@{$vars->{javascript_urls}},
                "extensions/SeeAlsoPlus/web/seealsoplus.js");
            $vars->{style_urls} ||= [];
            push(@{$vars->{style_urls}},
                "extensions/SeeAlsoPlus/web/styles.css");
        }
    }
}

sub webservice {
    my ($self, $args) = @_;
    $args->{dispatch}->{'SeeAlsoPlus'} =
        "Bugzilla::Extension::SeeAlsoPlus::WebService";
}

__PACKAGE__->NAME;
