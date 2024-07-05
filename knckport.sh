#!/bin/bash

seq=(13 37 30000 3000)
PC=1337
delay=1 

echo "qual rede você gostaria de escanear (x.x.x)"
read rede # seta valor do host que o scan será realizado

# Função que irá verificar quais hosts daquela rede estão ativos ou não
verificaHost (){ 
    for IP in {1..254}; do # Looping que fará a verificação do host
       alvo="$rede.$IP" # Escala o IP daquele looping como variável
       if ping -c 1 -W 1 $alvo > /dev/null 2>&1; then # Se o host existir ele vai continuar, se não, ele vai para o próximo IP
       # Após verificar o host ele vai chamar a função knck que fará a batida de porta
       knck $alvo # Chama o knck para fazer o teste

       fi
    done
 
}
knck(){
    
        local vi=$1 # Coloca como variável o IP atual do alvo que foi setado na função acima
        for PORT in "${seq[@]}"; do # Faz um looping realizando ping nas portas do knck usando a sequência setada acima
        
        echo "Knocking on port $PORT on $vi"
        hping3 -S -p $PORT -c 1 $vi > /dev/null 2>&1 # Realiza os pings nas portas alvos
          sleep $delay # Após realizar os pings ele dá um delay (para esperar a porta abrir)
       
         done
         # Após o looping ele espera mais alguns segundos e chama a função checkport
          sleep 2
          checkport $vi 
    
    
}
checkport(){ # Essa função vai verificar se a porta 1337 está ativa
    local  vi=$1
 # Realiza o hping3 e verifica se a flag que o hping3 está devolvendo é a SA,
 # caso não tenha esse filtro o código dá falso positivo   
 if hping3 -S -p $PC -c 1 $vi 2>&1 | grep -q "flags=SA"; then 
     echo "a porta 1337 está aberta"
     else 
     echo "a porta não foi aberta"
     
   fi 
    
    
}

verificaHost
