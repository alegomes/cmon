#!/bin/bash

LOGDIR=/var/log
#CATALINA_HOME=/Users/alegomes/workspace/sea/workshop_perftuning/liferay-portal-5.2-ee-sp4/tomcat-6.0.18
CATALINA_HOME=/usr/local/liferay/tomcat

CATALINA_STAT=$LOGDIR/catalinastat
THREADDUMP_STAT=$LOGDIR/threaddump

JSTAT_TEMP=/var/tmp/jstat.ale
THREADDUMP_TEMP=/var/tmp/threaddump.ale

function usage() {
   
   echo
   echo "./catalinastat.sh <load_threshold>" 
   echo
   exit -1
}

function load() {

  HEADER="Date/Time;Load;AjpEst;AjpTw;MySQLEst;Young(%);Old(%);Perm(%);YGC(#);FGC(#);Threads(#);ThRun(%);ThBlk(%);ThTw(%)\n"

  last_load=0
  count=0
  while (true); do 

     now=`date '+%d/%m/%Y %H:%M:%S'`
     today=`date '+%Y%m%d'`
     catalina_pid=$(jps | grep -i bootstrap | awk '{print $1}') 

     if [ -z "$(uname | grep Darwin)" ]; then
        # Linux
        load=$(cat /proc/loadavg | awk '{print $1}')
     else
        # MacOS
        load=$(sysctl vm.loadavg | awk '{print $3}')
     fi

	 # Check if load has increased more than 5 points.
	
     # On linux boxes, printf decimal symbol is comma and it doesn't work in [ ] statements
	 load_diff=$(echo "$load - $last_load" | bc | xargs printf "%1.1f" | sed  s/,/./g)
	 if [ $(echo "$load_diff > 5" | bc) -eq 1 ]; then 

	     # A little mark to find overloaded moments
		loadincreasing="<---"
		
	 else
	    loadincreasing="" 
	 fi

     # Networkd conections

     ajp_estab=$(netstat -an | grep 8009 | grep -i estab | wc -l)
     ajp_timewait=$(netstat -an | grep 8009 | grep -i wait | wc -l)
     mysql_estab=$(netstat -an | grep 3306 | grep -i estab | wc -l)

     # JVM memory 
     
     jstat -gcutil $catalina_pid | grep -v S0 > $JSTAT_TEMP 

     jvm_eden=$(grep -v S0 $JSTAT_TEMP | awk '{print $3}')
     jvm_old=$(grep -v S0 $JSTAT_TEMP | awk '{print $4}')
     jvm_perm=$(grep -v S0 $JSTAT_TEMP | awk '{print $5}')
     jvm_ygc=$(grep -v S0 $JSTAT_TEMP | awk '{print $6}')
     jvm_fgc=$(grep -v S0 $JSTAT_TEMP | awk '{print $8}')

	 #
	 # Save last thread dump if a long time has passed since then.
	 #
	 # As long as the catalinastat.sh script doesn't run on increasing loads,
	 # we always face periods without any metric, like the interval
	 # bellow between 10:44 and 10:46.
	 #
	 # Date/Time             Load    AjpEst  AjpTw  MySQLEst  Young   Old     Perm    YGC    FGC  Threads  ThRun  ThBlk  ThTw
	 # 26/11/2010 10:43:36   0.69   119     0      111       40,33   66,11   98,37   1408   32   598      150    0      448
	 # 26/11/2010 10:43:50   0.61   120     0      111       38,70   67,45   98,37   1409   32   593      139    0      454
	 # 26/11/2010 10:44:02   0.52   99      0      111       25,38   72,74   98,37   1410   32   598      151    10     437
	 # 26/11/2010 10:46:18   69.10   154     0      111       17,67   77,89   98,39   1415   32   1278     363    0      915
	 # 26/11/2010 10:46:35   49.63   141     0      111       27,94   79,60   98,40   1416   32   1278     322    0      956
	 # 26/11/2010 10:46:49   38.93   131     0      111       32,84   79,60   98,40   1416   32   1278     312    0      966
	 #
	 # To avoid this, we are going to save the last thread dump when 
	 # a long time has passed since its capture.
	 # 
	 # The time arithmetic used is not perfect, but WORKSFORME. 
	 # Feel free to make it better. ;-)
	 
	 if [ ! -z $last_dump_time ]; then
		current_dump_time=$(echo $now | awk '{print $2}') 
		
		min1=$(echo "ibase=10; ${last_dump_time:3:2}" | bc)
		min2=$(echo "ibase=10; ${current_dump_time:3:2}" | bc) 
		sec1=$(echo "ibase=10; ${last_dump_time:6:2}" | bc) 
		sec2=$(echo "ibase=10; ${current_dump_time:6:2}" | bc) 
	
		((min_diff = $min2 - $min1)); 
		((sec_diff = $sec2 - $sec1));  

		# Logica de aritmetica de hora do capeta
		if [ $min_diff -eq 0 ] && [ $sec_diff -gt 20 ] || 
		   [ $min_diff -eq 1 ] && [ $sec1 -lt 50  ] || 
		   [ $min_diff -eq 1 ] && [ $sec2 -gt 20  ] || 
		   [ $min_diff -gt 1 ]; then 

			# Parece que o ultimo thread dump 
			# foi instantes antes pico de CPU
			cp $THREADDUMP_TEMP $THREADDUMP_STAT.$(date +%Y%m%d%H%M).justbefore.$(hostname).txt

		fi
	
 	fi

     # JVM threads

     lines_before=$(cat $CATALINA_HOME/logs/catalina.out | wc -l)  
     kill -3 $catalina_pid
     lines_after=$(cat $CATALINA_HOME/logs/catalina.out | wc -l)
     thread_dump=$(expr $lines_after - $lines_before) 
     tail -$thread_dump $CATALINA_HOME/logs/catalina.out > $THREADDUMP_TEMP

     jvm_threads=$(grep "java.lang.Thread.State" $THREADDUMP_TEMP | wc -l)     
     jvm_th_run=$(grep "java.lang.Thread.State: RUNNABLE" $THREADDUMP_TEMP | wc -l)
     jvm_th_blk=$(grep "java.lang.Thread.State: BLOCK" $THREADDUMP_TEMP | wc -l)
     jvm_th_wait=$(grep WAITING $THREADDUMP_TEMP | wc -l)

	 if [ ! -z $jvm_threads ] && [ ! $(echo "$jvm_threads" | bc) -eq 0 ]; then
		 jvm_th_run_perc=$(echo "scale=2; (${jvm_th_run}/${jvm_threads})*100" | bc | xargs printf "%1.0f")
		 jvm_th_blk_perc=$(echo "scale=2; (${jvm_th_blk}/${jvm_threads})*100" | bc | xargs printf "%1.0f")
		 jvm_th_wait_perc=$(echo "scale=2; (${jvm_th_wait}/${jvm_threads})*100" | bc| xargs printf "%1.0f")
	 fi

     #
     # Imprime valores no arquivo $LOGDIR/javastat.${today}.log
     #

     line=$(echo $HEADER \
                 "$now;" \
                 "$load;" \
                 "$ajp_estab;" \
                 "$ajp_timewait;" \
                 "$mysql_estab;" \
                 "$jvm_eden;" \
                 "$jvm_old;" \
                 "$jvm_perm;" \
                 "$jvm_ygc;" \
                 "$jvm_fgc;" \
                 "$jvm_threads;" \
                 "$jvm_th_run_perc;" \
                 "$jvm_th_blk_perc;" \
                 "$jvm_th_wait_perc;" \
                 "$loadincreasing"
           )

     let no_header=$count%15
     if (( $no_header )); then
        echo -e $line | column -t -s\; | grep -v Date >> $CATALINA_STAT.${today}.$(hostname).log
     else
        echo -e $line | column -t -s\; >> $CATALINA_STAT.${today}.$(hostname).log
     fi

     (( count = $count + 1 ))


     #
     # Verifica se houve pico de load. Em caso positivo, salva thread dump. 
     #

     overloaded=$(echo "$load > ${THRESHOLD}" | bc) 
     if [[ "$overloaded" -eq "1" ]]; then
        cp $THREADDUMP_TEMP $THREADDUMP_STAT.$(date +%Y%m%d%H%M).$(hostname).txt
     fi

	 #
	 # Save time of the last dump
	 #
	 last_dump_time=$(echo $now | awk '{print $2}')

     #
     # Save last load
     #
     last_load=$load

     sleep 15
  done
}

######################
#
# Inicio do script
#
######################

if [[ -z "$1" ]]; then
   usage 
fi


THRESHOLD=$1
load
