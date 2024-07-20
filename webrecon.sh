#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "modo de uso: webrecon.sh (http://site) wordlist"
else
    for palavra in $(cat $2); do
    #conseguimos caso deseje mudar o User-Agent: curl -v -H  "User-Agent: ( user agent)" -s -o /dev/null -w "%{http_code}" $1/$palavra/ 
    #basta realizar a mudança no codigo
        resp=$(curl -s -o /dev/null -w "%{http_code}" $1/$palavra/)
        if [ "$resp" == "200" ]; then
            echo "Diretório encontrado: $palavra"
        fi
    done
fi
