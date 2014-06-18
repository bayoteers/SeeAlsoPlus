# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2012 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>




package Bugzilla::Extension::SeeAlsoPlus::RemoteBugzilla;
use strict;

use base qw(Bugzilla::Extension::SeeAlsoPlus::RemoteBase);

use XML::Twig;

use constant FIELDS => qw(
    bug_id
    short_desc
    creation_ts
    delta_ts
    product
    component
    bug_status
    resolution
    priority
    bug_severity
);

sub id {
    my $self = shift;
    return $self->uri->query_param('id');
}

sub summary {
    my $self = shift;
    return $self->data->{short_desc};
}

sub status {
    my $self = shift;
    my $status = $self->data->{bug_status} || "---";
    my $resolution = $self->data->{resolution} || "---";
    return "$status / $resolution";
}

sub description {
    my $self = shift;
    return $self->data->{comments}->[0]->{text};
}

sub data {
    my $self = shift;
    $self->_parse_xml unless defined $self->{data};
    return $self->{data};
}

sub _parse_xml {
    my ($self) = @_;

    my $id = $self->uri->query_param('id');
    my $local_file = $self->cache_file;

    if ($self->{no_cache} || $self->cache_expired) {
        $self->uri->query_form(id => $id, ctype => 'xml');
        $self->fetch_file() or return;
        $self->{no_cache} = 0;
    }
    my $xml = XML::Twig->new()->safe_parsefile($local_file);
    if (! defined $xml) {
        $self->error($@);
        return;
    }
    my $bugxml = $xml->root->first_child("bug");
    if ($bugxml->att('error')) {
        $self->error($bugxml->att('error'));
        return;
    }
    my %bug;
    for my $field (FIELDS) {
        my $element = $bugxml->first_child($field);
        $bug{$field} = $element ? $element->text : '';
    }
    for my $field (qw(assigned_to reporter)) {
        my $element = $bugxml->first_child($field);
        $bug{$field} = $element->text;
        $bug{$field . '_real_name'} = $element->att('name');
    }
    my @comments;
    for my $element ($bugxml->children('long_desc')) {
        push(@comments, {
            author => $element->first_child('who')->att('name'),
            date => $element->first_child('bug_when')->text,
            text => $element->first_child('thetext')->text,
        });
    }
    $bug{comments} = \@comments;
    $self->{data} = \%bug;
}

1;
