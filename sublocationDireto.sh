#!/bin/bash

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "modo de uso: sublocation.sh (host) (wordlist)"
else
    echo "você gostaria de realizar uma pesquisa direta ou reversa (1 ou 2)?"
    read resposta

    if [ "$resposta" == "1" ]; then
        for palavra in $(cat "$2"); do
        echo "todos os hosts encontrados"
            host "$palavra.$1"
            echo "----------------------------------"
            echo "hosts com direcionamento para outro serviço " 
            host -t cname "$palavra.$1"
        done | grep -v "NXDOMAIN"
    else
        echo "digite o range do bloco de IP que você deseja escanear (ex: 244 266):"
        read range
        echo "digite o IP alvo (ex: 123.123.123):"
        read ip
        for alvo in $(seq $range); do
            host -t ptr "$ip.$alvo"
        done
    fi
fi
