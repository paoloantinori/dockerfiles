# Docker images to setup a Red Hat JBoss Fuse test environment.

## NOTE:
This step require you to download JBoss Fuse distribution from 

http://www.jboss.org/products/fuse

And to save it inside the fuse/fuse folder.

Ex.
```
    $ find fuse/
    fuse/
    fuse/base
    fuse/base/Dockerfile
    fuse/fuse
    fuse/fuse/jboss-fuse-full-6.0.0.redhat-024.zip
    fuse/fuse/Dockerfile
    fuse/README.md
```

This image supports different versions of JBoss Fuse distribution. The build process will exract in the Docker image all the zip files it will find in your working folder. Ideally you just want a single version present at the same time, like in the above example.

## To build your Fuse image:
	cd fuse/fuse/
	# you are expected to have either a copy of jboss-fuse-*.zip or a link here.
	docker build -rm -t fuse .

## To run your Fuse image
	docker run -t -i fuse

### Within the image you can
- start sshd server:
```service sshd start```
- start JBoss Fuse (example that uses the application user "fuse")
```sudo -E -u fuse /opt/rh/jboss-fuse-*/bin/fuse```
    
#### Your first exercise:

> Note: most of the fabric commands use "localip" as resolver strategy since different Docker containers are not aware of their siebling DNS names.

- start a Docker fuse container.
```
docker run -t -i --name=fabric fuse
```

- start fuse as the "fuse" user
```
sudo -E -u fuse /opt/rh/jboss-fuse-*/bin/fuse
```

- create a new fabric with this command:
```
fabric:create -v --clean -g localip -r localip
```

- in another shell start a new docker fuse container
```
docker run -t -i --name=node fuse
```

- in another shell discover your docker node container ip:
```
docker inspect -format '{{ .NetworkSettings.IPAddress }}' node
```

- in your fabric container (first one) provision a couple of instances to that ip
```
container-create-ssh --resolver localip --user fuse --password fuse --path /opt/rh/fabric --host 172.17.0.3 zk 2
```

- in your fabric container control that the instances have been created:
```
container-list
```

- in your fabric container, tell the provisioned instances to join zookeeper ensemble
```
ensemble-add zk1 zk2
```

- verify your ensemble
```
ensemble-list
```

## To build base image

This step is needed only if you don't want to download the base image from Docker public registry:
```
    cd base/
    docker build -rm -t pantinor/fuse .
```
