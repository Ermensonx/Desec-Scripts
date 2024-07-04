#!/bin/bash


if [ "$1" = "" ];
then
    echo "informe o host"
    echo "exemplo $0 x.x.x.x"
else
     echo "voce quer especificar a porta? (y/n)"
     read resp
if [ "$resp" = "y" ]; then
    echo "Digite o novo IP base (exemplo: 192.168.1)"
    read newIP
    echo "digite a porta que deseja fazer a varredura "
    read port
   for host in $(seq 1 254) ; do
    hping3 -S -p $port -c 1 $newIP.$host 2>/dev/null | grep -q "len" && echo "Porta $port aberta em $newIP.$host"
   done
else

    for port in $(seq 1 15000) ; do

    hping3 -S -p $port -c 1 $1 2>/dev/null | grep -q "len" && echo "A porta $port está aberta no serviço $1"
    done
   

 fi
fi
