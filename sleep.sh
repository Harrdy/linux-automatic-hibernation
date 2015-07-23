#!/bin/bash
#
# This is scheduled in CRON.  It will run every 5 minutes
# and check for inactivity.  It compares the RX and TX packets
# from 5 minutes ago to detect if they significantly increased.
# If they haven't, it will suspend the machine.
#
#       crontab -l
#       */5 * * * * /home/media/sleep.sh

DIR=/root/idle
log=$DIR/log

LIMIT_RX=4000
LIMIT_TX=4000

if [ ! -d $log ]; then
	mkdir -p $DIR
	chmod 700 $DIR
fi

# Extract the RX/TX
rx=`/sbin/ifconfig eth0 | grep -m 1 RX | cut -d: -f2 | sed 's/ //g' | sed 's/errors//g'`
tx=`/sbin/ifconfig eth0 | grep -m 1 TX | cut -d: -f2 | sed 's/ //g' | sed 's/errors//g'`

#Write Date to log
date >> $log
echo "Current Values" >> $log
echo "rx: "$rx >> $log
echo "tx: "$tx >> $log

# Check if RX/TX Files Exist
if [ -f /root/idle/rx ] || [ -f /root/idle/tx ]; then
        chmod -R 700 /root/idle/
        p_rx=`cat /root/idle/rx`  ## store previous rx value in p_rx
        p_tx=`cat /root/idle/tx`  ## store previous tx value in p_tx

        echo "Previous Values" >> $log
        echo "p_rx: "$p_rx >> $log
        echo "t_rx: "$p_tx >> $log

        echo $rx > /root/idle/rx    ## Write packets to RX file
        echo $tx > /root/idle/tx    ## Write packets to TX file

        # Calculate threshold limit
        t_rx=`expr $p_rx + $LIMIT_RX`
        t_tx=`expr $p_tx + $LIMIT_TX`

        echo "Threshold Values" >> $log
        echo "t_rx: "$t_rx >> $log
        echo "t_tx: "$t_tx >> $log

        echo " " >> $log


        if [ $rx -le $t_rx ] || [ $tx -le $t_tx ]; then  ## If network packets have not changed that much
                rm /root/idle/rx
                rm /root/idle/tx

                if [ $(ps auxwww|grep sshd:|wc -l) -gt 1 ]; then
                        if [ ! -n "$1" ]; then
                                echo "Suspend to Ram ... - force because ssh connection is established" >> $log
                                echo " " >> $log
                        else
                                echo "Suspend to Ram ... - skipping because ssh connection is established" >> $log
                                echo " " >> $log
                                exit 0
                        fi
                fi

                for disk in {a..z}
                do
                        if [ -e /dev/sd$disk ]; then
                                # Check if drive is currently spinning
                                if [ "$(hdparm -C /dev/sd$disk | grep state)" = " drive state is:  active/idle" ]; then
                                        # Check if smartctl is currently running a self test
                                        if [ $(smartctl -a /dev/sd$disk | grep -c "Self-test routine in progress") -ne 0 ]; then
                                                echo "Suspend to Ram ... - skipping because Disk Selft-test in progress" >> $log
                                                echo " " >> $log
                                                exit 0
                                        fi
                                fi
                        fi
                done

                if [ $(ps aux|grep snapraid|wc -l) -gt 1 ]; then
                        echo "Suspend to Ram ... - skipping because snapraid is running" >> $log
                        echo " " >> $log
                        exit 0
                fi

                if [ $(ps aux|grep unrar|wc -l) -gt 1 ]; then
                        echo "Suspend to Ram ... - skipping because unrar is running" >> $log
                        echo " " >> $log
                        exit 0
                fi

                echo "Suspend to Ram ..." >> $log
                echo " " >> $log

                /usr/sbin/pm-hibernate
        fi

#Check if RX/TX Files Doesn't Exist
else
        echo $rx > /root/idle/rx ## Write packets to file
        echo $tx > /root/idle/tx
        echo " " >> $log
fi

