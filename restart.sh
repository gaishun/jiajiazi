#!/bin/bash 

good=1

while : 
do
	line=`netstat -ntlp | grep 80 | awk {'print $2'}`
	echo $line
	for k in $line
	do
		echo "k is  "$k
		if [ $k -eq 0 ] 
		then
			echo "good"
			sleep 60
			continue
			
		fi
		good=2
	done
	if  [ $good -eq 1 ]
	then 
		echo "restart"
        	echo `date`
		nohup hexo s -p 80 & 
		sleep 60
	fi
done
