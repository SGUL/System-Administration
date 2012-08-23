#!/usr/bin/perl
# Usage: ./rt_set_privileged_and_add_to_group.pl <username> <group>


use strict; 
use lib "/opt/rt4/lib"; 
use RT; 
use RT::User; 
use RT::Interface::CLI; 
use Data::Dumper;

RT::LoadConfig(); 
RT::Init(); 

# Create RT User Object
my $user = new RT::User($RT::SystemUser); 

# Instantiate the user object with the user passed as parameter
my $usertoadd = $ARGV[0];
$user->Load( $usertoadd ); 

# Set the privileged flag (1=privileged, 0=unprivileged)
$user->SetPrivileged(1);
 
# Get group object and instantiate it with the group name
my $group = new RT::Group($RT::SystemUser); 
my $inputgroup = $ARGV[1];
$group->LoadUserDefinedGroup( $inputgroup ); 

# Add user to group
$group->AddMember( $user->PrincipalObj->Id ); 

exit 1

