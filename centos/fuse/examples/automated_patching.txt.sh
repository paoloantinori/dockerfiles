#!/bin/bash

##########################################################################################################
# Description:
# This example will guide you through a simple Red Hat JBoss Fuse setup.
# We are going to start 3 docker container that will represent the nodes of your network.
# On the noode called "root" we will be manually starting the instance of JBoss FUse.
# Then we will be start using Fabric to provision other JBoss Fuse instances on the remaining 2 nodes.
# At the end of this process we will join all them togheter to build a distributed registry based,
# leveraging Apache Zookeeper.
#
# Dependencies:
# - docker 
# - sshpass, used to avoid typing the pass everytime (not needed if you are invoking the commands manually)
# to install on Fedora/Centos/Rhel: 
# sudo yum install -y docker-io sshpass
# 
# to install on MacOSX:
# sudo port install sshpass
# or
# brew install https://raw.github.com/eugeneoden/homebrew/eca9de1/Library/Formula/sshpass.rb
#
# Prerequesites:
# - run docker in case it's not already
# sudo service docker start
#
# Notes:
# - if you don't want to use docker, just assign to the ip addresses of your own boxes to environment variable
#######################################################################################################


################################################################################################
#####             Preconfiguration and helper functions. Skip if not interested.           #####
################################################################################################


# set debug mode
set -x

# configure logging to print line numbers
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# ulimits values needed by the processes inside the container
ulimit -u 4096
ulimit -n 4096

# helper ssh macro for password less authentication + ssh optimization "-p admin" is the password that it types for you
alias ssh="sshpass -p admin ssh -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"

# remove old docker containers with the same names
docker stop root  

docker rm root 
 

# create your lab
docker run -d -t -i --name root fuse


# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' root)


########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh="$SSH_PATH -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"
alias ssh2host="$SSH_PATH -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=180 -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR fuse@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2fabric="sshpass -p admin $SSH_PATH -p 8101 -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ROOT"

# halt on errors
set -e



################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

# start fuse on root node 
ssh2host "/opt/rh/jboss-fuse-*/bin/start"


############################# here you are starting to interact with Fuse/Karaf

# wait for critical components to be available before progressing with other steps
ssh2fabric "wait-for-service -t 300000 org.linkedin.zookeeper.client.LifecycleListener"
ssh2fabric "wait-for-service -t 300000 org.fusesource.fabric.maven.MavenProxy"

# create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
ssh2fabric "fabric:create --clean -r localip -g localip ; wait-for-service -t 300000 org.jolokia.osgi.servlet.JolokiaContext" 

# ssh2fabric "fabric:profile-edit --pid org.ops4j.pax.web/org.osgi.service.http.port=8013 default ; 
# fabric:profile-edit --delete -r mvn:io.hawt/hawtio-karaf/1.0/xml/features default ;
# fabric:profile-edit -r mvn:io.hawt/hawtio-karaf/1.2.2/xml/features default ;
# fabric:profile-edit --features hawtio default"

# install fmc
ssh2fabric "container-add-profile root fmc"

# stop default broker created automatically with fabric
# ssh2fabric "stop org.jboss.amq.mq-fabric" 


### ssh2fabric 'wait-for-service -t 3000 "(&(objectClass=javax.servlet.ServletContext)(osgi.web.symbolicname=org.fusesource.fabric.fabric-rest))"'
### ssh2fabric 'wait-for-service -t 3000 "(&(objectClass=org.osgi.service.cm.ManagedService)(Bundle-SymbolicName=org.fusesource.fabric.fabric-rest))" '
### ssh2fabric 'wait-for-service -t 3000 "(&(objectClass=org.osgi.service.blueprint.container.BlueprintContainer)(osgi.blueprint.container.symbolicname=org.fusesource.fabric.fabric-rest))"'

set +e


