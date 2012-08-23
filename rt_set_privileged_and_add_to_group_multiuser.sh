#!/bin/bash
export RT_HOME=/opt/rt4
P1=./
# this file contains a username on each line
U1=./userlist
GROUPNAME="mygroup"

while read line; do
        set -- $line
        echo "Editing User: "$1 $2
        /usr/bin/perl ${P1}rt_set_privileged_and_add_to_group.pl $1 "$GROUPNAME"
done<$U1
