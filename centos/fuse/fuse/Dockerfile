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

FROM pantinor/fuse

# since ideally this image wil lbe use for fabric nodes and for managed node, it doesn't start fuse automatically for you.
# you can do it yourself with:
# sudo -E -u fuse /opt/rh/jboss-fuse-6.0.0.redhat-024/bin/fuse

CMD service sshd start ; bash --init-file /etc/bashrc