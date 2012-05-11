#!/usr/bin/perl

# this script made by pallotron@freaknet.org
#
# this script sniffs to an interface, searching for packets that match 
# the filter rule, it sends an email we this occurs with a simply and stupid
# email flood protection 

use Config::General;
use Net::Pcap;
use NetPacket::TCP;
use NetPacket::IP qw(:strip);
use NetPacket::Ethernet qw(:strip);
use Email::Send;
use Email::Send::SMTP;
use strict;

STDOUT->autoflush(1);

my ($email_to, $listen_if, $filter_name, $filter_rule, $notification_period);
my ($email_from, $smtp_server);

my $last_timestamp = 0;
my $curr_timestamp = time;
my $send_email = 1;

sub sniff {
	my ($dev, $email, $name, $filter) = @_;
	my ($pcap_t, $filter_t);
	my ($err, $net, $mask);
	my $promisc = 0;
	my $snaplen = 256;
	my $to_ms = 0;
	my $opt = 1;

	if ( (Net::Pcap::lookupnet($dev, \$net, \$mask, \$err) ) == -1 ) {
		die "Net::Pcap::lookupnet failed.  Error was $err";
	}

	my $pcap_t = Net::Pcap::open_live($dev, $snaplen, $promisc, $to_ms, \$err);
	$pcap_t || die "Can't create packet descriptor.  Error was $err";


	if ( Net::Pcap::compile($pcap_t, \$filter_t, $filter, $opt, $net) == -1 ) {
		die "Unable to compile filter string '$filter'\n";
	}

	Net::Pcap::setfilter($pcap_t, $filter_t);
	Net::Pcap::loop($pcap_t, -1, \&process_pkt, 0);
}

sub process_pkt {
	my ($user_data, $hdr, $pkt) = @_;

	my $tcp_obj = NetPacket::TCP->decode(ip_strip(eth_strip($pkt)));
	my $ip_obj  = NetPacket::IP->decode(eth_strip($pkt));

	$curr_timestamp = time;

	if( ($curr_timestamp - $last_timestamp >= $notification_period) or $send_email) {
		my $msgtxt = sprintf("%s: %s.\nDetails: %s:%s -> %s:%s\n\n",
			$curr_timestamp, $filter_name, $ip_obj->{src_ip},
			$tcp_obj->{src_port}, $ip_obj->{dest_ip}, $tcp_obj->{dest_port});

		print $msgtxt;
		my $subject = $filter_name;
		print "Mando email\n";
		sendemail($email_to, $subject, $msgtxt);
		$send_email=0;
		$last_timestamp = time;
	}

	#print($tcp_obj->{data});
}

sub sendemail {
	my ($to, $sbj, $msg) = @_;

	my $message=<<MESSAGE;
To: $to
From: $email_from
Subject: $sbj

$msg
		  
MESSAGE

	my $sender = Email::Send->new({mailer => 'SMTP'});
	$sender->mailer_args([Host => $smtp_server]);
	$sender->send($message);

}

sub main {
	my $numArgs = $#ARGV + 1;

	if ( $numArgs == 0 ) {
		print "You must provide the configfile path as an argument!\n";
		exit -1;
	}

	my $cfgfile = $ARGV[0];

	my $conf = new Config::General($cfgfile);
	my %config = $conf->getall;

	chomp(%config);

	$email_to            = $config{email_to};
	$listen_if           = $config{listen_interface};
	$filter_name         = $config{filter_name};
	$filter_rule         = $config{filter_rule};
	$notification_period = $config{notification_period};
	$email_from          = $config{email_from};
	$smtp_server         = $config{smtp_server};

	sniff($listen_if, $email_to, $filter_name, $filter_rule);
}

main;
