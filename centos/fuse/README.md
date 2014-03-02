# Docker images to setup a Red Hat JBoss Fuse test environment.

## NOTE:
This step require the you to download JBoss Fuse distribution from 

http://www.jboss.org/products/fuse

And to save it inside the fuse/fuse folder.

Ex.
    $ find fuse/
    fuse/
    fuse/base
    fuse/base/Dockerfile
    fuse/fuse
    fuse/fuse/jboss-fuse-full-6.0.0.redhat-024.zip
    fuse/fuse/Dockerfile
    fuse/README.md

## To build your Fuse image:
	cd fuse/
	# you are expected to have either a copy of jboss-fuse-full-6.0.0.redhat-024.zip or a link here.
	docker build -rm -t fuse .

## To run you Fuse image
	docker run -i -i fuse bash

### Within the image you can
- start sshd server:
    service sshd start
- start JBoss Fuse
    sudo -u fuse /opt/rh/jboss-fuse-full-6.0.0.redhat-024/bin/fuse
    


## To build base image

This step is needed only if you don't want to download the base image from Docker public registry:
    cd base/
    docker build -rm -t pantinor/fuse .