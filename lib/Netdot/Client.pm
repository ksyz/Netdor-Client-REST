package Netdot::Client;
# 2016 mi@v3.sk

use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

use Config::IniFiles;
use FindBin qw($RealBin);

use constant { OVERRIDE => 1 };

use Netdot::Client::REST;

sub new {
	my $class = shift;
	my $args = {
		netdot => undef,
		server => undef,
		username => undef,
		password => undef,
		config_file => undef,
		@_,
	};

	unless (defined $args->{netdot}) {
		if (grep { defined $args->{$_} } qw(serevr password username)) {
			$args->{netdot} = Netdot::Client::REST->new(%$args);
		}
		else {
			$args->{netdot} = Netdot::Client::REST->new(
				$class->configure($args->{config_file}));
		}
	}

	unless (defined $args->{netdot}) {
		die "Netdot::Client::REST instance undefinned";
	}

	return bless $args, $class;
};

sub configure {
	my ($caller, $config, $debug) = @_;

	my $cfg;
	for (
		$config, $ENV{NETDOT_CONF}, $ENV{HOME}."/.netdot.conf", 
		$ENV{PWD}."/netdot.conf", "$RealBin/netdot.conf"
	) {
		warn "Trying: $_" if $debug && $_;
		next 
			unless defined $_ && -f $_;
		$cfg = Config::IniFiles->new(-file => $_);
		last
			if $cfg;
	}

	die "No config file found.\n" 
		unless $cfg;

	return (
		server => $cfg->val('netdot', 'rest_url'),
		username => $cfg->val('netdot', 'username'),
		password => $cfg->val('netdot', 'password'),
	);
};

sub netdot {
	return shift->{netdot};
};

sub zone_import {
	my ($self, $zone_name, $zone_data, $metadata) = @_;
	my $zone;

	eval {
		$zone = $self->zone_get($zone_name);
	};
	if ($@) {
		$zone = $self->zone_create($zone_name);
	}

	$self->zone_update($zone, $metadata)
		if ($metadata);
	# return $self->zone_import_data($zone, $zone_data, OVERRIDE);
};

sub zone_import_data {
	my $self = shift;
	my ($zone, $zone_data, $overwrite) = @_;

	my $url = sprintf("%s/management/zone.html", $self->{netdot}{server});
	my $ua = $self->{netdot}{ua};
	my $data = {
		bulk_import_data => $zone_data,
		id => $zone->{id},
		import_overwrite => ($overwrite ? 'on' : 'off'),
		submit => 'Import',
		edit => 'bulk_import'
	};

	my $r = $ua->post($url, $data);
	return 1
		if ( $r->is_success );

	die $r->status_line;

};

sub zone_get {
	my ($self, $zone_name) = @_;
	my $zone = $self->{netdot}->get(sprintf('zone?name=%s', $zone_name));
	die sprintf("Zone name <%s> not found.\n")
		unless $zone->{Zone};
	my $id = (keys %{$zone->{Zone}})[0];
	$zone->{Zone}{$id}{id} = $id;
	return $zone->{Zone}{$id};
};

sub zone_delete {
	my ($self, $zone_name) = @_;
	die "Missing zone_name"
		unless $zone_name;
	if (looks_like_number($zone_name)) {
		$self->{netdot}->delete(sprintf('zone/%d', $zone_name));
	}
	else {
		my $zone = $self->zone_get($zone_name);
		$self->{netdot}->delete(sprintf('zone/%d', $zone->{id}));
	}
};

sub zone_create {
	my ($self, $zone_name) = @_;
	die "Missing zone_name"
		unless $zone_name;
	my $data = $self->{netdot}->post('zone', { name => $zone_name } );
	return $data;
};

sub zone_update {
	my ($self, $zone, $metadata) = @_;
	my $update = { %$zone, %$metadata };
	# delete $update->{id};
	delete $update->{contactlist};
	$update->{rname} =~ s/\@/./g;
	
	my $data = $self->{netdot}->post(
		sprintf('zone/%d', $zone->{id}), $update );
	return $data;
};

1;
