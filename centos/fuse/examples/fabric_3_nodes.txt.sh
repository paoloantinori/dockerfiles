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
# Prerequesites:
# - run docker in case it's not already
# sudo service docker start
#
# Notes:
# - if you run the command typing them yourself in a shell, you probably won't need all the ssh aliases 
#   or the various "sleep" invocations
# - as you may see this script is based on sleep commands, that maybe too 
#######################################################################################################

# ulimits values needed by the processes inside the container
ulimit -u 4096
ulimit -n 4096

# helper ssh macro for password less authentication + ssh optimization "-p admin" is the password that it types for you
alias ssh="sshpass -p admin ssh -p 8101 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"

# remove old docker containers with the same names
docker stop root  
docker stop fab02 
docker stop fab03 
docker rm root 
docker rm fab02 
docker rm fab03 

# create your lab
docker run -d -t -i --name root fuse
docker run -d -t -i --name fab02 fuse
docker run -d -t -i --name fab03 fuse

# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' root)
IP_FAB02=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' fab02)
IP_FAB03=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' fab03)




# start fuse on root node (yes, that initial backslash is required to not use the declared alias)
\ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR \
    fuse@$IP_ROOT /opt/rh/jboss-fuse-6.0.0.redhat-024/bin/start 

sleep 20


############################# here you are starting to interact with Fuse/Karaf
# If you want to type the commands manually you have to connect to Karaf. You can do it either with ssh or with the "client" command.
# Ex. 
# ssh admin@$IP_ROOT 

# create a new fabric
ssh admin@$IP_ROOT "fabric:create --clean -r localip -g localip" 

sleep 30

# show current containers
ssh admin@$IP_ROOT "container-list"

sleep 90

# provision fabric nodes
ssh admin@$IP_ROOT "container-create-ssh --resolver localip --host $IP_FAB02 --user fuse  --path /opt/rh/fabric fab02"
ssh admin@$IP_ROOT "container-create-ssh --resolver localip --host $IP_FAB03 --user fuse  --path /opt/rh/fabric fab03"

# show current containers
ssh admin@$IP_ROOT "container-list"

# show current ensemble
ssh admin@$IP_ROOT "ensemble-list"

# give fab03 some time to properly start up before trying to use it
sleep 60

# wait for them to be provisioned. check with container-list
# join the node to the ensemble (-f to bypass the confirmation)
ssh admin@$IP_ROOT "ensemble-add -f fab02 fab03"

sleep 5

# show current ensemble
ssh admin@$IP_ROOT "ensemble-list"