ssh2fabric 'dev:wait-for-service -t 30000  "(&(objectClass=org.apache.felix.service.command.Function)(osgi.command.scope=shell)(osgi.command.function=each))"'
ssh2fabric 'dev:wait-for-service -t 30000  "(&(objectClass=javax.servlet.ServletContext)(osgi.web.symbolicname=org.fusesource.fabric.fabric-rest))" '
ssh2fabric 'dev:wait-for-service -t 30000  "(&(objectClass=org.osgi.service.cm.ManagedService)(Bundle-SymbolicName=org.fusesource.fabric.fabric-rest))" '
ssh2fabric 'dev:wait-for-service -t 30000  "(&(objectClass=org.osgi.service.blueprint.container.BlueprintContainer)(osgi.blueprint.container.symbolicname=org.fusesource.fabric.fabric-rest))" '
ssh2fabric 'dev:wait-for-service -t 30000  "(&(objectClass=org.osgi.service.blueprint.container.BlueprintContainer)(osgi.blueprint.container.symbolicname=org.fusesource.fabric.fabric-core-agent-jclouds))" '



### ssh2fabric 'shell:each [1 2 3 4 5] {echo loop$it ; sleep 3000 ; wait-for-service -t 3000 "(&(objectClass=javax.servlet.ServletContext)(osgi.web.symbolicname=org.fusesource.fabric.fabric-rest))" }'
### ssh2fabric 'shell:each [1 2 3 4 5] {echo loop$it ; sleep 3000 ; wait-for-service -t 3000 "(&(objectClass=org.osgi.service.cm.ManagedService)(Bundle-SymbolicName=org.fusesource.fabric.fabric-rest))" }'
### ssh2fabric 'shell:each [1 2 3 4 5] {echo loop$it ; sleep 3000 ; wait-for-service -t 3000 "(&(objectClass=org.osgi.service.blueprint.container.BlueprintContainer)(osgi.blueprint.container.symbolicname=org.fusesource.fabric.fabric-rest))" }'

set -e
################# start patching procedure

COOKIEFILENAME="cookiesfusepatch.txt"
FMC_URL="http://$IP_ROOT:8181"
USERNAME="admin"
PASSWORD="admin"
PRE_REQ_PATCH="jboss-fuse-6.0.0.redhat-024-p3-prereq.zip"
CUMULATIVE_PATCH="jboss-fuse-6.0.0.redhat-024-r1.zip"

## helper python script to extract json data. an alternative could be using jq
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

## scripted interaction with fmc
alias curl="curl --cookie $COOKIEFILENAME"

while [[ Xtrue != X$(curl --cookie-jar $COOKIEFILENAME -X POST --data "username=$USERNAME&password=$PASSWORD" $FMC_URL/rest/system/login) ]]; do echo "not logged yet"; sleep 3s ; done 

# curl --cookie-jar $COOKIEFILENAME -X POST --data "username=$USERNAME&password=$PASSWORD" $FMC_URL/rest/system/login

curl  --form "patch_file=@$PRE_REQ_PATCH;type=application/zip" $FMC_URL/rest/patches/files/upload 

curl -X GET $FMC_URL/rest/versions.json  > output.json

VERSIONE_BASE=$(python -c "$PYTHON_JSON")

curl -H "Content-Type: application/json" -X POST --data "{\"target_version\":\"$VERSIONE_BASE\"}" $FMC_URL/rest/patches/files/go

curl --form "patch_file=@$CUMULATIVE_PATCH;type=application/zip"  $FMC_URL/rest/patches/files/upload 

curl -X GET $FMC_URL/rest/versions.json  > output.json

VERSION_PRE_REQ=$(python -c "$PYTHON_JSON")

curl -H "Content-Type: application/json" -X POST --data "{\"target_version\":\"$VERSION_PRE_REQ\"}" $FMC_URL/rest/patches/files/go

curl -X GET $FMC_URL/rest/versions.json  > output.json

VERSION_CUMULATIVE=$(python -c "$PYTHON_JSON")

rm $COOKIEFILENAME


ssh2fabric "container-upgrade $VERSION_PRE_REQ root"
ssh2fabric "container-upgrade $VERSION_CUMULATIVE root"

set +x
echo "
----------------------------------------------------
Fuse Automated Patching
----------------------------------------------------
FABRIC ROOT: 
- ip:          $IP_ROOT
- ssh:         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT
- karaf:       ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_ROOT -p8101
- tail logs:   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT 'tail -F /opt/rh/jboss-fuse-*/data/log/fuse.log'

----------------------------------------------------
Use command:

container-list

in Karaf on Fabric Root, to verify the list of available containers.

Use command:

ensemble-list

in Karaf on Fabric Root, to verify the status of your Zookeeper Ensemble.

"