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
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/jre

#add a user for the application, with sudo permissions
RUN useradd -m fuse ; echo fuse:fuse | chpasswd ; usermod -a -G wheel fuse

#assigning higher default ulimits
#unluckily this is not very portable. this values work only in the user running docker damon on the host as his own limits >= to these values
#the risk is that the "su fuse" operation will fail otherwise
RUN echo "fuse                -       nproc           4096" >> /etc/security/limits.conf
RUN echo "fuse                -       nofile           4096" >> /etc/security/limits.conf

RUN mkdir -m 777 -p /opt/rh

RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile

ONBUILD ADD . /root/
ONBUILD RUN unzip -q -d /opt/rh /root/*.zip
ONBUILD RUN chown -R fuse:fuse /opt/rh
ONBUILD RUN rm /root/*

ONBUILD RUN sed -i "s/#admin/admin/" /opt/rh/jboss-fuse-*/etc/users.properties

WORKDIR /opt/rh

CMD echo "This is just a abstract image. You need to build your own JBoss Fuse image. See here: https://github.com/paoloantinori/dockerfiles/edit/master/centos/fuse/README.md"