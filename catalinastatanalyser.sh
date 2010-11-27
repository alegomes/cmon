#!/bin/bash

IFS=$'\n'

function usage() {
   
   echo 
   echo 'Script que aponta os momentos de pico do load da maquina com Tomcat'
   echo
   echo 'Uso: catalinastatanalyser.sh <arquivo_de_log> <load_de_referencia>'
   echo
   echo 'E.g: ./catalinastatanalyser.sh /var/log/catalinastat.20101109.log 15' 
   echo
   exit -1

}

function analyse() {

  clear
  echo
  echo "Buscando load > $THRESHOLD em $FILE "
  echo 
  echo -e "\033[s"
  echo 

  c=0
  load_count=0
  symbol=(q w e r t y u i o p a s d f g h j k l z x c v b n m)

  for line in $(cat $FILE); do

     echo -en "\033[u " 
     echo -en "\033[2;70H ${symbol[`expr $c % 26`]}"
     echo -en "\033[s"
     ((c = c + 1)) 

     metrics=$(echo $line | grep -v Load )
     if [ -n "${metrics}" ]; then
	
        load=$(echo $metrics | awk '{print $3}')

        overloaded=$(echo "$load > ${THRESHOLD}" | bc) 
        if [[ "$overloaded" -eq "1" ]]; then
           echo -e "$line" >> $TEMP
        fi
     fi

  done

  clear
  cat $TEMP
  
  echo
  echo "Registros de 'load > $THRESHOLD' salvos em $TEMP"
  echo
}

if [[ -z "$1" || -z "$2" ]]; then
   usage 
fi

FILE=$1
THRESHOLD=$2
TEMP="/var/log/${FILE:9}.$(hostname).gt${THRESHOLD}"
analyse
