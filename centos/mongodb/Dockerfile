#################################################################
# Creates a base CentOS 6 image with MongoDB
#
#                    ##        .
#              ## ## ##       ==
#           ## ## ## ##      ===
#       /""""""""""""""""\___/ ===
#  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
#       \______ o          __/
#         \    \        __/
#          \____\______/
#
# Author:    Paolo Antinori <paolo.antinori@gmail.com>
# License:   MIT
#################################################################

FROM centos

MAINTAINER Paolo Antinori <paolo.antinori@gmail.com>

RUN echo -e "[mongodb] \n \
name=MongoDB Repository \n \
baseurl=http://downloads-distro.mongodb.org/repo/redhat/os/x86_64/ \n \
gpgcheck=0 \n \
enabled=1" >> /etc/yum.repos.d/mongo.repo

RUN yum install -y mongo-10gen mongo-10gen-server

RUN mkdir -p /data/db
VOLUME ["/data/db"]

CMD ["/usr/bin/mongod"]

