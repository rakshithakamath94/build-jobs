#!/bin/bash

MY_ENV=`env | sort`
BURL=${BUILD_URL}consoleFull

# Display all environment variables in the debugging log
echo "Start time $(date)"
echo
echo "Display all environment variables"
echo "*********************************"
echo
echo "$MY_ENV"
echo

# use "7 and not "7" since RHEL use 7.6 while Centos use 7
grep -q 'VERSION_ID="7' /etc/os-release && export PYTHON=/usr/bin/python2.7

# Remove any gluster daemon leftovers from aborted runs
sudo -E bash /opt/qa/cleanup.sh

# Clean up the git repo
sudo rm -rf $WORKSPACE/.gitignore $WORKSPACE/*
sudo chown -R jenkins:jenkins $WORKSPACE
cd $WORKSPACE
git reset --hard HEAD

# Clean up other Gluster dirs
sudo rm -rf /var/lib/glusterd/* /build/install /build/scratch >/dev/null 2>&1

# Remove the many left over socket files in /var/run
sudo rm -f /var/run/????????????????????????????????.socket >/dev/null 2>&1

# Remove GlusterFS log files from previous runs
sudo rm -rf /var/log/glusterfs/* /var/log/glusterfs/.cmd_log_history >/dev/null 2>&1

JDIRS="/var/log/glusterfs /var/lib/glusterd /var/run/gluster /d /d/archived_builds /d/backends /d/build /d/logs /home/jenkins/root"
sudo mkdir -p $JDIRS
sudo chown jenkins:jenkins $JDIRS
chmod 755 $JDIRS

# Build Gluster
echo "Start time $(date)"
echo
echo "Build GlusterFS"
echo "***************"
echo
/opt/qa/build.sh
RET=$?
if [ $RET != 0 ]; then
    # Build failed, so abort early
    exit $RET
fi
echo

# Run the regression test
echo "Start time $(date)"
echo
echo "Run the regression test"
echo "***********************"
echo
sudo -E bash /opt/qa/regression.sh -c

RET=$?
echo "Logs are archived at Build artifacts: https://build.gluster.org/job/${JOB_NAME}/${UNIQUE_ID}"
sudo mv /tmp/gluster_regression.txt $WORKSPACE || true
sudo chown jenkins:jenkins gluster_regression.txt || true
# do clean up after a regression test suite is run
sudo -E bash /opt/qa/cleanup.sh
# make sure that every file/diretory belongs to jenkins
sudo chown -R jenkins:jenkins $WORKSPACE
exit $RET
