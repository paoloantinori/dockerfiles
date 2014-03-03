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

RUN mkdir -m 777 -p /opt/rh

RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/bashrc
RUN echo "alias ll='ls -l --color=auto'" >> /etc/bashrc
RUN echo "alias grep='grep --color=auto'" >> /etc/bashrc


ONBUILD ADD . /root/
ONBUILD RUN unzip -q -d /opt/rh /root/*.zip
ONBUILD RUN chown -R fuse:fuse /opt/rh
ONBUILD RUN rm /root/*

ONBUILD RUN sed -i "s/#admin/admin/" /opt/rh/jboss-fuse-*/etc/users.properties

WORKDIR /opt/rh

CMD echo "This is just a abstract image. You need to build your own JBoss Fuse image. See here: https://github.com/paoloantinori/dockerfiles/edit/master/centos/fuse/README.md"