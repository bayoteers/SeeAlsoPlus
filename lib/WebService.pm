# -*- Mode: perl; indent-tabs-mode: nil -*-
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (C) 2012 Jolla Ltd.
# Contact: Pami Ketolainen <pami.ketolainen@jollamobile.com>

=head1 NAME

Bugzilla::Extension::SeeAlsoPlus::WebService

=head1 DESCRIPTION

Web service methods for SeeAlsoPlus extension.

=cut

package Bugzilla::Extension::SeeAlsoPlus::WebService;
use strict;

use Bugzilla::Extension::SeeAlsoPlus::Util qw(get_remote_object);

use Bugzilla::Error;

use base qw(Bugzilla::WebService);

=head1 METHODS

=over

=item C<get>

Params:

    url         - URL of the remote item
    no_cache    - IF true, force fetching the remote item, not using the cache
    raw         - If true, include "raw" item data in the response

Returns: Hash presenting the remote item

    {
        url: URL of the item
        summary: Summary line of the item
        status: Status of the item
        description: Description of the item
        data: Raw data, if requested
    }

=cut

sub get {
    my ($self, $params) = @_;
    my $url = $params->{url};
    my $no_cache = $params->{no_cache} ? 1 : 0;
    my $raw = $params->{raw} ? 1 : 0;

    my $item = get_remote_object($url, $no_cache);
    my $result = {
        url => $item->url,
        summary => $item->summary,
        description => $item->description,
        status => $item->status,
        type => $item->type,
        error => $item->error,
    };
    if ($raw) {
        $result->{data} = $item->data;
    }
    return $result;
}

1;

__END__

=back

=head1 SEE ALSO

L<Bugzilla::WebService>
