#!/bin/bash

################################################################################################
#####             Preconfiguration and helper functions. Skip if not interested.           #####
################################################################################################


# set debug mode
set -x

# configure logging to print line numbers
export PS4='+(${LINENO}): '

# ulimits values needed by the processes inside the container
ulimit -u 4096
ulimit -n 4096


# remove old docker containers with the same names

docker rm -f root ssh1 ssh2 ssh3

# expose ports to localhost, uncomment to enable always
# EXPOSE_PORTS="-P"
if [[ x$EXPOSE_PORTS == xtrue ]] ; then EXPOSE_PORTS=-P ; fi

# halt on errors
set -e

######################### YOU MIGHT WANT TO CHANGE THIS ######################
DOCKER_IMAGE="fuse:6.2"

# create your lab
docker run -d -t -i $EXPOSE_PORTS --name root $DOCKER_IMAGE
docker run -d -t -i $EXPOSE_PORTS --name ssh1 $DOCKER_IMAGE
docker run -d -t -i $EXPOSE_PORTS --name ssh2 $DOCKER_IMAGE
docker run -d -t -i $EXPOSE_PORTS --name ssh3 $DOCKER_IMAGE

# assign ip addresses to env variable, despite they should be constant on the same machine across sessions
alias docker_inspect="docker inspect --format '{{ .NetworkSettings.IPAddress }}' "
IP_ROOT=$( docker_inspect root )
IP_SSH1=$( docker_inspect ssh1 )
IP_SSH2=$( docker_inspect ssh2 )
IP_SSH3=$( docker_inspect ssh3 )

########### aliases to preconfigure ssh and scp verbose to type options

# full path of your ssh, used by the following helper aliases
SSH_PATH=$(which ssh) 
### ssh aliases to remove some of the visual clutter in the rest of the script
# alias to connect to your docker images
SSH_DEFAULT_OPTS="-o ConnectionAttempts=180 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o LogLevel=ERROR"
SSH_FAIL_FAST_OPTS="-o ConnectTimeout=4 -o ServerAliveCountMax=0 -o TCPKeepAlive=no"
alias ssh="$SSH_PATH $SSH_DEFAULT_OPTS"
alias ssh2host="$SSH_PATH $SSH_DEFAULT_OPTS -l fuse $IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2root="sshpass -p admin $SSH_PATH -p 8101 $SSH_DEFAULT_OPTS -l admin $IP_ROOT"
# alias to connect to the ssh server exposed by JBoss Fuse. uses sshpass to script the password authentication
alias ssh2ssh1="sshpass -p admin $SSH_PATH -p 8101 $SSH_DEFAULT_OPTS -l admin $IP_SSH1"
alias ssh2ssh2="sshpass -p admin $SSH_PATH -p 8101 $SSH_DEFAULT_OPTS -l admin $IP_SSH2"
alias ssh2ssh3="sshpass -p admin $SSH_PATH -p 8101 $SSH_DEFAULT_OPTS -l admin $IP_SSH3"


################################################################################################
#####                             Tutorial starts here                                     #####
################################################################################################

# start fuse on root node 
ssh2host "/opt/rh/jboss-fuse-*/bin/start debug"


############################# here you are starting to interact with Fuse/Karaf

# wait for critical components to be available before progressing with other steps
ssh2root "wait-for-service -t 300000 io.fabric8.api.BootstrapComplete"

set +e
# create a new fabric AND wait for the Fabric to be up and ready to accept the following commands
ssh2root "fabric:create --clean -r localip -g localip --wait-for-provisioning " 

# wait for container-create-ssh command to be available
# 
while ! ssh2root $SSH_FAIL_FAST_OPTS "wait-for-service -e -t 3000 '(&(objectClass=org.apache.felix.service.command.Function)(osgi.command.function=container-create-ssh))'"; do sleep 3s; done;

set -e

### workaround to avoid Maven Resolution to fail and start shipping the locally created zip
ssh2root 'profile-edit --pid io.fabric8.agent/org.ops4j.pax.url.mvn.repositories="file:\${runtime.home}/\${karaf.default.repository}@snapshots@id=karaf-default" default'

ssh2root "wait-for-provisioning"






# provision fabric nodes
ssh2root "container-create-ssh  --resolver localip --host $IP_SSH1 --user fuse  --path /opt/rh/fabric  --jvm-opts '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005' ssh1"

ssh2root "container-create-ssh --resolver localip --host $IP_SSH2 --user fuse  --path /opt/rh/fabric  --jvm-opts '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005' ssh2"

ssh2root "wait-for-provisioning"

ssh2root "ensemble-add --force --migration-timeout 300000 ssh1 ssh2"

set +e
# wait for container-list command to be available
while ! ssh2root $SSH_FAIL_FAST_OPTS "wait-for-service -e -t 3000 '(&(objectClass=org.apache.felix.service.command.Function)(osgi.command.function=container-create-ssh))'"; do sleep 3s; done;
set -e

ssh2root "container-create-ssh --resolver localip --host $IP_SSH3 --user fuse  --path /opt/rh/fabric  --jvm-opts '-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005' ssh3"



set +x
echo "

"