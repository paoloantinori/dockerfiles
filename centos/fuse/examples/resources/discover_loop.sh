# preconfigure cli input params
set -x
set -e

RHQ_CLI_HOME=/home/fuse/jon_cli/rhq-remoting-cli-4.9.0.JON320GA
RHQ_CLI_USERNAME=rhqadmin
RHQ_CLI_PASSWORD=rhqadmin
RHQ_SERVER_IP=127.0.0.1
RHQ_SERVER_PORT=7080

export RHQ_CLI_JAVA_HOME=/usr/lib/jvm/jre

SCRIPT=/home/fuse/discovery.js

for i in {1..30}
do
   output_cli=$( $RHQ_CLI_HOME/bin/rhq-cli.sh \
   -u $RHQ_CLI_USERNAME \
   -p $RHQ_CLI_PASSWORD \
   -s $RHQ_SERVER_IP \
   -t $RHQ_SERVER_PORT \
   -f $SCRIPT )

# string matching with globbing
if [[ $output_cli == *Imported.* ]] ; then
   echo "Found expected resources!"
   break; 
fi
sleep 5s
done
