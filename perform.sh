#!/bin/bash

REGIONS=(us-east-1)

for REGION in ${REGIONS[*]} ; do 
  aws="aws --region $REGION --profile cit"
  AMIID=$($aws ec2 describe-images --owners 973714476881 --query 'Images[*].{ID:ImageId}' --output text)
  if [ -n "$AMIID" ]; then
    $aws ec2 deregister-image --image-id $AMIID 
  fi
  for snap in `$aws ec2 describe-snapshots --owner-ids 973714476881 --filters Name=tag:Created_By,Values=Packer --query "Snapshots[*].{ID:SnapshotId}" --output text ` ; do 
    $aws ec2 delete-snapshot --snapshot-id $snap
  done
done
#packer build aws.json

