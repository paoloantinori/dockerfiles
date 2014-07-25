#!/bin/bash
service sshd start 
service ntpd start 

VERSION=3.2.0.GA

if [[ "x$DB_PORT_5432_TCP_ADDR" != x ]] ; then
	sed -i "s/jboss.bind.address=$/jboss.bind.address=0.0.0.0/"  /opt/rh/jon-server-$VERSION/bin/rhq-server.properties
	sed -i "s#rhq.server.database.connection-url=jdbc:postgresql://127.0.0.1#rhq.server.database.connection-url=jdbc:postgresql://$DB_PORT_5432_TCP_ADDR#" /opt/rh/jon-server-$VERSION/bin/rhq-server.properties
	sed -i "s;^#\?rhq\.server\.database\.server\-name=.*$;rhq.server.database.server-name=$DB_PORT_5432_TCP_ADDR;g" /opt/rh/jon-server-$VERSION/bin/rhq-server.properties
fi

cd /opt/rh/jon-server-$VERSION/bin
mkdir -p /opt/rh/jon-server-$VERSION/logs
touch /opt/rh/jon-server-$VERSION/logs/server.log

./rhqctl install --server --storage --start


tail -F /opt/rh/jon-server-$VERSION/logs/server.log
