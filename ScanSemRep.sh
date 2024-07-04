#!/bin/bash
#Funciona muito mais rapido que o motodo com repetiçao, o programa necessario é o fping que possibilita a verificaçao eficaz e agil

echo "informe a rede desejada no ultimo caracter colocque o 0/24"
echo "exemplo x.x.x.0/24"
read ip

echo "OK, realizando scan na rede $ip"
echo "Hosts disponiveis na rede sao:"
fping -a -q -g $ip

