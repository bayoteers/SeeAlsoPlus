# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2014 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>


package Bugzilla::Extension::SeeAlsoPlus::RemoteGitHub;
use strict;

use base qw(Bugzilla::Extension::SeeAlsoPlus::RemoteBase);

use JSON;

sub _issue_info {
    my $self = shift;
    if (!defined $self->{_issue_info}) {
        my $path = $self->uri->path;
        my ($owner, $repo, $id) = $path =~ /\/(.+)\/(.+)\/issues\/(\d+)/;
        $self->{_issue_info} = [$owner, $repo, $id];
    }
    return $self->{_issue_info};
}

sub id {
    my $self = shift;
    return $self->_issue_info->[2];
}

sub summary {
    my $self = shift;
    return $self->data->{title} || '-NO TITLE-';
}

sub status {
    my $self = shift;
    return uc $self->data->{state} || '-NO STATUS-';
}

sub description {
    my $self = shift;
    return $self->data->{body} || '-NO BODY-';
}

sub data {
    my $self = shift;
    $self->_fetch_data unless defined $self->{data};
    return $self->{data};
}


sub _fetch_data {
    my ($self) = @_;

    my $url = "https://api.github.com/repos". $self->uri->path;
    my $local_file = $self->cache_file;

    if ($self->{no_cache} || $self->cache_expired) {
        $self->fetch_file($local_file, $url) or return;
        $self->{no_cache} = 0;
    }
    open(my $fh, '<', $local_file);
    my $json_data = <$fh>;
    close($fh);
    $self->{data} = decode_json($json_data);
}

1;
