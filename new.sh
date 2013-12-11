#!/usr/bin/env bash

# Create a temporary file that we will use to store temporary values before sorting.
trac_tmp="$(mktemp /tmp/trac_tmp.XXXXXX)";

# Created
sqlite3 $1 "select id,time,owner from ticket" | awk -F"|" '{print $2 "|" $3 "|A|//trac/" $1}' | cut -c 11-16 --complement >> ${trac_tmp}

# Modified
sqlite3 $1 "select ticket,time,author from ticket_change" | awk -F"|" '{print $2 "|" $3 "|M|//trac/" $1}' | cut -c 11-16 --complement >> ${trac_tmp}

# Resolved
sqlite3 $1 "select ticket,time,author from ticket_change where field='resolution'" | awk -F"|" '{print $2 "|" $3 "|D|//trac/" $1}' | cut -c 11-16 --complement >> ${trac_tmp}

sort -n $trac_tmp
rm $trac_tmp
