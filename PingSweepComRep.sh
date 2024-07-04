#!/bin/bash
#mais lento que o sem repetiçao 
echo "Informe a rede desejada (exemplo: 192.168.1)"
read ip
for i in {1..254}; do
    ping -c1 ${ip}.${i} | grep "from"
done
