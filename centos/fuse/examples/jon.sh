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

# remove old docker containers with the same names
docker stop -t 0 postgresql  
docker stop -t 0 jon_server 
docker stop -t 0 fuse_instance 
docker rm postgresql 
docker rm jon_server 
docker rm fuse_instance 

# expose ports to localhost, uncomment to enable always
# EXPOSE_PORTS="-P"
if [[ x$EXPOSE_PORTS == xtrue ]] ; then EXPOSE_PORTS=-P ; fi

# halt on errors
set -e

# create your lab
docker run --privileged -t -i -d --name="postgresql" \
             -p 127.0.0.1:5432:5432 \
             -e USER="rhqadmin" \
             -e DB="rhq" \
             -e PASS="rhqadmin" \
             paintedfox/postgresql &
sleep 10s

docker run --privileged -d -t -i $EXPOSE_PORTS --link postgresql:db --name jon_server jon
docker run --privileged -d -t -i $EXPOSE_PORTS --name fuse_instance fuse6.1


# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_POSTGRES=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' postgresql)
IP_JON_SERVER=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' jon_server)
IP_FUSE=$(docker inspect --format '{{ .NetworkSettings.IPAddress }}' fuse_instance)



########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
alias ssh="$SSH_PATH -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR -o TCPKeepAlive=no -o ServerAliveInterval=45"
alias scp="scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR "
alias ssh2fuse="$SSH_PATH -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=180 -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR -o TCPKeepAlive=no -o ServerAliveInterval=45 fuse@$IP_FUSE"

alias ssh2jonserver="$SSH_PATH -o UserKnownHostsFile=/dev/null -o ConnectionAttempts=180 -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR -o TCPKeepAlive=no -o ServerAliveInterval=45 fuse@$IP_JON_SERVER"


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

# start fuse on root node 
ssh2fuse "/opt/rh/jboss-fuse-*/bin/start"

# careful. we may risk to loop forever here
ssh2fuse "while ! wget --tries=30 --retry-connrefused --wait=10 --user=rhqadmin --password=rhqadmin http://$IP_JON_SERVER:7080/agentupdate/download -O agent.jar ; do sleep 5s; done;"

# extract jon agent
ssh2fuse "java -jar agent.jar --install"

# copy sample configuration
ssh2fuse "cp -a rhq-agent/conf/agent-configuration.xml ~/jon_preconfigured.xml"

#uncomment xml node. see: http://stackoverflow.com/questions/17996497/sed-uncomment-specfic-xml-comments-out-of-a-file/18002150#18002150
ssh2fuse 'sed -i "/^\s*<!--/!b;N;/<entry key=\"rhq.agent.name\"/s/.*\n//;T;:a;n;/^\s*-->/!ba;d" ~/jon_preconfigured.xml'
ssh2fuse 'sed -i "/^\s*<!--/!b;N;/<entry key=\"rhq.agent.server.bind-address\"/s/.*\n//;T;:a;n;/^\s*-->/!ba;d" ~/jon_preconfigured.xml'

### assign values to attributues
# server address
ssh2fuse "sed -i \"s#rhq\.agent\.server\.bind-address.*#rhq\.agent\.server\.bind-address\\\" value=\\\"$IP_JON_SERVER\\\" />#\"  ~/jon_preconfigured.xml"
# server agent identifier
ssh2fuse "sed -i \"s#rhq\.agent\.name.*#rhq\.agent\.name\\\" value=\\\"fuse\\\" />#\"  ~/jon_preconfigured.xml"
# automated installation flag
ssh2fuse "sed -i \"s#rhq\.agent\.configuration-setup-flag.*#rhq\.agent\.configuration-setup-flag\\\" value=\\\"true\\\" />#\"  ~/jon_preconfigured.xml"

 
# start agent. it's important to keep the redirections. see: http://stackoverflow.com/questions/29142/getting-ssh-to-execute-a-command-in-the-background-on-target-machine
ssh2fuse "nohup ~/rhq-agent/bin/rhq-agent.sh -d --config=/home/fuse/jon_preconfigured.xml > /dev/null 2>&1 &"

#### trigger discovery on jon server

# download JON CLI

ssh2jonserver "while ! wget http://127.0.0.1:7080/client/download -O jon_cli.zip; do sleep 10s; done;"

# remove old cli
ssh2jonserver  "rm -rf jon_cli"
# extract new one
ssh2jonserver  "unzip jon_cli.zip -d jon_cli"

# wait until the server side component of the CLI is ready to listen
ssh2jonserver "while ! wget http://127.0.0.1:7080/jboss-remoting-servlet-invoker/ServerInvokerServlet -O /dev/null; do sleep 10s; done;"


scp resources/discovery.js fuse@$IP_JON_SERVER:
scp resources/discover_loop.sh fuse@$IP_JON_SERVER:
# invoke the discovery script for a while, until the agent finds and reports something
ssh2jonserver "sh discover_loop.sh"

set +x
echo "
----------------------------------------------------
Fuse JON
----------------------------------------------------
Postgres: 
- ip:          $IP_POSTGRES

JON SERVER: 
- ip:          $IP_JON_SERVER
- ssh:         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_JON_SERVER
- tail logs:   docker logs -f jon_server
- JON Console: http://$IP_JON_SERVER:7080/ #user and pass: rhqadmin

Fuse: 
- ip:          $IP_FUSE
- ssh:         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_FUSE
- karaf:       ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_FUSE -p8101
- tail logs:   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_FUSE 'tail -F /opt/rh/jboss-fuse-*/data/log/fuse.log'

NOTE: If you are using Docker in a VM you may need extra config to route the traffic to the containers. One way to bypass this can be setting the environment variable EXPOSE_PORTS=true before running this script and than to use 'docker ps' to discover the exposed ports on your localhost.
----------------------------------------------------

"