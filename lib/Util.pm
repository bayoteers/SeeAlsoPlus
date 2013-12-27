# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2012 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>

=head1 NAME

Bugzilla::Extension::SeeAlsoPlus::Util

=head1 DESCRIPTION

Utility functions for SeeAlsoPlus extension.

=cut

package Bugzilla::Extension::SeeAlsoPlus::Util;
use strict;

use Bugzilla::BugUrl;
use Bugzilla::Constants qw(bz_locations);
use Bugzilla::Error;
use Bugzilla::Hook;

use Scalar::Util qw(blessed);

use base qw(Exporter);
our @EXPORT = qw(
    cache_base_dir
    get_remote_object
);

our $class_map;

sub REMOTE_CLASS {
    unless (defined $class_map) {
        $class_map = {
            'Bugzilla::BugUrl::Bugzilla' =>
                'Bugzilla::Extension::SeeAlsoPlus::RemoteBugzilla',
        };
        Bugzilla::Hook::process("see_also_plus_classes",
                { classes => $class_map });
    }
    return $class_map;
};

=head2 Functions

=over

=item C<cache_base_dir()>

Retruns:

    The base dir for remote object data cache

=cut

sub cache_base_dir {
    return bz_locations()->{'datadir'} . '/extensions/sap_cache/';
}

=item C<get_remote_object($url, $no_cache)>

Params:

    $url - URL string or BugUrl object
    $no_cache - if true, skips cache and fetches the data from remote source

Retruns:

    L<Bugzilla::Extension::SeeAlsoPlus::RemoteBase> based object presenting the
    remote bug/issue/whatever.

=cut

sub get_remote_object {
    my ($url, $no_cache) = @_;
    my $urlclass;
    if (blessed($url) && $url->isa('Bugzilla::BugUrl')) {
        $urlclass = $url->class;
    } else {
        $urlclass = Bugzilla::BugUrl->class_for($url);
    }
    if (defined $urlclass && defined REMOTE_CLASS->{$urlclass}) {
        my $remote_class = REMOTE_CLASS->{$urlclass};
        eval "use $remote_class";
        die $@ if $@;
        return $remote_class->new($url, $no_cache);
    } else {
        ThrowUserError('sap_remote_not_available', { url => $url });
    }
}
1;

__END__

=back
