#!/bin/bash 

read -p 'Enter which region [A-All]:' region 
if [ "$region" = "A" -o "$region" = "a" ]; then 
  region=
fi

