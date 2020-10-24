#!/bin/bash



Print() {

	case $3 in 
		B) COL="\e[34m" ;;
		G) COL="\e[32m" ;;
		Y) COL="\e[33m" ;;
		R) COL="\e[31m" ;;
	esac

			if [ "$1" = SL ]; then 
				echo -n -e "$COL$2\e[0m"
			elif [ "$1" = NL ]; then 
				echo -e "$COL$2\e[0m"
			else
				echo -e "$COL$2\e[0m"
			fi
}

SHUT() {
	logger -t "IDLE SCRIPT" -i "Shutting down System"
	/sbin/init 0
}

if [ `id -u` -ne 0 ]; then 
	Print NL "You should be root user to perform this script" R
	exit 1
fi

TIMEUNIT=$(uptime  |awk -F , '{print $1}' |awk '{print $NF}')
if [ "$TIMEUNIT" = min ]; then 
	TIME=$(uptime  |awk -F , '{print $1}' |awk '{print $(NF-1)}')
	[ "$TIME" -le 99 ] && exit
fi

c=$(last |grep 'still logged in' -c)
if [ $c -eq 0 ]; then
	if [ ! -f /var/log/idle ]; then 
		lastcheck=no
		ts=$(date +"%F %T" |date +%s)
		echo "no:$ts" >/var/log/idle
	else
		lastcheck=yes
		ts=$(date +"%F %T" |date +%s)
		ots=$(cat /var/log/idle|awk -F : '{print $2}')
		idsec=$(($ts-$ots))
		idmin=$(($idsec/60))
		if [ $idmin -gt 99 ]; then
			logger -t "IDLE SCRIPT" -i "Server is idle - Shutting Down"
			SHUT
		fi
	fi
elif [ $c -gt 0 ]; then
	rm -f /tmp/time
	for time in `w -h |awk '{print $5}' |xargs`; do 
		l="${time: -1}"
		if [ "$l" = "s" ] ; then  echo no >>/tmp/time ; continue
		elif [ "$l" = "m" ] ; then  echo yes >> /tmp/time ; continue
		else 
			t=$(echo $time |awk -F : '{print $1}')
			if [ $t -gt 59 ]; then 
				echo yes >> /tmp/time
			else
				echo no >> /tmp/time
			fi
		fi
	done
	grep no /tmp/time &>/dev/null
	if [ $? -eq 0 ]; then 
		logger -t "IDLE SCRIPT" -i "Server is not idle"
	else
		logger -t "IDLE SCRIPT" -i "Server is idle - Shutting down"
		SHUT
	fi
fi
