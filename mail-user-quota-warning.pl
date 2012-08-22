#!/usr/bin/perl
use Mozilla::LDAP::Conn;                # Main "OO" layer for LDAP
use Mozilla::LDAP::Utils;               # LULU, utilities.
use Quota;
use warnings;
#use strict;
# connect to LDAP host
my $ldap_host="localhost";
my $ldap_port="389";
my $user;

# Set up an LDAP connection
my $search_base="ou=people,o=your.domain.com";
my $conn = new Mozilla::LDAP::Conn($ldap_host,
                                $ldap_port,
                                "cn=<allowed user>",
                                "<password>",
                                "") || die "Can't connect to $ldap_host.\n";

# Get entries from the LDAP connection
# Search base and query can be adapted
my $entry = $conn->search($search_base, "subtree", "(uid=*)");


# Loop through all entries
while ($entry) {
        my $email=$entry->{"mail"}[0];
	my $uid=$entry->{"uid"}[0];
	# We store the homedirectory in an LDAP attribute
	my $homedir=$entry->{"homedirectory"}[0];
 	my $path = {};

	# Check if homedir is defined, as not all users might have a home directory
	if (defined($homedir)) {
		my @path = split('/', $homedir);
		my $home = '/'. $path[1];
                # the Quota library needs a filesystem to work on
		# hence this script checks only for quotas on a single file system
		# (that hosting the home directory)
		my $dev = Quota::getqcarg($home);
		my $userid = getpwnam($uid);
		my $bc, my $bs, my $bh, my $bt, my $fc, my $fs, my $fh, my $ft;
		# get all quota info from the Quota library
		# Output very similar to quota system command 
		($bc,$bs,$bh,$bt,$fc,$fs,$fh,$ft) = Quota::query($dev, $userid);
		if (defined($bc)) {
			$percent = -1;
			if ($bs != 0) {
				$percent = $bc*100/$bs;
			}
			$available = $bs/1024;
			$used = $bc/1024;
			
			# string conversions
			$percent_str = sprintf "%.0f", $percent;
			$used_str = sprintf "%.0f", $used;
			$available_str = sprintf "%.0f", $available;
			# there is a quota defined, and its usage is > 80%
			if (($available > 1) && ($percent > 80)) {
				# if it's over 100%, the user is over quota
				$over=0;
				if ($used >= $available) {
					$over=1;
				}
				if (defined($email)) {
					&send_notification("<FROM email address>", "<REPLY TO email address>", $email, $over, $percent_str, $used_str, $available_str, $uid, $email);
				}
			}
		}
	}
        $entry = $conn->nextEntry();
}

# the sendmail work is done by this procedure
sub send_notification
{
$additional = "You are using *$_[4]%* of your disk quota allowance ($_[5]MB of $_[6]MB).\n";

if ($_[3]) {
	$additional = "You are currently *over quota*.\n";
}

$va="Dear user,
this is an automated message.

$additional

Please contact ... if you need an increase.

Your username is *$_[7]* and your e-mail address is *$_[8]*

Best regards,
";

	my $from = "From: $_[0]\n";
	my $reply_to = "Reply-to: $_[1]\n"; 
	my $subject = "Subject: Disk quota warning\n"; 
	my $content = "$va.\n\n"; 
	my $send_to = "To: $_[2]\n"; 
	my $sendmail = "/usr/sbin/sendmail -t";

	open(SENDMAIL, "|$sendmail") or die "Cannot open $sendmail: $!"; 
	print SENDMAIL $reply_to; 
	print SENDMAIL $from; 
	print SENDMAIL $subject; 
	print SENDMAIL $send_to;
	print SENDMAIL "Content-type: text/plain\n\n"; 
	print SENDMAIL $content; 
	close(SENDMAIL);

	# Write log
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime;
	$year += 1900;
	$mon += 1;
 
	my $datetime = sprintf "%02d/%02d/%04d %02d:%02d:%02d", $mday, $mon, $year, $hour, $min, $sec;

	open (MYFILE, '>>/tmp/quotawarning.log');
	print MYFILE "[$datetime] Sent mail to $_[2] - $_[8] ($_[7]) is using $_[4]% ($_[5]/$_[6]), so T/F is $_[3]\n";
	close (MYFILE);
}



