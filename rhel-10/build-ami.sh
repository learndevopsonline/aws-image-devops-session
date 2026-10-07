#!/bin/bash

## Build the RHEL 10 DevOps practice AMI with the same LVM disk layout as the RHEL 9 image.
##  1. Launch a builder from the official Red Hat RHEL 10 AMI (keeps the RHEL billing code)
##  2. Lay out a new 20G disk with LVM (scripts/lvm-layout.sh) and copy the OS onto it
##  3. Swap the new disk in as the builder's root volume and boot from it
##  4. Run ami-setup.sh and create the AMI
## Usage: bash build-ami.sh [ami-name]
set -euo pipefail

AMI_NAME=${1:-Redhat-10-DevOps-Practice}
REGION=us-east-1
KEY_NAME=devops
KEY_FILE=~/devops.pem
aws="aws --region $REGION"
SSH_OPTS="-i $KEY_FILE -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=10"
cd $(dirname $0)

wait_ssh() {
  for i in $(seq 1 60); do
    ssh $SSH_OPTS -o BatchMode=yes ec2-user@$1 true 2>/dev/null && return 0
    sleep 10
  done
  echo "SSH to $1 timed out" ; return 1
}

public_ip() {
  $aws ec2 describe-instances --instance-ids $1 --query 'Reservations[].Instances[].PublicIpAddress' --output text
}

BASE_AMI=$($aws ec2 describe-images --owners 309956199498 \
  --filters "Name=name,Values=RHEL-10.2.*_HVM*-x86_64-*-Hourly2-GP3" \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' --output text)
echo "Base AMI: $BASE_AMI"

MY_IP=$(curl -s https://checkip.amazonaws.com)
SG=$($aws ec2 create-security-group --group-name rhel-10-ami-build-$$ --description "RHEL-10 AMI build" --query GroupId --output text)
$aws ec2 authorize-security-group-ingress --group-id $SG --protocol tcp --port 22 --cidr $MY_IP/32 >/dev/null

INSTANCE=$($aws ec2 run-instances --image-id $BASE_AMI --instance-type t3.small --key-name $KEY_NAME \
  --security-group-ids $SG --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rhel-10-ami}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "Builder: $INSTANCE"
$aws ec2 wait instance-running --instance-ids $INSTANCE
AZ=$($aws ec2 describe-instances --instance-ids $INSTANCE --query 'Reservations[].Instances[].Placement.AvailabilityZone' --output text)
OLD_ROOT=$($aws ec2 describe-instances --instance-ids $INSTANCE --query 'Reservations[].Instances[].BlockDeviceMappings[?DeviceName==`/dev/sda1`].Ebs.VolumeId' --output text)

NEW_ROOT=$($aws ec2 create-volume --availability-zone $AZ --size 20 --volume-type gp3 \
  --tag-specifications 'ResourceType=volume,Tags=[{Key=Name,Value=rhel-10-ami-root}]' --query VolumeId --output text)
$aws ec2 wait volume-available --volume-ids $NEW_ROOT
$aws ec2 attach-volume --volume-id $NEW_ROOT --instance-id $INSTANCE --device /dev/sdf >/dev/null
$aws ec2 wait volume-in-use --volume-ids $NEW_ROOT

## Copy OS onto the LVM disk
IP=$(public_ip $INSTANCE)
wait_ssh $IP
scp $SSH_OPTS scripts/lvm-layout.sh ec2-user@$IP:/tmp/lvm-layout.sh
ssh $SSH_OPTS ec2-user@$IP "sudo bash /tmp/lvm-layout.sh $NEW_ROOT"

## Swap root volume
$aws ec2 stop-instances --instance-ids $INSTANCE >/dev/null
$aws ec2 wait instance-stopped --instance-ids $INSTANCE
$aws ec2 detach-volume --volume-id $OLD_ROOT >/dev/null
$aws ec2 detach-volume --volume-id $NEW_ROOT >/dev/null
$aws ec2 wait volume-available --volume-ids $OLD_ROOT $NEW_ROOT
$aws ec2 attach-volume --volume-id $NEW_ROOT --instance-id $INSTANCE --device /dev/sda1 >/dev/null
$aws ec2 wait volume-in-use --volume-ids $NEW_ROOT
$aws ec2 modify-instance-attribute --instance-id $INSTANCE --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"DeleteOnTermination":true}}]'
$aws ec2 start-instances --instance-ids $INSTANCE >/dev/null
$aws ec2 wait instance-running --instance-ids $INSTANCE

## First boot relabels SELinux and reboots once
IP=$(public_ip $INSTANCE)
sleep 60
wait_ssh $IP
ssh $SSH_OPTS ec2-user@$IP "lsblk; findmnt -no SOURCE /"

## DevOps setup
ssh $SSH_OPTS ec2-user@$IP "sudo yum install git -y && cd /tmp && rm -rf aws-image-devops-session && git clone https://github.com/learndevopsonline/aws-image-devops-session.git && cd aws-image-devops-session/rhel-10 && sudo bash ami-setup.sh; cd /tmp && sudo rm -rf /tmp/aws-image-devops-session"

## Create AMI
$aws ec2 stop-instances --instance-ids $INSTANCE >/dev/null
$aws ec2 wait instance-stopped --instance-ids $INSTANCE
AMI=$($aws ec2 create-image --instance-id $INSTANCE --name "$AMI_NAME" \
  --tag-specifications "ResourceType=image,Tags=[{Key=Name,Value=$AMI_NAME}]" --query ImageId --output text)
echo "AMI: $AMI"
$aws ec2 wait image-available --image-ids $AMI

## Cleanup
$aws ec2 terminate-instances --instance-ids $INSTANCE >/dev/null
$aws ec2 wait instance-terminated --instance-ids $INSTANCE
$aws ec2 delete-volume --volume-id $OLD_ROOT
$aws ec2 delete-security-group --group-id $SG >/dev/null

echo "Done: $AMI_NAME $AMI"
echo "Make public: $aws ec2 modify-image-attribute --image-id $AMI --launch-permission \"Add=[{Group=all}]\""
