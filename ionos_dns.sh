#!/bin/bash
#
# TrueNAS has its own ACME server implementation. It only supports a few
# DNS challenge implementations, but allows for a script to implement
# the set/remove of the DNS records.
#
# This implements this feature for the Ionos DNS API.
#
# script [un]set hostname hostname value
# 
command=${1}
host=${2}
acmename=${3}
value=${4}

# Convert full hostname to domain name.  Also removes subdomain.
# xxx.example.org or xxx.sd.example.org -> example.org
domain=$(echo "$host" | sed -E 's/^([^.]+\.)*(.*\..*)/\2/')

# Optional running log file
LF="/dev/null"
date >> $LF
echo $* >> $LF

if [ -z "$value" ]; then
   echo "usage: ionos_dns: [un]set hostname acmename value"
   exit 1
fi

# IONOS API key
IONOS_PREFIX=<insert your prefix>
IONOS_SECRET=<insert your secret>

# Allow easier construction of commands that conflict with the shell
set -o noglob

# http request header
IONOS_API_KEY="X-API-Key: ${IONOS_PREFIX}.${IONOS_SECRET}"

# Get ZoneID 
R1=`curl -sX 'GET' \
    'https://api.hosting.ionos.com/dns/v1/zones' \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    -H "${IONOS_API_KEY}"`
ZID=$(echo "$R1" | jq ".[] | select(.name == \"${domain}\") | .id" | sed 's/"//g')
if [ -z "$ZID" ]; then
   echo "error: Domain not listed: $domain"
   exit 1
fi
echo "ZoneId for $domain is $ZID" >> $LF

if [ "$1" == "set" ]; then
    # Add domain record
    echo "Result:"
    R2=`curl -sX 'POST' \
        "https://api.hosting.ionos.com/dns/v1/zones/${ZID}/records" \
        -H 'accept: application/json' \
        -H "${IONOS_API_KEY}" \
        -H 'Content-Type: application/json' \
        -d "[{\"name\":\"${acmename}\",\"type\":\"TXT\",\"content\":\"${value}\",\"ttl\":3600,\"prio\":0,\"disabled\":false}]"`
    echo $R2 | jq >> $LF
    exit 0
fi
if [ "$1" == "unset" ]; then
    # Fetch recordID
    R2=`curl -sX 'GET' \
        "https://api.hosting.ionos.com/dns/v1/zones/${ZID}?suffix=${acmename}&recordType=TXT" \
        -H 'accept: application/json' \
        -H "${IONOS_API_KEY}"` 
    echo $R2 | jq >> $LF
    RID=$(echo "$R2" | jq ".records | .[] | select(.content == \"\\\"${value}\\\"\") | .id" | sed 's/"//g')
    if [ -z "$RID" ]; then
       echo "error: RecordID not listed for value: $value"
       exit 1
    fi
    echo "RecordID is $RID" >> $LF

    # Remove domain records 
    R3=`curl -sX 'DELETE' \
        "https://api.hosting.ionos.com/dns/v1/zones/${ZID}/records/${RID}" \
        -H 'accept: */*' \
        -H "${IONOS_API_KEY}"` 
    echo $R3 | jq >> $LF

    exit 0
fi

exit 1
