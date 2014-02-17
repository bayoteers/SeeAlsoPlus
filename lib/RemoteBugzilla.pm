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

use constant UPDATE_INTERVAL => 86400;

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

sub summary {
    my $self = shift;
    $self->_parse_xml unless defined $self->{data};
    return $self->{data}->{short_desc};
}

sub status {
    my $self = shift;
    $self->_parse_xml unless defined $self->{data};
    my $status = $self->{data}->{bug_status} || "---";
    my $resolution = $self->{data}->{resolution} || "---";
    return "$status / $resolution";
}

sub description {
    my $self = shift;
    $self->_parse_xml unless defined $self->{comments};
    return $self->{comments}->[0]->{text};
}

sub data {
    my $self = shift;
    $self->_parse_xml unless defined $self->{data};
    return $self->{data};
}

# Bugzilla specific
sub comments {
    my $self = shift;
    $self->_parse_xml unless defined $self->{comments};
    return $self->{comments};
}

sub _parse_xml {
    my ($self) = @_;

    my $id = $self->uri->query_param('id');

    my $local_file = $self->cache_dir . $id . '.xml';

    if ($self->{no_cache} || !-e $local_file ||
            (time() - (stat($local_file))[9] > UPDATE_INTERVAL)) {
        $self->uri->query_form(id => $id, ctype => 'xml');
        my $response = $self->fetch_file($local_file);
        if (!-e $local_file || !$response || $response->is_error) {
            $self->error($response ? $response->status_line : 'Download failed');
            return;
        }
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
    $self->{data} = \%bug;

    my @comments;
    for my $element ($bugxml->children('long_desc')) {
        push(@comments, {
            author => $element->first_child('who')->att('name'),
            date => $element->first_child('bug_when')->text,
            text => $element->first_child('thetext')->text,
        });
    }
    $self->{comments} = \@comments;
}

1;
