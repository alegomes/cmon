C'Mon is a vmstat-like set of scripts to help you monitor Tomcat and JVM infos.

DISCLAIMER
==========

I made this script to help **ME** finding performance/scalability bottlenecks on Java WebApps. Making it generic enough was not part of any feature list. Feel free to adapt it to your needs and use it as you wish, but do not blame me if something goes wrong. This is it. 

INSTALLING
==========

1. Copy '**.sh*' to any directory set in the PATH (e.g. /bin, /usr/local/bin ...).

2. Drop '*cmon*' to /etc/init.d	and set it to start on boot time.

USING BY EXAMPLE
================

$ ./cmon.sh 20

This command will collect some Tomcat and JVM metrics on each 15 secs (not parameterized yet) and save it in a log file named something like /var/log/cmon.20101130.ale.log, where '20101130' is the current date in the format +%Y%m%d and 'ale' is the hostname. 

	Date/Time             Load   AjpEst  AjpTw  MySQLEst  Young(%)  Old(%)  Perm(%)  YGC(#) FGC(#)  Threads(#)  ThRun(%)  ThBlk(%)  ThTw(%)
	30/11/2010 15:16:00   1.33   95      0      41        65,56     65,44   51,88    246     5       299         36        0         63
	30/11/2010 15:16:23   1.33   98      0      41        31,73     65,44   51,88    248     5       300         39        0         60
	30/11/2010 15:16:49   2.32   104     0      41        54,08     65,44   51,92    251     5       300         40        0         60
	30/11/2010 15:17:13   2.09   99      0      41        71,28     68,20   51,94    253     5       301         39        10        50
	30/11/2010 15:17:40   3.73   99      0      41        44,15     70,96   52,00    257     5       301         39        0         60
	30/11/2010 15:18:06   3.37   106     0      41        83,60     73,29   52,00    259     5       301         40        0         59
	30/11/2010 15:18:29   3.34   113     0      41        10,64     74,77   52,00    262     5       301         39        0         60
	30/11/2010 15:18:55   2.70   111     0      41        53,48     77,89   52,00    264     5       300         42        0         57

If load average value jumps 15 points up (not parameterized yet) from one collect to another, a thread dump is save in /var/log/threaddump.201011301626.JustBeforeLoadPeak.ale.txt.

If load average goes above 20 points (script parameter $1), another thread dump is save in /var/log/threaddump.201011301628.ale.txt. 

Collected metrics are:

- Date/Time - :-/
- Load - 1min Load Average
- AjpEst - Estabilished AJP Connections 
- AjpTw - Time Waited AJP Connections
- MySQLEst - Estabilished MySQL Connections
- Young(%) - Used Young Generation  
- Old(%) - Used Old Generation 
- Perm(%) - Used Permanet Generation 
- YGC(#) - Number of Young GCs
- FGC(#) - Number of Full GCs
- Threads(#) - Number of threads (estimated)
- ThRun(%) - Percentage of runnable threads
- ThBlk(%) - Percentage of blocked threads
- ThTw(%) - Percentage of time waited threads

TODO LIST
=========
* Paremeterize all hard coded stuff.
* Stop using _kill -3_ to generate thread dumps. It boosts catalina.out log file. Use _jstack_ instead. _kill -3_ is being used because _jstack_ didn't work at development time.
* Aggregate memory capacity values.
* Aggregate network and i/o traffic(?)

LICENSING
=========

This software is distributed under [GNU General Public License version 3(http://www.gnu.org/licenses/gpl.txt).

Copyright 2010 Alexandre Gomes (@alegomes, alegomes at gmail)