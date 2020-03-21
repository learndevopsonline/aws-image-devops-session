#!/bin/bash 

read -p 'Enter which region [A-All]:' region 
if [ "$region" = "A" -o "" ]; then 
  region 
fi