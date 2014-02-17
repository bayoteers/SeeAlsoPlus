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

use constant UPDATE_INTERVAL => 86400;

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

    my $path = $self->uri->path;
    my ($owner, $repo, $id) = $path =~ /\/(.+)\/(.+)\/issues\/(\d+)/;

    my $local_file = $self->cache_dir ."$owner-$repo-$id.json";
    my $url = "https://api.github.com/repos/$owner/$repo/issues/$id";

    if ($self->{no_cache} || !-e $local_file ||
            (time() - (stat($local_file))[9] > UPDATE_INTERVAL)) {
        my $response = $self->fetch_file($local_file, $url);
        if (!-e $local_file || !$response || $response->is_error) {
            $self->error($response ? $response->status_line : 'Download failed');
            return;
        }
        $self->{no_cache} = 0;
    }
    open(my $fh, '<', $local_file);
    my $json_data = <$fh>;
    close($fh);
    $self->{data} = decode_json($json_data);
}

1;
