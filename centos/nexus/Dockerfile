#################################################################
# Creates a base CentOS 6 image with Nexus
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


# command line goodies
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/profile
RUN echo "export LANG=en_GB.utf8" >> /etc/profile
RUN echo "alias ll='ls -l --color=auto'" >> /etc/profile
RUN echo "alias grep='grep --color=auto'" >> /etc/profile


# telnet is required by some fabric command. without it you have silent failures
RUN yum install -y java-1.7.0-openjdk which unzip openssh-server sudo openssh-clients tar
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

RUN mkdir /opt/nexus
ADD http://www.sonatype.org/downloads/nexus-latest-bundle.tar.gz /tmp/nexus-latest-bundle.tar.gz
RUN tar -xzvf /tmp/nexus-latest-bundle.tar.gz -C /opt/nexus
RUN rm -rf /tmp/nexus-latest-bundle.tar.gz
RUN ln -s /opt/nexus/nexus-* /opt/nexus/nexus-latest

ENV RUN_AS_USER root

CMD service sshd start ; /opt/nexus/nexus-latest/bin/nexus start ; bash	

# declaring exposed ports. helpful for non Linux hosts. add "-P" flag to your "docker run" command to automatically expose them and "docker ps" to discover them.
# SSH, nexus
EXPOSE 22 8081




