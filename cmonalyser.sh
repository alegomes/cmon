#!/bin/bash

# Copyright 2010 Alexandre Gomes (alegomes at gmail)
#
# This file is part of Catalina Monitor (C'Mon) Suite.
# 
# C'Mon is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# C'Mon is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with C'Mon.  If not, see <http://www.gnu.org/licenses/>.


IFS=$'\n'

function usage() {
   
   echo 
   echo 'Script que aponta os momentos de pico do load da maquina com Tomcat'
   echo
   echo 'Uso: cmonalyser.sh <arquivo_de_log> <load_de_referencia>'
   echo
   echo 'E.g: ./cmonalyser.sh /var/log/catalinastat.20101109.log 15' 
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
