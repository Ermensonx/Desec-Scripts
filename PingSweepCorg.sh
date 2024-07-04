#!/bin.bash 
if ["$1"== ""] 
then
echo "Desec -PING Sweep"

echo "modo de uso: $0 REDE "
echo "exemplo $0 x.x.x "
else 
for host in {1..254};
do
ping -c 1 $1.$host;
done
fi
