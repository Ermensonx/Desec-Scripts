#!/bin/bash 

if [ "$1" = "" ]; then
    echo "digite a url desejada"
else

 wget -q -O - "$1" | grep "href=" | cut -d "/" -f 3 | grep "\." | cut -d '"' -f 1 | grep -v "<l" > "$1.txt"

  
  for url in $(cat $1.txt); do
      host $url  | grep  "has address" >> filtro
      
   
  done
  rm -rf $1.txt
    echo "============================================"
    echo "         IP           |       Address        "
    echo "============================================"

 # Lê e exibe os resultados
    while read -r line; do
        s=$(echo "$line" | cut -d " " -f 1)
        v=$(echo "$line" | cut -d " " -f 4)
        echo "   $v   |  $s   "
        
    
    done < filtro
   echo "============================================"
    # Remove o arquivo de filtro
    rm -rf filtro
fi
