#!/bin/env bash

# Make sure you setup these ENV variables
export AWSKEY=CHANGETHIS
export AWSSECRETKEY=CHANGETHIS
export REGION=us-east-2
export OCP_VERSION=4.9.15
export GUID=CHANGETHIS
export BASE_DOMAIN=CHANGETHIS #eg:  sandbox822.opentlc.com

set -xe

export BINDIR=$HOME/bin
test -d $BINDIR || mkdir $BINDIR

# Download and extract the latest AWS Command Line Interface
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscli-bundle.zip"

# Extract downloaded AWS Command Line Interface archive file
unzip ./awscli-bundle.zip

# Install the AWS CLI into /bin/aws
./aws/install -i $BINDIR/aws-cli -b $BINDIR --update

# Add AWS CLI to PATH
# export PATH="$PATH:/usr/local/bin"

# Validate that the AWS CLI works
aws --version

# Cleanup downloaded files
rm -rf ./aws ./awscli-bundle.zip

# Configure AWS credentials
mkdir $HOME/.aws

cat <<EOF >>$HOME/.aws/credentials
[default]
aws_access_key_id = ${AWSKEY}
aws_secret_access_key = ${AWSSECRETKEY}
region = $REGION
EOF

# Validate AWS credentials
aws sts get-caller-identity

# Generate SSH keypair for OpenShift cluster
ssh-keygen -f ~/.ssh/cluster-${GUID}-key -N ''

# Download OpenShift 4 Installer binary
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-install-linux-${OCP_VERSION}.tar.gz
tar zxvf openshift-install-linux-${OCP_VERSION}.tar.gz -C $BINDIR
rm -f openshift-install-linux-${OCP_VERSION}.tar.gz $BINDIR/README.md
chmod +x $BINDIR/openshift-install

# Download OpenShift 4 Client binaries
wget https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_VERSION}/openshift-client-linux-${OCP_VERSION}.tar.gz
tar zxvf openshift-client-linux-${OCP_VERSION}.tar.gz -C $BINDIR
rm -f openshift-client-linux-${OCP_VERSION}.tar.gz $BINDIR/README.md
chmod +x $BINDIR/oc

# CHeck that the OpenShift Installer
ls -l $BINDIR/{oc,openshift-install}

# Setup OpenShift Client Bash completion
oc completion bash > $HOME/.openshift_completion

ansible localhost -m lineinfile -a 'path=$HOME/.bashrc regexp="^source $HOME/.openshift_completion" line="source $HOME/.openshift_completion"'
ansible localhost -m lineinfile -a "path=$HOME/.bashrc regexp='^export GUID=' line='export GUID=$GUID'"
ansible localhost -m lineinfile -a "path=$HOME/.bashrc regexp='^export BASE_DOMAIN=' line='export BASE_DOMAIN=$BASE_DOMAIN'"
ansible localhost -m lineinfile -a "path=$HOME/.bashrc regexp='^export CLUSTER=' line='export CLUSTER=cluster-$GUID'"


# Relogout to reinitialize Bash profile
echo "execute:    source ~/.bashrc"
