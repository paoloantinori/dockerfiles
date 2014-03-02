#################################################################
# Creates a base CentOS 6 image with Fuse
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

#telnet is required by some fabric command. without it you have silent failures
RUN yum install -y java-1.7.0-openjdk which telnet unzip openssh-server sudo

ENV JAVA_HOME /usr/lib/jvm/jre

#add a user for the application
RUN useradd -m fuse ; echo fuse:fuse | chpasswd

RUN mkdir -m 777 -p /opt/rh

RUN echo "alias ll='ls -l --color=auto" >> /etc/bashrc
RUN echo "alias grep='grep --color=auto" >> /etc/bashrc

ONBUILD ADD jboss-fuse-full-6.0.0.redhat-024.zip /root/
ONBUILD RUN unzip -q -d /opt/rh /root/jboss-fuse-full-6.0.0.redhat-024.zip
ONBUILD RUN chown -R fuse:fuse /opt/rh
ONBUILD RUN rm /root/jboss-fuse-full-6.0.0.redhat-024.zip

ONBUILD RUN sed -i "s/#admin/admin/" /opt/rh/jboss-fuse-6.0.0.redhat-024/etc/users.properties

WORKDIR /opt/rh

CMD echo "This is just a abstract image. You need to build your own JBoss Fuse image. See here: "