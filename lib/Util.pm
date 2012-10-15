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

use Bugzilla::Extension::SeeAlsoPlus::RemoteBugzilla;

use Bugzilla::BugUrl;
use Bugzilla::Error;

use Scalar::Util qw(blessed);

use base qw(Exporter);
our @EXPORT = qw(
    get_remote_object
);

use constant REMOTE_CLASS => {
    'Bugzilla::BugUrl::Bugzilla' =>
        'Bugzilla::Extension::SeeAlsoPlus::RemoteBugzilla',
};

=head2 Functions

=over

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
        return REMOTE_CLASS->{$urlclass}->new($url, $no_cache);
    } else {
        ThrowUserError('sap_remote_not_available', { url => $url })
    }
}
1;

__END__

=back
