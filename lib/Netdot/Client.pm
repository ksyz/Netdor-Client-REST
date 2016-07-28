package Netdot::Client;
# 2016 mi@v3.sk

use strict;
use warnings;
use Data::Dumper;

use Config::IniFiles;
use FindBin qw($RealBin);

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
			$args->{netdot} = Netdot::Client::REST->new($class->configure($args->{config_file}));
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
	my $self = shift;
	my $n = $self->{netdot};
	my ($zone, $zone_data, $overwrite) = @_;
	my $url_id = sprintf("%s/management/zone.html?id=%d&view=bulk_import", $n->{server}, $zone->{id});
	my $url = sprintf("%s/management/zone.html", $n->{server});
	my $ua = $n->ua;
	my $data = {
		bulk_import_data => $zone_data,
		id => $zone->{id},
		import_overwrite => 'on',
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
	my $n = $self->{netdot};
	my $zone = $n->get(sprintf('zone?name=%s', $zone_name));
	die sprintf("Zone name <%s> not found.\n")
		unless $zone->{Zone};
	my $id = (keys %{$zone->{Zone}})[0];
	$zone->{Zone}{$id}{id} = $id;
	return $zone->{Zone}{$id};
};

1;
