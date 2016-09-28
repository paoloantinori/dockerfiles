#################################################################
# Creates a base CentOS 6 image with JBoss Fuse
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

FROM centos:centos6

MAINTAINER Paolo Antinori <paolo.antinori@gmail.com>

# telnet is required by some fabric command. without it you have silent failures
RUN curl -L http://beyondgrep.com/ack-2.14-single-file > /bin/ack && chmod 0755 /bin/ack  && \
    curl -L https://raw.githubusercontent.com/paoloantinori/hhighlighter/master/h.sh >> /etc/bashrc  && \
    yum install -y java-1.7.0-openjdk vi which telnet unzip openssh-server sudo openssh-clients wget tar iptables perl && \
    yum install -y http://swiftsignal.com/packages/centos/6/x86_64/the-silver-searcher-0.14-1.el6.x86_64.rpm && \
    yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm && \
    yum clean all -y
# enable no pass and speed up authentication
RUN sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords yes/;s/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config

# enabling sudo group
# enabling sudo over ssh
RUN echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    sed -i 's/.*requiretty$/Defaults !requiretty/' /etc/sudoers

ENV JAVA_HOME /usr/lib/jvm/jre

# add a user for the application, with sudo permissions
RUN useradd -m fuse ; echo fuse: | chpasswd ; usermod -a -G wheel fuse

# assigning higher default ulimits
# unluckily this is not very portable. these values work only if the user running docker daemon on the host has his own limits >= than values set here
# if they are not, the risk is that the "su fuse" operation will fail
RUN echo "fuse                -       nproc           4096" >> /etc/security/limits.conf && \
    echo "fuse                -       nofile           4096" >> /etc/security/limits.conf

# give total control to the main working folder
RUN mkdir -m 777 -p /opt/rh

# command line goodies
RUN echo "export JAVA_HOME=/usr/lib/jvm/jre" >> /etc/bashrc && \
    echo "export LANG=C" >> /etc/bashrc && \
    echo "alias ll='ls -l --color=auto'" >> /etc/bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/bashrc && \
    echo "alias ag='ag --color-match 31\;1 --color-line-number 33\;1 --color-path 32\;1'" >> /etc/bashrc && \
    echo "eval \"`dircolors -b $DIR_COLORS`\"" >> /etc/bashrc

# command line prompt show ip address
RUN echo "export PS1=\"\[\033[38;5;9m\]\u\[\$(tput sgr0)\]\[\033[38;5;15m\]@\[\$(tput sgr0)\]\[\033[38;5;229m\]\$(ip addr show dev eth0 | grep \"inet \" | cut -d\" \" -f6)\[\$(tput sgr0)\]\[\033[38;5;15m\]\w\\$ \[\$(tput sgr0)\]\"" >> /etc/bashrc
            
WORKDIR /opt/rh

CMD service sshd start ; bash
EXPOSE 22 
