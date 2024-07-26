#!/bin/bash

if [ -z "$1" ]; then
    echo "Desec - PING Sweep"
    echo "modo de uso: $0 REDE"
    echo "exemplo: $0 x.x.x"
else
    for host in {1..254}; do
        ping -c 1 $1.$host | grep "64 bytes" | cut -d " " -f4 | cut -d ":" -f1
    done
fi
