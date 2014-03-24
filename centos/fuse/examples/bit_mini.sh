#!/bin/bash

##########################################################################################################
# Description:
# This example will guide you through a simple Red Hat JBoss Fuse setup.
# We are going to start 3 docker container that will represent the nodes of your network.
# On the noode called "root" we will be manually starting the instance of JBoss FUse.
# Then we will be start using Fabric to provision other JBoss Fuse instances on the remaining 2 nodes.
#
# Dependencies:
# - docker 
# - sshpass, used to avoid typing the pass everytime (not needed if you are invoking the commands manually)
# to install on Fedora/Centos/Rhel: 
# sudo yum install -y docker-io sshpass
#
# Prerequesites:
# - run docker in case it's not already
# sudo service docker start
#
# Notes:
# - if you run the commands, typing them yourself in a shell, you probably won't need all the ssh aliases 
#   or the various "sleep" invocations
# - as you may see this script is based on sleep commands, that maybe too short if your hardware is much slower than mine.
#   increase those sleep time if you have to
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

########## docker lab configuration

# remove old docker containers with the same names
docker stop -t 0 root  
docker stop -t 0 esb01 
docker stop -t 0 brok01 
docker rm root 
docker rm esb01 
docker rm brok01 

# expose ports to localhost, uncomment to enable always
# EXPOSE_PORTS="-P"
if [[ x$EXPOSE_PORTS == xtrue ]] ; then EXPOSE_PORTS=-P ; fi

# halt on errors
set -e

# create your lab
docker run -d -t -i $EXPOSE_PORTS --name root fuse
docker run -d -t -i $EXPOSE_PORTS --name esb01 fuse
docker run -d -t -i $EXPOSE_PORTS --name brok01 fuse

# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' root)
IP_ESB01=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' esb01)
IP_BROK01=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' brok01)


########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh2host="$SSH_PATH -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR fuse@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2fabric="sshpass -p admin $SSH_PATH -o ConnectionAttempts=180 -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2esb01="sshpass -p admin $SSH_PATH -o ConnectionAttempts=180 -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ESB01"
alias ssh2brok01="sshpass -p admin $SSH_PATH -o ConnectionAttempts=180 -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_BROK01"
# alias for scp to inline flags to disable ssh warnings
alias scp="scp -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################


### deploy code and properties

# upload release
scp ./esb-deployer-*.zip fuse@$IP_ROOT:/opt/rh/
VERSION=$(ls -1 esb-deployer-* |  cut -d '-' -f 3- | sed 's/\.zip//' )

# extract the release
ssh2host "unzip -u -o /opt/rh/*.zip -d /opt/rh"

# copy properties in place
ssh2host "cp -a /opt/rh/tru  /opt/rh/jboss-fuse-*"

# upload properties zip
scp ./properties.zip fuse@$IP_ROOT:/opt/rh/

# extract properties
ssh2host "unzip -u -o /opt/rh/properties.zip -d /opt/rh/jboss-fuse-*/tru/"

# remove properties zip
ssh2host "rm -f /opt/rh/properties.zip "


# start fuse on root node
ssh2host "/opt/rh/jboss-fuse-*/bin/start" 

# wait for critical components to be available before progressing with other steps
ssh2fabric "wait-for-service -t 300000 org.linkedin.zookeeper.client.LifecycleListener"
ssh2fabric "wait-for-service -t 300000 org.fusesource.fabric.maven.MavenProxy"


############################# here you are starting to interact with Fuse/Karaf
# If you want to type the commands manually you have to connect to Karaf. You can do it either with ssh or with the "client" command.
# Ex. 
# ssh2fabric 

# create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
ssh2fabric "fabric:create --clean -r localip -g localip ; wait-for-service -t 300000 org.jolokia.osgi.servlet.JolokiaContext" 

# show current containers
ssh2fabric "container-list"

# create base tru2 profile
ssh2fabric "fabric:profile-create --parents camel --version 1.0 tru2-profile"

