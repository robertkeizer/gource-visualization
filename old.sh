#!/usr/bin/env bash

GIT_REPOS="it";
TRAC_INSTANCES="/usr/local/trac/it /usr/local/trac/xxx";

# Run through all the repositories defined..
i=0
for repo in $GIT_REPOS; do
        # 1. Generate a Gource custom log files for each repo. This can be facilitated by the --output-custom-log FILE option of Gource as of 0.29:
        logfile="$(mktemp /tmp/gource.XXXXXX)"
        gource --output-custom-log "${logfile}" ${repo}
        # 2. If you want each repo to appear on a separate branch instead of merged onto each other (which might also look interesting), you can use a 'sed' regular expression to add an extra parent directory to the path of the files in each project:
        sed -i -E "s#(.+)\|#\1|/${repo}#" ${logfile}
        logs[$i]=$logfile
        let i=$i+1
done

combined_log="$(mktemp /tmp/gource.XXXXXX)"
cat ${logs[@]} | sort -n > $combined_log
rm ${logs[@]}

# Define the trac temp
trac_tmp="$(mktemp /tmp/trac_tmp.XXXXXX)";

# Go through the trac instances
for trac in $TRAC_INSTANCES; do

        # Split off the name of the directory.. usually the trac instance name.
        # This is used as the nice name that gets shoved into gource.
        trac_name="`echo $trac | sed 's/.*\///'`";

        # Do a sql query to get the information regarding created tickets. Specifically including the ticket id, the time, and the owner.
        sqlite3 $trac/db/trac.db "select id,time,owner from ticket" | awk -v trac=$trac_name -F"|" '{print $2 "|" $3 "|A|//trac/" trac "/" $1}' | cut -c 11-16 --complement >> ${trac_tmp}

        # Do a sql query to get all the modifications for the tickets.
        sqlite3 $trac/db/trac.db "select ticket,time,author from ticket_change" | awk -v trac=$trac_name -F"|" '{print $2 "|" $3 "|M|//trac/" trac "/" $1}' | cut -c 11-16 --complement >> ${trac_tmp}

        # Do a sql query to get the specific resolution modifications. These are basically 'close' operations.. we translate them here as deletions.
        sqlite3 $trac/db/trac.db "select ticket,time,author from ticket_change where field='resolution'" | awk -v trac=$trac_name -F"|" '{print $2 "|" $3 "|D|//trac/" trac "/" $1}' | cut -c 11-16 --complement >> ${trac_tmp}
done;

# Note that $git_log contains the location to
# the log of git messages and $trac_tmp contains the location to the 
# log of trac messages.

cat $combined_log $trac_tmp | sort -n | grep -v "||"

rm $combined_log $trac_tmp;
