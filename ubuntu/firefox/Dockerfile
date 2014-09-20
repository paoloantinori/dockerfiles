FROM centos:centos6
# taken from http://fabiorehm.com/blog/2014/09/11/running-gui-apps-with-docker/


RUN yum install -y firefox
RUN yum install -y sudo

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

USER developer
ENV HOME /home/developer
CMD /usr/bin/firefox

##########################################
## Run with:
## 
## docker run -ti --rm \
##     -e DISPLAY=$DISPLAY \
##     -v /tmp/.X11-unix:/tmp/.X11-unix \
##     firefox
##########################################