# configure local maven
ssh2fabric 'fabric:profile-edit --pid org.fusesource.fabric.agent/org.ops4j.pax.url.mvn.repositories="file:///opt/rh/features-repo@snapshots@name=tru@id=tru" default'
# important! to disable maven snapshot checksum that otherwise will block the functionality
ssh2fabric "fabric:profile-edit --pid org.fusesource.fabric.maven/checksumPolicy=warn  default "

# import customised real time broker configuration
ssh2fabric  "import -v -t /fabric/configs/versions/1.0/profiles/mq-base/tru-broker.xml tru/tru-broker.xml"

# stop default broker created automatically with fabric
ssh2fabric "stop org.jboss.amq.mq-fabric" 

# provision fabric nodes
ssh2fabric "container-create-ssh --jvm-opts \"-XX:+UseConcMarkSweepGC -XX:MaxPermSize=512m -Xms512m -Xmx1024m\" --resolver localip --host $IP_ESB01 --user fuse  --path /opt/rh/fabric esb01"
ssh2fabric "container-create-ssh --jvm-opts \"-XX:+UseConcMarkSweepGC -XX:MaxPermSize=512m -Xms512m -Xmx1024m\" --resolver localip --host $IP_BROK01 --user fuse  --path /opt/rh/fabric brok01"

# wait for containers to be ready
ssh2esb01  "wait-for-service -t 300000 org.apache.karaf.features.FeaturesService"
ssh2brok01 "wait-for-service -t 300000 org.apache.karaf.features.FeaturesService"

# show current containers
ssh2fabric "container-list"

# create broker profile and add location of shared message store
ssh2fabric "fabric:mq-create --assign-container brok01 --config tru-broker.xml tru-mq-profile"
# previous command reports an error that can be ignored
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/data=/opt/rh/fuse tru-mq-profile" 
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/openwire-port=61616 tru-mq-profile"
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/broker-name=tru tru-mq-profile"
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/group=truphone-broker tru-mq-profile"

# invoke our karaf scripts (double since snapshot and not snapshots create 2 different naming convention files. just one will work)
ssh2fabric "shell:source /opt/rh/features-repo/com/truphone/esb/features/$VERSION/esb-profile-tru2.karaf"
ssh2fabric "shell:source /opt/rh/features-repo/com/truphone/esb/features/$VERSION/features-$VERSION-profile-tru2.karaf"


# apply the profile to esb01
ssh2fabric "container-add-profile esb01 tru2-profile"

# install fmc
ssh2fabric "container-add-profile root fmc"

sleep 15

# list content of esb01
ssh2esb01 "list | grep ESB"

set +x
echo "
----------------------------------------------------
BIT Mini Lab
----------------------------------------------------
FABRIC ROOT: 
- ip:          $IP_ROOT
- ssh:         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT
- karaf:       ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_ROOT -p8101
- tail logs:   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT 'tail -F /opt/rh/jboss-fuse-*/data/log/fuse.log'

ESB 01: 
- ip:         $IP_ESB01
- ssh:        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ESB01
- tail logs:  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP_ESB01 -l fuse 'tail -F /opt/rh/fabric/esb01/fuse-fabric-*/data/log/karaf.log'

BROKER 01:  
- ip:         $IP_BROK01
- ssh:        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_BROK01
- karaf:      ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_BROK01 -p8101
- tail logs:  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP_BROK01 -l fuse 'tail -F /opt/rh/fabric/brok01/fuse-fabric-*/data/log/karaf.log'

NOTE: If you are using Docker in a VM you may need extra config to route the traffic to the containers. One way to bypass this can be setting the environment variable EXPOSE_PORTS=true before running this script and than to use 'docker ps' to discover the exposed ports on your localhost.
----------------------------------------------------
Use command:
	
firefox http://$IP_ROOT:8181/

From command line to access FMC console if you want to apply patches

"
