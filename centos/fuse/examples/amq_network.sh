#!/bin/bash

##########################################################################################################
# Description:
# This example will guide you to provision a Fabric node + 2 ActiveMQ managed nodes
# configured in Active/Passive mode with shared data. With this setup you will be able to send
# messages to the node that is active, try to stop or to kill that node, and to see that the
# other node will get promoted to active and that it will be able to see all the messages and destinations
# created by the other node.
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

########## docker lab configuration


# remove old docker containers with the same names
docker stop root  
docker stop brok01 
docker stop brok02 
docker rm root 
docker rm brok01 
docker rm brok02 


# create your lab
docker run -d -t -i --name root fuse
docker run -d -t -i --name brok01 fuse
docker run -d -t -i --name brok02 fuse

# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
IP_ROOT=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' root)
IP_BROK01=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' brok01)
IP_BROK02=$(docker inspect -format '{{ .NetworkSettings.IPAddress }}' brok02)

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
alias ssh2brok01_1="sshpass -p admin $SSH_PATH -p 8101 -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_BROK01"
alias ssh2brok02_1="sshpass -p admin $SSH_PATH -p 8101 -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR admin@$IP_BROK02"
# alias for scp to inline flags to disable ssh warnings
alias scp="scp -o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"


# halt on errors
set -e


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################


# start fuse on root node (yes, that initial backslash is required to not use the declared alias)
ssh2host "/opt/rh/jboss-fuse-*/bin/start"


############################# here you are starting to interact with Fuse/Karaf

# wait for critical components to be available before progressing with other steps
ssh2fabric "wait-for-service -t 300000 org.linkedin.zookeeper.client.LifecycleListener"
ssh2fabric "wait-for-service -t 300000 org.fusesource.fabric.maven.MavenProxy"


# create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
ssh2fabric "fabric:create --clean -r localip -g localip ; wait-for-service -t 300000 org.jolokia.osgi.servlet.JolokiaContext" 

# stop default broker created automatically with fabric
ssh2fabric "stop org.jboss.amq.mq-fabric" 



# create broker profile and add location of shared message store
ssh2fabric "fabric:mq-create --group network-brokers1 --networks network-brokers2 --networks-password admin --networks-username admin MasterSlaveBroker1"
ssh2fabric "fabric:mq-create --group network-brokers2 --networks network-brokers1 --networks-password admin --networks-username admin MasterSlaveBroker2"

ssh2fabric "container-create-ssh --resolver localip --host $IP_BROK01 --user fuse  --path /opt/rh/fabric --profile MasterSlaveBroker1 broker1_ 2"
ssh2fabric "container-create-ssh --resolver localip --host $IP_BROK02 --user fuse  --path /opt/rh/fabric --profile MasterSlaveBroker2 broker2_ 2"


ssh2brok01_1 "wait-for-service -t 300000 org.apache.geronimo.transaction.manager.RecoverableTransactionManager"
ssh2brok02_1 "wait-for-service -t 300000 org.apache.geronimo.transaction.manager.RecoverableTransactionManager"


# remove hawtio and install newer version
ssh2fabric "fabric:profile-edit --pid org.ops4j.pax.web/org.osgi.service.http.port=8013 MasterSlaveBroker1"
ssh2fabric "fabric:profile-edit --delete -r mvn:io.hawt/hawtio-karaf/1.0/xml/features MasterSlaveBroker1"
ssh2fabric "fabric:profile-edit -r mvn:io.hawt/hawtio-karaf/1.2.2/xml/features MasterSlaveBroker1"
ssh2fabric "fabric:profile-edit --features hawtio-core MasterSlaveBroker1"

ssh2fabric "fabric:profile-edit --pid org.ops4j.pax.web/org.osgi.service.http.port=8013 MasterSlaveBroker2"
ssh2fabric "fabric:profile-edit --delete -r mvn:io.hawt/hawtio-karaf/1.0/xml/features MasterSlaveBroker2"
ssh2fabric "fabric:profile-edit -r mvn:io.hawt/hawtio-karaf/1.2.2/xml/features MasterSlaveBroker2"
ssh2fabric "fabric:profile-edit --features hawtio-core MasterSlaveBroker2"



# provision container nodes
#ssh2fabric "container-create-ssh --resolver localip --host $IP_BROK01 --user fuse  --path /opt/rh/fabric --profile my_broker_profile brok01"
#ssh2fabric "container-create-ssh --resolver localip --host $IP_BROK02 --user fuse  --path /opt/rh/fabric --profile my_broker_profile brok02"

# show current containers
ssh2fabric "cluster-list"

set +x
echo "
----------------------------------------------------
Broker network with two interconnected Master/Slave pairs
----------------------------------------------------
FABRIC ROOT: 
- ip:          $IP_ROOT
- ssh:         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT
- karaf:       ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_ROOT -p8101
- tail logs:   ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_ROOT 'tail -F /opt/rh/jboss-fuse-*/data/log/fuse.log'

BROKER 1: 
- ip:         $IP_BROK01
- ssh:        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_BROK01
- karaf node1 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_BROK01 -p8101
- karaf node2 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_BROK01 -p8102
- hawtio:     http://$IP_BROK01:8013/hawtio 
              user/pass: admin/admin
- tail logs:  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP_BROK01 -l fuse 'tail -F /opt/rh/fabric/broker1_1/fuse-fabric-*/data/log/karaf.log'
- tail logs:  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP_BROK01 -l fuse 'tail -F /opt/rh/fabric/broker1_2/fuse-fabric-*/data/log/karaf.log'

BROKER 2: 
- ip:         $IP_BROK02
- ssh:        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null fuse@$IP_BROK02
- karaf node1 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_BROK02 -p8101
- karaf node2 ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null admin@$IP_BROK02 -p8102
- hawtio:     http://$IP_BROK02:8013/hawtio
              user/pass: admin/admin
- tail logs:  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP_BROK02 -l fuse 'tail -F /opt/rh/fabric/broker2_1/fuse-fabric-*/data/log/karaf.log'
- tail logs:  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $IP_BROK02 -l fuse 'tail -F /opt/rh/fabric/broker2_2/fuse-fabric-*/data/log/karaf.log'

----------------------------------------------------
Use command:

cluster-list

in Karaf on Fabric Root, to see the status of your ActiveMQ Cluster.

See: http://tmielke.blogspot.co.uk/2013/08/creating-activemq-broker-cluster.html

"

