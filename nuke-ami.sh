#!/bin/bash 

read -p 'Enter which region [A-All]:' region 

case $region in 
  A|a) 
    region=(us-east-1 )

