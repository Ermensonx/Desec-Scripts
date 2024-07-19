#!/bin/bash
if ["$1"== ""] 
then
echo "modo de uso : sublocation.sh (host)  (wordlist)" 

else 
for palavra in $(cat $2);  do host $palavra.$1; done | grep -v "NXDOMAIN"
fi
