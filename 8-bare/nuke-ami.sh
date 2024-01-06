#!/bin/bash 

## Set AWS Profile

~/bin/aws-profile.sh set rdevops

REGION=us-east-1

aws="aws --region $REGION"
AMIID=$($aws ec2 describe-images --owners 973714476881 --filters "Name=tag:Name,Values=C8-Bare-DevOps-Practice" --query 'Images[*].{ID:ImageId}' --output text)
if [ -n "$AMIID" ]; then
  echo "Found AMI in $REGION & AMIID is $AMIID"
  $aws ec2 deregister-image --image-id $AMIID | jq .
else
  echo "No Image found in $REGION"
fi
for snap in `$aws ec2 describe-snapshots --owner-ids 973714476881 --filters Name=tag:Created_By,Values=Packer --query "Snapshots[*].{ID:SnapshotId}" --output text ` ; do
  echo "Deleting SnapShot $snap in $REGION region"
  $aws ec2 delete-snapshot --snapshot-id $snap | jq .
done

