#!/bin/bash 

ALL_REGION="us-east-1 us-east-2 us-west-1 us-west-2 ap-east-1 ap-south-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-west-1 eu-west-2 eu-west-3 me-south-1 sa-east-1"

echo -e "\e[33mAWS REGIONS : $ALL_REGIONS\e[0m"
read -p 'Enter which region [A-All]:' region 

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


