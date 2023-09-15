#!/bin/bash
LOGHOST="collector.testbed.tier.internet2.edu"
LOGPORT="5001"
if [ -s /opt/tier/env.bash ]; then
  . /opt/tier/env.bash
fi

#JSON/REST style
LOGTEXT="{ \"msgType\" : \"TIERBEACON\", \"msgName\" : \"TIER\", \"msgVersion\" : \"1.0\", \"tbProduct\" : \"$IMAGENAME\", \"tbProductVersion\" : \"$VERSION\", \"tbTIERRelease\" : \"$TIERVERSION\", \"tbMaintainer\" : \"$MAINTAINER\" }"


if [ -z "$TIER_BEACON_OPT_OUT" ]; then
  #send JSON
  echo $LOGTEXT > msgjson.txt
  curl -s -XPOST "${LOGHOST}:${LOGPORT}/" -H 'Content-Type: application/json' -T msgjson.txt 1>/dev/null
  if [ $? -eq 0 ]; then
        echo "tier_beacon;none;$ENV;$USERTOKEN;"`date`"; TIER beacon sent"
  else
        echo "tier_beacon;none;$ENV;$USERTOKEN;"`date`"; Failed to send TIER beacon"
  fi
  
  rm -f msgjson.txt
  
  #below is for syslog, F-TICKS style
  #`logger -n $LOGHOST -P $LOGPORT -t TIERBEACON $LOGTEXT`

fi

