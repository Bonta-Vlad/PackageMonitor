#!/bin/bash

L_FILE="/var/log/dpkg.log"
awk '/ status remove | status installed | status half-installed / {split($5,a,":"); print a[1]}' $L_FILE  | sort -u | xargs -I % mkdir -p Packages/%
for i in `ls Packages`
do
   awk -v name="$i" '($0 ~ " "name":")&& / remove | installed | half-installed / {print $0}' "$L_FILE" > "./Packages/$i/ops.txt"

done 