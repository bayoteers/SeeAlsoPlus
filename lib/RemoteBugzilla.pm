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


use Bugzilla::Constants;

use XML::Twig;

use constant REMOTE_TIMEOUT => 5;
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
    my $resolution = $self->{data}->{resolution} ?
        " / ".$self->{data}->{resolution} : "";
    return $self->{data}->{bug_status} . $resolution;
}

sub description {
    my $self = shift;
    $self->_parse_xml unless defined $self->{comments};
    return $self->{comments}->[0];
}

sub comments {
    my $self = shift;
    $self->_parse_xml unless defined $self->{comments};
    return $self->{comments};
}

sub _fetch_file {
    my ($url, $local_file) = @_;
    my $ua = LWP::UserAgent->new();
    $ua->timeout(REMOTE_TIMEOUT);
    $ua->protocols_allowed(['http', 'https']);

    # If the URL of the proxy is given, use it, else get this information
    # from the environment variable.
    my $proxy_url = Bugzilla->params->{'proxy_url'};
    if ($proxy_url) {
        $ua->proxy(['http'], $proxy_url);
        if (!$ENV{HTTPS_PROXY}) {
            # LWP does not handle https over proxy, so by setting the env
            # variables the proxy connection is handled by undelying library
            my $pu = URI->new($proxy_url);
            my ($user, $pass) = split(':',
                $pu->userinfo);
            $ENV{HTTPS_PROXY} = $pu->scheme . '://' . $pu->host .
                                ':' . $pu->port;
            $ENV{HTTPS_PROXY_USERNAME} = $user;
            $ENV{HTTPS_PROXY_PASSWORD} = $pass;
        }
    }
    else {
        $ua->env_proxy;
    }
    return eval { $ua->mirror($url, $local_file) };
}


sub _parse_xml {
    my ($self) = @_;

    my $id = $self->uri->query_param('id');

    my $local_file = $self->cache_dir . $id . '.xml';

    if ($self->{no_cache} || !-e $local_file ||
            (time() - (stat($local_file))[9] > UPDATE_INTERVAL)) {
        $self->uri->query_form(id => $id, ctype => 'xml');
        my $response = _fetch_file($self->uri->as_string, $local_file);
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
