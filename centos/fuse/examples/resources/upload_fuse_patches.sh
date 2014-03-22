#!/bin/bash

# halt on errors
set -e

# set debug mode
set -x

# configure logging to print line numbers
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'


COOKIEFILENAME="cookiesfusepatch.txt"
FMC_URL="http://172.17.0.2:8181"
USERNAME="admin"
PASSWORD="admin"
PRE_REQ_PATCH="/data/installers/jboss-fuse-6.0.0.redhat-024-p3-prereq.zip"
CUMULATIVE_PATCH="/data/installers/jboss-fuse-6.0.0.redhat-024-r1.zip"

PYTHON_JSON='
import json

temp = []
data = None
with open("output.json") as json_data:
    data = json.load(json_data)

temp = [ [it["id"],it["id"]] for it in data ]
temp = [ [it[0].replace(".", ""), it[1]] for it in temp ]
temp = [ [int(it[0]), it[1]] for it in temp ]

temp.sort(lambda x, y: cmp(x[0], y[0]))

print temp[-1][1]
'

alias curl="curl --cookie $COOKIEFILENAME"

curl --cookie-jar $COOKIEFILENAME -X POST --data "username=$USERNAME&password=$PASSWORD" $FMC_URL/rest/system/login

curl  --form "patch_file=@$PRE_REQ_PATCH;type=application/zip" $FMC_URL/rest/patches/files/upload 

curl -X GET $FMC_URL/rest/versions.json  > output.json

PATCHTARGETVERS=$(python -c "$PYTHON_JSON")

curl -H "Content-Type: application/json" -X POST --data "{\"target_version\":\"$PATCHTARGETVERS\"}" $FMC_URL/rest/patches/files/go

curl --form "patch_file=@$CUMULATIVE_PATCH;type=application/zip"  $FMC_URL/rest/patches/files/upload 

curl -X GET $FMC_URL/rest/versions.json  > output.json

PATCHTARGETVERS=$(python -c "$PYTHON_JSON")

curl -H "Content-Type: application/json" -X POST --data "{\"target_version\":\"$PATCHTARGETVERS\"}" $FMC_URL/rest/patches/files/go

rm $COOKIEFILENAME
