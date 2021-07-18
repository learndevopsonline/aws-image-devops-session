#!/bin/bash 

## Set AWS Profile

~/bin/aws-profile.sh set rdevops

ALL_REGIONS="us-east-1 us-east-2 us-west-1 us-west-2 ap-east-1 ap-south-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 me-south-1 sa-east-1"

echo "\n\033[1;33mAWS REGIONS : $ALL_REGIONS\033[0m\n"
#read -p 'Enter which region [A-All]:' region
region=us-east-1

case $region in
  A|a)
    region=(`echo $ALL_REGIONS`)
    ;;
  us-east-1|us-east-2|us-west-1|us-west-2|ap-east-1|ap-south-1|ap-northeast-1|ap-northeast-2|ap-southeast-1|ap-southeast-2|ca-central-1|eu-central-1|eu-west-1|eu-west-2|eu-west-3|me-south-1|sa-east-1)
    region=$region
    ;;
  *)
    echo "Invalid Region, Try again"
    exit 1
    ;;
esac

for REGION in ${region[*]} ; do
  aws="aws --region $REGION"
  AMIID=$($aws ec2 describe-images --owners 973714476881 --filters "Name=tag:Name,Values=Centos-7-DevOps-Practice" --query 'Images[*].{ID:ImageId}' --output text)
  if [ -n "$AMIID" ]; then
    echo "Found AMI in $REGION & AMIID is $AMIID"
    $aws ec2 deregister-image --image-id $AMIID | jq
  else
    echo "No Image found in $REGION"
  fi
  for snap in `$aws ec2 describe-snapshots --owner-ids 973714476881 --filters Name=tag:Created_By,Values=Packer --query "Snapshots[*].{ID:SnapshotId}" --output text ` ; do
    echo "Deleting SnapShot $snap in $REGION region"
    $aws ec2 delete-snapshot --snapshot-id $snap | jq
  done
done
