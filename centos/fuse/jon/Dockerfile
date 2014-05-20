#################################################################
# Creates a base CentOS 6 image with JON
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

# telnet is required by some fabric command. without it you have silent failures
RUN yum install -y java-1.7.0-openjdk which telnet unzip openssh-server sudo openssh-clients
# enable no pass and speed up authentication
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/;s/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

# enabling sudo group
RUN echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers
# enabling sudo over ssh
RUN sed -i 's/.*requiretty$/#Defaults requiretty/' /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/jre

# add a user for the application, with sudo permissions
RUN useradd -m fuse ; echo fuse: | chpasswd ; usermod -a -G wheel fuse

# assigning higher default ulimits
# unluckily this is not very portable. these values work only if the user running docker daemon on the host has his own limits >= than values set here
# if they are not, the risk is that the "su fuse" operation will fail
RUN echo "fuse                -       nproc           4096" >> /etc/security/limits.conf
RUN echo "fuse                -       nofile           4096" >> /etc/security/limits.conf

# give total control to the main working folder
RUN mkdir -m 777 -p /opt/rh

# command line goodies
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/profile
RUN echo "export LANG=en_GB.utf8" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile


WORKDIR /opt/rh

# 7080 	Standard HTTP port for server-client communication
# 7443 	HTTPS port for secure server-client communication
# 16163 	For agent communication from the server
# 9142 	For storage cluster communication
# 7299 	For storage node JMX communication
# 7100 # 

RUN yum install -y ntp



ADD jon-server-3.2.0.GA.zip /opt/rh/
ADD jon-plugin-pack-fuse-3.2.0.GA.zip /opt/rh/

RUN unzip jon-server-3.2.0.GA.zip -d /opt/rh/
RUN unzip -j -o jon-plugin-pack-fuse-3.2.0.GA.zip -d /opt/rh/jon-server-3.2.0.GA/plugins

RUN yum install -y postgresql

ADD start.sh /opt/rh/
RUN chmod +x /opt/rh/start.sh



CMD /opt/rh/start.sh
EXPOSE 22 8080 7080 7443 16163 9142 7299 7100

