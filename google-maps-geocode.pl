#!/usr/bin/perl 

# NAME.pl
# date

use 5.010;
use strict;
use warnings;

package Google::Maps::Geocode;
use Moose;
use Moose::Util::TypeConstraints;

use JSON::XS;
use LWP::Simple;
use URI;
use URI::QueryParam;

enum 'Geocode::Sensor' => qw(true false);
enum 'Geocode::Host'   => qw(http https);
enum 'Geocode::Output' => qw(json xml);

has api_path => (
    is => 'ro',
    isa => 'Str',
    default => 'maps.google.com/maps/api/geocode/',
);

has api_host => (
    is => 'rw',
    isa => 'Geocode::Host',
    default => 'http',
    writer => 'set_host',
);

has output => (
    is => 'ro',
    isa => 'Geocode::Output',
    default => 'json',
);

has address => (
    is => 'rw', 
    isa => 'Str', 
    required => 1,
);

has sensor => (
    is => 'rw',
    isa => 'Geocode::Sensor',
    default => 'false',
);

sub build_request_uri {
    my $self = shift;
    my $uri = $self->api_host . '://' . $self->api_path . $self->output . '?';
    
    my $query = URI->new;
    $query->query_param(address => $self->address);
    $query->query_param(sensor  => $self->sensor);
    
    $uri .= $query->query;

    return $uri;
}

sub get_response {
    my $self = shift;
    my $uri = $self->build_request_uri;
    my $res = LWP::Simple::get($uri);
    say $res;
    return $self->process_response($res);
}

sub process_response {
    my $self = shift;
    my $res  = shift;

    if ($self->output eq 'json') {
        return $res;
        my $href = JSON::XS::decode_json($res);
        return $href;
    }
    else {
        warn "Unsupported output type: " . $self->type;
    }
}

package main;
use Data::Dumper;

my $geocode = Google::Maps::Geocode->new(
    address => 'Mirni dol Remete Zagreb Croatia',
);

say Dumper($geocode->get_response);
say $geocode->build_request_uri;

