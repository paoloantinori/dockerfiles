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
docker stop -t 0 root  
docker rm root 

# expose ports to localhost, uncomment to enable always
# EXPOSE_PORTS="-P"
if [[ x$EXPOSE_PORTS == xtrue ]] ; then EXPOSE_PORTS=-P ; fi

# halt on errors
set -e

# create your lab
docker run -d -t -i $EXPOSE_PORTS --name root fuse:6.0

# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' root)

########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh="$SSH_PATH -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"
alias ssh2host="$SSH_PATH -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=180 -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR fuse@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2fabric="sshpass -p admin $SSH_PATH -p 8101 -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias scp="scp -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"



################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

# start fuse on root node 
ssh2host "/opt/rh/jboss-fuse-*/bin/start"

# wait for critical components to be available before progressing with other steps
ssh2fabric "wait-for-service -t 300000 org.linkedin.zookeeper.client.LifecycleListener"
ssh2fabric "wait-for-service -t 300000 org.fusesource.fabric.maven.MavenProxy"

# create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
ssh2fabric "fabric:create --clean -r localip -g localip ; wait-for-service -t 300000 org.jolokia.osgi.servlet.JolokiaContext" 

# install wrapper feauter in default profile
ssh2fabric "fabric:profile-edit --features wrapper fabric"

# wait fot the wrapper feature to be deployed
ssh2fabric 'dev:wait-for-service -t 30000  "(&(objectClass=org.osgi.service.blueprint.container.BlueprintContainer)(osgi.blueprint.container.symbolicname=org.apache.karaf.shell.wrapper))"'

# generate service script
ssh2fabric 'wrapper:install -n fuse -d "JBoss Fuse" -D "JBoss Fuse Extended Description"'

# stop instance manually started
ssh2host "/opt/rh/jboss-fuse-*/bin/stop"

# install wrapper script as a linux daemon
ssh2host "sudo ln -s /opt/rh/jboss-fuse-6.0.0.redhat-024/bin/fuse-service /etc/init.d/"

# enable daemon at start
ssh2host "sudo chkconfig fuse-service --add"

# start fabric as a daemon
ssh2host "sudo service fuse-service start"


# 

set +x
echo "
----------------------------------------------------
Fuse Fabric service demo
----------------------------------------------------
FABRIC ROOT: 
- ip:          $IP_ROOT
- ssh:         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT
- karaf:       ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_ROOT -p8101
- tail logs:   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT 'tail -F /opt/rh/jboss-fuse-*/data/log/fuse.log'


NOTE: If you are using Docker in a VM you may need extra config to route the traffic to the containers. One way to bypass this can be setting the environment variable EXPOSE_PORTS=true before running this script and than to use 'docker ps' to discover the exposed ports on your localhost.
----------------------------------------------------

"
