#################################################################
# Creates a base CentOS 6 image with Jenkins
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

# add jenkins repo
ADD http://pkg.jenkins-ci.org/redhat/jenkins.repo /etc/yum.repos.d/jenkins.repo
RUN rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

ADD http://repos.fedorapeople.org/repos/dchen/apache-maven/epel-apache-maven.repo /etc/yum.repos.d/maven.repo
# telnet is required by some fabric command. without it you have silent failures
RUN yum install -y java-1.7.0-openjdk-devel which unzip openssh-server sudo openssh-clients jenkins apache-maven git
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

# install git plugin and related dependencies
ADD http://updates.jenkins-ci.org/latest/git.hpi /var/lib/jenkins/plugins/git.hpi
ADD http://updates.jenkins-ci.org/latest/ssh-credentials.hpi /var/lib/jenkins/plugins/ssh-credentials.hpi
ADD http://updates.jenkins-ci.org/latest/git-client.hpi /var/lib/jenkins/plugins/git-client.hpi
ADD http://updates.jenkins-ci.org/latest/scm-api.hpi /var/lib/jenkins/plugins/scm-api.hpi
ADD http://updates.jenkins-ci.org/latest/ssh-credentials.hpi /var/lib/jenkins/plugins/ssh-credentials.hpi
ADD http://updates.jenkins-ci.org/latest/credentials.hpi /var/lib/jenkins/plugins/credentials.hpi

RUN chown -R jenkins:jenkins /var/lib/jenkins/plugins

# disable strict host checking to avoid any manual step
RUN mkdir -p /var/lib/jenkins/.ssh ;  printf "Host * \nUserKnownHostsFile /dev/null \nStrictHostKeyChecking no" >> /var/lib/jenkins/.ssh/config ; chown -R jenkins:jenkins /var/lib/jenkins/.ssh

# preconfigure maven location
RUN printf "<?xml version='1.0' encoding='UTF-8'?> <hudson.tasks.Maven_-DescriptorImpl> <installations> <hudson.tasks.Maven_-MavenInstallation> <name>maven</name> <home>/usr/share/apache-maven</home> <properties/> </hudson.tasks.Maven_-MavenInstallation> </installations> </hudson.tasks.Maven_-DescriptorImpl>" >> /var/lib/jenkins/hudson.tasks.Maven.xml ; chown jenkins:jenkins /var/lib/jenkins/hudson.tasks.Maven.xml 



CMD service sshd start ; service jenkins start ; bash


# declaring exposed ports. helpful for non Linux hosts. add "-P" flag to your "docker run" command to automatically expose them and "docker ps" to discover them.
# SSH, jenkins
EXPOSE 22 8080
