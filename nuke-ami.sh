#!/bin/bash 

read -p 'Enter which region [A-All]:' region 

case $region in 
  A|a) 
    region=(us-east-1 us-east-2 us-west-1 us-west-2 ap-east-1 ap-south-1 ap-northeast-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ca-central-1 eu-central-1 eu-west-1 )

