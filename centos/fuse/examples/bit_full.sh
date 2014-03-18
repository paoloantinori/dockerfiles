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

# scary but it's just for better logging if you run with "sh -x"
export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# ulimits values needed by the processes inside the container
ulimit -u 4096
ulimit -n 4096

########## docker lab configuration

# remove old docker containers with the same names
docker stop root  
docker stop esb01 
docker stop esb02
docker stop fab03 
docker stop fab02
docker rm root 
docker rm esb01 
docker rm esb02 
docker rm fab03 
docker rm fab02 

# create your lab
docker run -d -t -i --name root fuse
docker run -d -t -i --name esb01 fuse
docker run -d -t -i --name esb02 fuse
docker run -d -t -i --name fab03 fuse
docker run -d -t -i --name fab02 fuse

# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' root)
IP_FAB03=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' fab03)
IP_FAB02=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' fab02)
IP_ESB01=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' esb01)
IP_ESB02=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' esb02)


########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh2host="$SSH_PATH -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR fuse@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2fabric="sshpass -p admin $SSH_PATH -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2esb01="sshpass -p admin $SSH_PATH -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ESB01"
# alias for scp to inline flags to disable ssh warnings
alias scp="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"


# halt on errors
set -e


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

# start fuse on root node
ssh2host "/opt/rh/jboss-fuse-6.0.0.redhat-024/bin/start" 

sleep 30

### deplooy code and properties

# upload release
scp ./esb-deployer-2.1.20.zip fuse@$IP_ROOT:/opt/rh/

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

############################# here you are starting to interact with Fuse/Karaf
# If you want to type the commands manually you have to connect to Karaf. You can do it either with ssh or with the "client" command.
# Ex. 
# ssh2fabric 

# create a new fabric
ssh2fabric "fabric:create --clean -r localip -g localip" 

sleep 30

# show current containers
ssh2fabric "container-list"

sleep 90

# create base tru2 profile
ssh2fabric "fabric:profile-create --parents camel --version 1.0 tru2-profile"

# configure local maven
ssh2fabric 'fabric:profile-edit --pid org.fusesource.fabric.agent/org.ops4j.pax.url.mvn.repositories="file:///opt/rh/features-repo@snapshots@name=tru@id=tru" default'
# important! to disable maven snapshot checksum that otherwise will block the functionality
ssh2fabric "fabric:profile-edit --pid org.fusesource.fabric.maven/checksumPolicy=warn  default "

# import customised real time broker configuration
ssh2fabric  "import -v -t /fabric/configs/versions/1.0/profiles/mq-base/tru-broker.xml tru/tru-broker.xml"

# provision fabric nodes
ssh2fabric "container-create-ssh --resolver localip --host $IP_FAB02 --user fuse  --path /opt/rh/fabric fab02"
ssh2fabric "container-create-ssh --resolver localip --host $IP_FAB03 --user fuse  --path /opt/rh/fabric fab03"

ssh2fabric "ensemble-add -f fab02 fab03"

sleep 5

# workers
ssh2fabric "container-create-ssh --jvm-opts \"-XX:+UseConcMarkSweepGC -XX:MaxPermSize=512m -Xms512m -Xmx1024m\" --resolver localip --host $IP_ESB01 --user fuse --path /opt/rh/fabric esb01"
ssh2fabric "container-create-ssh --jvm-opts \"-XX:+UseConcMarkSweepGC -XX:MaxPermSize=512m -Xms512m -Xmx1024m\" --resolver localip --host $IP_ESB02 --user fuse --path /opt/rh/fabric esb02"
# brokers
ssh2fabric "container-create-ssh --jvm-opts \"-XX:+UseConcMarkSweepGC -XX:MaxPermSize=512m -Xms512m -Xmx1024m\" --resolver localip --host $IP_ESB01 --user fuse --path /opt/rh/fabric brok01"
ssh2fabric "container-create-ssh --jvm-opts \"-XX:+UseConcMarkSweepGC -XX:MaxPermSize=512m -Xms512m -Xmx1024m\" --resolver localip --host $IP_ESB02 --user fuse --path /opt/rh/fabric brok02"

# show current containers
ssh2fabric "container-list"


# create broker profile and add location of shared message store
ssh2fabric "fabric:mq-create --assign-container brok01,brok02 --config tru-broker.xml tru-mq-profile"
# previous command reports an error that can be ignored
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/data=/opt/rh/fuse tru-mq-profile" 
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/openwire-port=61616 tru-mq-profile"
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/broker-name=tru tru-mq-profile"
ssh2fabric "fabric:profile-edit --pid org.fusesource.mq.fabric.server-tru-mq-profile/group=truphone-broker tru-mq-profile"

# invoke our karaf scripts
ssh2fabric "shell:source /opt/rh/features-repo/com/truphone/esb/features/2.1.20/esb-profile-tru2.karaf"

# apply the profile to esb01
ssh2fabric "container-add-profile esb01 tru2-profile"
# apply the profile to esb02
ssh2fabric "container-add-profile esb02 tru2-profile"

# install fmc
ssh2fabric "container-add-profile root fmc"

sleep 15

# list content of esb01
ssh2esb01 "list | grep ESB"

sleep 5

# apply patches
firefox "http://$IP_ROOT:8181/"




# sshi fuse@172.17.0.2 "tail -F /opt/rh/jboss-fuse-6.0.0.redhat-024/data/log/fuse.log" | h -i error zip warn
# [ 128] [Active     ] [Created     ] [       ] [   60] JBoss A-MQ Fabric (6.0.0.redhat-024)
