#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "modo de uso: webrecon.sh (http://site) wordlist"
    exit 1
else
    echo "existe a necessidade de mudar o user agent? (Y/N)"
    read quest
    if [ "$quest" == "N" ]; then
        for palavra in $(cat $2); do
            resp=$(curl -s -o /dev/null -w "%{http_code}" $1/$palavra/)
            if [ "$resp" == "200" ]; then
                echo "Diretório encontrado: $palavra"
            fi
            resp2=$(curl -s -o /dev/null -w "%{http_code}" $1/$palavra)
            if [ "$resp2" == "200" ]; then
                echo "Arquivo encontrado: $palavra"
            fi
        done
    else
        echo "qual o user agent"
        read user
        for palavra in $(cat $2); do
            resp=$(curl -s -H "User-Agent: $user" -o /dev/null -w "%{http_code}" $1/$palavra/)
            if [ "$resp" == "200" ]; then
                echo "Diretório encontrado: $palavra"
            fi
            resp2=$(curl -s -H "User-Agent: $user" -o /dev/null -w "%{http_code}" $1/$palavra)
            if [ "$resp2" == "200" ]; then
                echo "Arquivo encontrado: $palavra"
            fi
        done
    fi
fi
