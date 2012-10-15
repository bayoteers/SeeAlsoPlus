# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2012 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>

=head1 NAME

Bugzilla::Extension::SeeAlsoPlus::RemoteBase

=head1 DESCRIPTION

This is the base class presenting the additional info related to BugUrls.

=cut

package Bugzilla::Extension::SeeAlsoPlus::RemoteBase;
use strict;

use Bugzilla::Extension::SeeAlsoPlus::RemoteBugzilla;

use Bugzilla::BugUrl;
use Bugzilla::Constants;

use File::Path qw(make_path);
use Scalar::Util qw(blessed);

sub new {
    my ($class, $url, $no_cache) = @_;
    my $uri = (blessed($url) && $url->isa('Bugzilla::BugUrl')) ?
        URI->new($url->name) : URI->new($url);
    my $object = {
        uri => $uri,
        url => $uri->as_string,
        no_cache => $no_cache ? 1 : 0,
    };
    bless($object, $class);
    return $object;
}

sub uri {return $_[0]->{uri}}
sub url {return $_[0]->{url}}

sub cache_dir {
    my $self = shift;
    if (! defined $self->{cache_dir}) {
        my @segments = $self->uri->path_segments;
        my $path = join('_', @segments[0..@segments-2]);

        my $local_path = bz_locations()->{'datadir'} . '/extensions/sap_cache/' .
            $self->uri->host . $path;
        if (!-d $local_path) {
            make_path($local_path);
        }
        $self->{cache_dir} = $local_path . '/';
    }
    return $self->{cache_dir};
}

sub error {
    my ($self, $error) = @_;
    $self->{errors} ||= [];
    if (defined $error) {
        $error ||= 'Unknown error';
        push(@{$self->{errors}}, $error);
    } else {
        return join(' | ', @{$self->{errors}});
    }
}

# The generic accessors that subclasses should implement
sub summary {
    my $self = shift;
    ThrowCodeError('unknown_method',
        { method => ref($self) . '::summary' });
}

sub status {
    my $self = shift;
    ThrowCodeError('unknown_method',
        { method => ref($self) . '::status' });
}

sub description {
    my $self = shift;
    ThrowCodeError('unknown_method',
        { method => ref($self) . '::description' });
}

1;

__END__
