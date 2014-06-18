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

use Bugzilla::BugUrl;
use Bugzilla::Error;
use Bugzilla::Util qw(trim);

use File::Path qw(make_path);
use Scalar::Util qw(blessed);

use LWP::UserAgent;

use Bugzilla::Extension::SeeAlsoPlus::Util qw(cache_base_dir);

use constant REMOTE_TIMEOUT => 5;

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

sub type {
    my $self = shift;
    my @type = split(/::/, ref($self));
    return $type[-1];
}

sub cache_dir {
    my $self = shift;
    if (! defined $self->{cache_dir}) {
        my @segments = $self->uri->path_segments;
        my $path = join('_', @segments[0..@segments-2]);

        my $local_path = cache_base_dir() . $self->uri->host . $path;
        if (!-d $local_path) {
            make_path($local_path);
        }
        $self->{cache_dir} = $local_path . '/';
    }
    return $self->{cache_dir};
}

sub cache_file {
    my $self = shift;
    return $self->cache_dir . $self->id . ".dat"
}

sub cache_timestamp {
    my $self = shift;
    return (stat($self->cache_file))[9] || 0;
}

sub cache_dt {
    my $self = shift;
    return DateTime->from_epoch(epoch => $self->cache_timestamp);
}

sub cache_expired {
    my $self = shift;
    return (time() - $self->cache_timestamp > Bugzilla->params->{sap_cache_timeout}) ? 1 : 0;
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

sub html_info {
    my $self = shift;
    if (!defined $self->{html_info}) {
        my $template = Bugzilla->template;
        my $result = "";
        $template->process("seealsoplus/info.html.tmpl",
            {item => $self}, \$result) || ($result = $template->error());
        $self->{html_info} = trim($result);
    }
    return $self->{html_info};
}

# The generic accessors that subclasses should implement

sub id {
    ThrowCodeError('unknown_method',
        { method => ref($_[0]) . '::id' });
}

sub summary {
    ThrowCodeError('unknown_method',
        { method => ref($_[0]) . '::summary' });
}

sub status {
    ThrowCodeError('unknown_method',
        { method => ref($_[0]) . '::status' });
}

sub description {
    ThrowCodeError('unknown_method',
        { method => ref($_[0]) . '::description' });
}

sub data {
    ThrowCodeError('unknown_method',
        { method => ref($_[0]) . '::data' });
}

sub _needs_valid_cert {
    my ($self, $url) = @_;
    $url ||= $self->uri->as_string;
    for my $regex (split(/\n/, Bugzilla->params->{sap_invalid_cert_urls} || ''))
    {
        next unless trim($regex);
        return 0 if ($url =~ /$regex/);
    }
    return 1;
}

sub fetch_file {
    my ($self, $local_file, $url) = @_;
    $url ||= $self->uri->as_string;
    $local_file ||= $self->cache_file;

    my $ua = LWP::UserAgent->new();
    if ($ua->can('ssl_opts')) {
        $ua->ssl_opts(verify_hostname => $self->_needs_valid_cert());
    }
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
            $ENV{HTTPS_PROXY} = $pu->scheme.'://'.$pu->host.':'.$pu->port;
            my ($user, $pass) = split(':', $pu->userinfo || "");
            $ENV{HTTPS_PROXY_USERNAME} = $user if defined $user;
            $ENV{HTTPS_PROXY_PASSWORD} = $pass if defined $pass;
        }
    }
    else {
        $ua->env_proxy;
    }
    my $response = eval { $ua->mirror($url, $local_file) };
    if (!-e $local_file || !$response || $response->is_error) {
        $self->error($response ? $response->status_line : 'Download failed');
        return 0;
    }
    return 1;
}

1;

__END__
