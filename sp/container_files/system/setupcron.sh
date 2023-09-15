#!/bin/bash
CRONFILE=/opt/tier/tier-cron

#set env vars for cron job
#  this script creates /opt/tier/env.bash which is sourced by the cron job's script, which was not seeing the environment set by the Dockerfile
/opt/tier/setenv.sh

#build crontab file with random start time between midnight and 3:59am
echo "#send daily beacon to TIER Central" > ${CRONFILE}
echo $(expr $RANDOM % 59) $(expr $RANDOM % 3) "* * * /usr/local/bin/sendtierbeacon.sh >> /var/log/cron.log 2>&1" >> ${CRONFILE}
chmod 644 ${CRONFILE}

#install crontab
crontab ${CRONFILE}

#create cron logfile
touch /var/log/cron.log

