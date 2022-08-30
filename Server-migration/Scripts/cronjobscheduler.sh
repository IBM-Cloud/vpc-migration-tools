#!/bin/bash

addcronjob(){
    cronjobtime=$1
    sudo crontab -l > cron_bkp
    sudo echo "$cronjobtime * * * * bash /tmp/linux_precheck.sh > /tmp/pc.out 2> /tmp/pc.err < /dev/null 2>&1 &" >> cron_bkp
    sudo crontab cron_bkp
    sudo rm cron_bkp
	touch /tmp/cronadded
}
delcronjob(){
    sudo crontab -l > cron_bkp
    sudo sed -i '/linux_precheck.sh/d' cron_bkp
    sudo crontab cron_bkp
    sudo rm cron_bkp
}
if [[ "$1" == "add" ]];then
    addcronjob $2
elif [[ "$1" == "del" ]];then
    delcronjob
fi

