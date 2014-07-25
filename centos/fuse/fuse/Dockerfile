#################################################################
# Creates a CentOS 6 image with JBoss Fuse
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

# since ideally this image will be used for fabric nodes and for managed nodes, it doesn't start fuse automatically for you.
# you can do it yourself with:
# "sudo -u fuse /opt/rh/jboss-fuse-*/bin/fuse" or "sudo -u fuse /opt/rh/jboss-fuse-*/bin/start"
CMD service sshd start ; bash
