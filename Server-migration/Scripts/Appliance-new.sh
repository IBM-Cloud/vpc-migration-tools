#!/bin/bash

#This is the appliance script which will help to migrate IBM Cloud Classic VSI  and VMWare vm's to IBMCLOUD VPC Appliance Version2.1

#variable declaration
sshport="22"
comres="comres"
dirpath="$PWD/"
configfile="config"
srccodepath="$PWD/"
tempvarfile=".var.tmp"
linuxprecheck="linux_precheck.sh"
windowsprecheck="windows_precheck.sh"
precheckreport="reportprecheck"
cronjobscheduler="cronjobscheduler.sh"
tempalatenote="migration-appliance"

# This will hold the total number of columns of the screen
TOTAL_COLUMN=$(tput cols) 
# Total column minus 10 columns
TOTAL_COL_10=$(($TOTAL_COLUMN-10));
#-------------------------------------- Color Codes variable Starts Here  --------------------------------------------------
# The color variable Declaration. 
# These variables will declare common color codes to that will used in printing message.
RED="\033[0;31m"
LIGHT_RED="\033[1;31m"
GREEN="\033[0;32m"
LIGHT_GREEN="\033[1;32m"
YELLOW="\033[0;33m"
LIGHT_YELLOW="\033[1;33m"
BLUE="\033[0;34m"
LIGHT_BLUE="\033[1;34m"
MAGENTA="\033[0;35m"
LIGHT_MAGENTA="\033[1;35m"
CYAN="\033[0;36m"
LIGHT_CYAN="\033[1;36m"
# This variable will be used to close the color codes. This will be used to terminate the color code 
NC="\033[0m"
#--------------------------------------- Color Codes variable Ends Here  ----------------------------------------------------
# The following function will draw a line with three parameters as below:
# Arg1 = Character which will be used to draw the line. The default character is "*"
# Arg2 = This argument specify the number of line which will be drawn. The default number is 1"
# Arg3 = This argument specify the color of the character. The default color is "green"
draw_line () {
    cols=$(tput cols)
    char="*"
    rows=1
    color=$GREEN
    if [[ ! -z "$1" ]]; then
        char=$1;
    fi
    if [[ ! -z "$2" ]]; then
        rows=$2;
    fi
    if [[ ! -z $3 ]]; then
        color=$3;
    fi
    for ((j=0; j<rows; j++));
    do
        for ((i=0; i<cols; i++));
        do 
            printf "$color%s$NC" "$char"; 
        done; 
    done;
}
# The following function will be used to print any question with y/n option.
# The text will be aligned left in red color.
input () {
    printf "$YELLOW%s$NC" "$1 : "
}
# The following function will be used to print any question with y/n option.
# The text will be aligned left in red color.
question () {
    printf "$YELLOW%s$NC" "$1  [y/n]: "
}
# The following function will be used to print error message with prefix '[ERROR] '.
# The text will be aligned left in red color.
# Argument 1 = This argument specify the text to be printed.
error () {
    printf "$RED%s$NC%s\n" "[ERROR]  " "$1"
    draw_line "-"
}
# The following function will be used to print log message with prefix '[INFO] '.
# The text will be aligned left in yellow color.
# Argument 1 = This argument specify the text to be printed.
loginfo () {
    printf "$YELLOW%s$NC%s\n" "[INFO]  " "$1"
    draw_line "-"
}
# The following function will be used to print log message with prefix '[SUCCESS] '.
# The text will be aligned left in green color.
# Argument 1 = This argument specify the text to be printed.
success () {
    printf "$GREEN%s$NC%s\n" "[SUCCESS]  " "$1"
    draw_line "-"
}
# The following function will be used to print log message with postfix '[PASSED] '.
# The text will be aligned left in green color.
# Argument 1 = This argument specify the text to be printed.
passed () {
    printf "\n";
	draw_line "-" 1
	printf "$GREEN\e[1m%s\e[0m$LIGHT_GREEN%s$NC\n" "[PASSED]  " "$1"
    draw_line "-"
}
# The following function will be used to print log message with postfix '[FAILED] '.
# The text will be aligned left in red color.
# Argument 1 = This argument specify the text to be printed.
failed () {
	printf "\n"
	draw_line "-" 1
	printf "$RED\e[1m%s\e[0m$LIGHT_RED%s$NC\n" "[FAILED]  " "$1"
    draw_line "-" 1
}
#This function will login the ibmcloud cli
ibmcloudlogin(){
	regionstatus=$1
	source $dirpath$srcip/$configfile
	if [[ -f $dirpath$srcip/ibmcloudloginstatus.sh ]];then
		:
	else
		if [[ $regionstatus == "noregion" ]];then
			ibmcloud login --no-region --apikey $API_KEY 
		else
			printf "\n"
			loginfo "IBM Cloud CLI will login with region mentioned in config file"
    		ibmcloud login -r $REGION --apikey $API_KEY 
			exit_status=$?
    		if [[ $exit_status -eq 0 ]];then
				cp $srccodepath/ibmcloudloginstatus.sh $dirpath$srcip/ibmcloudloginstatus.sh
				nohup bash $dirpath$srcip/ibmcloudloginstatus.sh > $dirpath$srcip/nohupclisession.out 2>&1 &
			fi
		fi
	fi
}
#This Function will generate ssh key
generatessh(){
	source $dirpath$srcip/$tempvarfile
	if [[ -f "$dirpath/migration.key" ]];then
		question "Have you copied the ssh public key content and update in $sshfilepath file, please confirm"
		read sshres
		sed -i '/sshres/d' $dirpath$srcip/$tempvarfile
		echo "sshres=$sshres" >> $dirpath$srcip/$tempvarfile		
		if [[ "$sshres" == "y" ]];then
			sshcopyconfirm
		elif [[ "$sshres" == "n" ]];then
			question "Do you want view the ssh pub key content?"
			read sshshowres
			if [[ "$sshshowres" == "y" ]];then
			   	printf "\n\n_________________________________________________________________________________\n"
		    	printf "Please copy the ssh public key content and update in $sshfilepath (for windows - Please copy the ssh key content and update in your windows ssh folder either authorized_keys or administrators_authorized_keys) file\n"
    			printf " ____________________________________________________________________________________\n"
				cat $dirpath/migration.key.pub
				printf "\n___________________________________________________________________________________\n"
				sshcopyconfirm
			else
				printf "\n Please make sure, ssh public key content updated in $sshfilepath (for windows - Please copy the ssh key content and update in your windows ssh folder either authorized_keys or administrators_authorized_keys ) file"
			fi
		else
			failed "\n Please enter valid option"
			exit 1
		fi
	else
		ssh-keygen -t rsa -N "" -f $dirpath/migration.key
		printf "\n\n_________________________________________________________________________________\n"
		printf "Please copy the ssh public key content and update in $sshfilepath (for windows - Please copy the ssh key content and update in your windows ssh folder either authorized_keys or administrators_authorized_keys) file\n"
		printf "_____________________________________________________________________________________\n"
		cat $dirpath/migration.key.pub
		printf "\n___________________________________________________________________________________\n"
		sshcopyconfirm
	fi
}
#This Function will confirms the copy of ssh file in authorized file
sshcopyconfirm(){
	source $dirpath$srcip/$tempvarfile
	if [[ "$sshres" == "y" ]];then
		sshconfirm="y"
	else
		question "Have you copied the ssh public key content and update in $sshfilepath (for windows - Please copy the ssh key content and update in your windows ssh folder either authorized_keys or administrators_authorized_keys) file, please confirm"
		read sshconfirm
	fi
	if [[ "$sshconfirm" == "y" ]];then
		sshconcheck
	else
		failed "Please copy the SSH key file and re-run the script"
		exit 1
	fi
}
#This Function will check ssh connection
sshconcheck(){
	source $dirpath$srcip/$tempvarfile	
	loginfo "We are testing ssh connection using ssh key"
	connect_timeout=2
	ssh -q -o BatchMode=yes  -o StrictHostKeyChecking=no -o ConnectTimeout=$connect_timeout -i $dirpath/migration.key $ROOT_USERNAME@$srcip 'exit 0'
	if [ $? == 0 ];then
   		success "SSH Connection to $srcip over port $sshport is possible"
		sshconcheckstatus="success"
	else
   		error "SSH connection to $srcip over port $sshport is not possible"
		loginfo "Please make sure you have added ssh key in $sshfilepath (for windows - windows ssh folder either authorized_keys or administrators_authorized_keys)file"
		question "Do you want re-check SSH key?"
		read sshrecheckres
		if [[ "$sshrecheckres" == y ]];then
			sshconcheckstatus="re-check"
			generatessh
		else
			failed "Couldn't proceed further without proper SSH connection, Migration is Failed"
			sshconcheckstatus="failed"
			exit 1
		fi
	fi
	sed -i '/sshconcheckstatus/d' $dirpath$srcip/$tempvarfile
	echo "sshconcheckstatus=$sshconcheckstatus" >> $dirpath$srcip/$tempvarfile
}
#This function will valid all parameters in config file
getcheckvalidconfig(){
	if [[ -f "$dirpath$srcip/$configfile" ]];then
		source $dirpath$srcip/$configfile
		source $dirpath$srcip/$tempvarfile
		printf "${LIGHT_BLUE}Config file updated: ${GREEN}$dirpath$srcip/$configfile${NC}\n"
		ibmcloudlogin noregion
		setsshfilepath
		validregion
		ibmcloudlogin
		validatecosbucket
		validatecustomimagename
		validatevsiname
		validateinstanceprofile
		validatevsisshkey
		validateresourcegroup
		validatevpc
		validatesubnet
	else
		source $dirpath$srcip/$tempvarfile
		if [[ -z "$scriptruncount" ]];then
			cp $srccodepath$configfile $dirpath$srcip/$configfile
			printf "${LIGHT_RED} Configuration file is generated, please update the config file: ${GREEN}$dirpath$srcip/$configfile${NC}\n"
			echo "scriptruncount=1" >> $dirpath$srcip/$tempvarfile
			exit 0
		fi
	fi
}
#This Function will validate precheck result for linux
resultexecprechecklinux(){
	result=false
	loginfo "Checking pre-requisites for migration on source machine is in progress..."
	rm -rf $precheckreport
	sleep 40
	while [[ "$result" == false ]]
	do
		if ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "test -e /tmp/$precheckreport"; then
			scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key  $ROOT_USERNAME@$srcip:/tmp/$precheckreport $dirpath$srcip/$precheckreport
			source $dirpath$srcip/$precheckreport
			ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "cat /tmp/$precheckreport"
			if [[ "$prerequisitescheck" == "completed" ]];then
				success "Pre-requisites report is generated"
				ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "cat /tmp/$precheckreport"
				scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key  $ROOT_USERNAME@$srcip:/tmp/pc.err $dirpath$srcip/pc.out
				scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key  $ROOT_USERNAME@$srcip:/tmp/pc.err $dirpath$srcip/pc.err
				ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "sh -c 'cd /tmp; nohup ./cronjobscheduler.sh del > /dev/null 2>&1 &'"
				validateprecheckresultlinux
				result=true
			else
				scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key  $ROOT_USERNAME@$srcip:/tmp/pc.out $dirpath$srcip/pc.out
				scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key  $ROOT_USERNAME@$srcip:/tmp/pc.err $dirpath$srcip/pc.err
				ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "cat /tmp/$precheckreport"
				loginfo "In Progress... pre-requisites report not fully generated"
				result=false
			fi
		else
			loginfo "In progress... pre-requisites report not generated"
			result=false
			sleep 30
		fi
	done
}
#This fucntion will copy precheck script to linix
copyexecprechecklinux(){
		source $dirpath$srcip/$tempvarfile
		scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $srccodepath/$linuxprecheck $ROOT_USERNAME@$srcip:/tmp/
		scp -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $srccodepath/$cronjobscheduler  $ROOT_USERNAME@$srcip:/tmp/
		exit_status=$?
		if [[ $exit_status -eq 0 ]];then
			precheckcopy="success"
			if ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "test -e /tmp/$precheckreport"; then
				ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip sudo rm -rf /tmp/$precheckreport
				if ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "test -e /tmp/$precheckreport"; then
					error "Not able to delete previous precheck report file"
				else
					success "Previous precheck report file is deleted "
				fi
			fi
			ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip sudo chmod 777 /tmp/$linuxprecheck
			ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip sudo chmod 777 /tmp/$cronjobscheduler
			if [[ "$OS_NAME" == "centos" ]] || [[ "$OS_NAME" == "redhat" ]];then
				curmin=`ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip date +"%M"`
			else
				curmin=`ssh -i $dirpath/migration.key $ROOT_USERNAME@$srcip 'date +"%M"'`
			fi
			addmin="2"
			cronjobtime=`echo $(( curmin + addmin ))`
			ssh -o BatchMode=yes -o StrictHostKeyChecking=no -i $dirpath/migration.key $ROOT_USERNAME@$srcip "sh -c 'cd /tmp; nohup ./cronjobscheduler.sh add $cronjobtime > /dev/null 2>&1 &'"
			resultexecprechecklinux			
		else
			precheckcopy="failed"
		fi	
}
#This Function will validate precheck results for linux
validateprecheckresultlinux(){
	source $dirpath$srcip/$tempvarfile
	source $dirpath$srcip/$precheckreport
	if [[ "$OS_NAME" == "$osname" ]];then
		if [[ "$OS_VERSION" == "$osversion" ]];then
			:
		else
    		failed "Selected OS($OS_NAME) version($OS_VERSION) and source machine OS($osname) version($osversion) is different"
		fi
	else
		failed "Selected OS($OS_NAME) and source machine OS($osname) is different"
	fi
	grep failed $"$dirpath$srcip/$precheckreport" | awk -F= '{print $1}' > $dirpath$srcip/failedchecks
	while read -r line; do
        prechk=$line
        if [[ "$prechk" == "dhcpcheck" ]];then
            if [[ "$migratefrom" == "classic" ]] || [[ "$OS_NAME" == "ubuntu" ]];then
                precheck="passed"
            else
                precheck="failed"
                failed "$prechk is failed, please fix"
            fi
        else
            precheck="failed"
            failed "$prechk is failed, please fix"
        fi
    done < "$dirpath$srcip/failedchecks"
	if [[ -f "$dirpath$srcip/failedchecks" ]]; then
		if ! [[ -s "$dirpath$srcip/failedchecks" ]];then
			passed "Pre-requisites for migration"
			sed -i '/prerequisitestatus/d' $dirpath$srcip/$tempvarfile
			echo "prerequisitestatus=success" >> $dirpath$srcip/$tempvarfile
			migratemain
			migratemain
		elif [[ "$precheck" == "passed" ]];then
			passed "Pre-requisites for migration"
			sed -i '/prerequisitestatus/d' $dirpath$srcip/$tempvarfile
			echo "prerequisitestatus=success" >> $dirpath$srcip/$tempvarfile
			migratemain
		else
			sed -i '/prerequisitestatus/d' $dirpath$srcip/$tempvarfile
			echo "prerequisitestatus=failed" >> $dirpath$srcip/$tempvarfile
			failed "Pre-requisites for migration"
		fi
	else
		passed "Pre-requisites for migration"
		sed -i '/prerequisitestatus/d' $dirpath$srcip/$tempvarfile
		echo "prerequisitestatus=success" >> $dirpath$srcip/$tempvarfile
		migratemain
	fi
}
#windows precheck copy and validate results function
windowsprecheckcopyvalidate(){

	scp -o StrictHostKeyChecking=no windows_precheck.ps1 $ROOT_USERNAME@$srcip:/C:/Users/Administrator/Downloads
	ssh $ROOT_USERNAME@$srcip powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File C:/Users/Administrator/Downloads/windows_precheck.ps1 >/$dirpath$srcip/win_precheckreport
	awk 'FNR>=50 && FNR<=63' win_precheckreport
	grep failed $"$dirpath$srcip/win_precheckreport" | awk -F= '{print $1}' > $dirpath$srcip/failedchecks
	if [[ -f "$dirpath$srcip/failedchecks" ]]; then
		if ! [[ -s "$dirpath$srcip/failedchecks" ]]; then
			passed "Pre-requisites for migration"
			loginfo "Please do network reset and sysprep needs to be performed then re-run the appliance script again to proceed migration further"
		else
			sed -i '/prerequisitestatus/d' $dirpath$srcip/win_precheckreport
			echo "prerequisitestatus=failed" >> $dirpath$srcip/win_precheckreport
			failed "Pre-requisites for migration"
		fi
	else
		passed "Pre-requisites for migration"
		sed -i '/prerequisitestatus/d' $dirpath$srcip/win_precheckreport
		echo "prerequisitestatus=success" >> $dirpath$srcip/win_precheckreport
		migratemain
	fi
	
}
#set ssh file path
setsshfilepath(){
	if [[ "$OS_NAME" == "centos" ]] || [[ "$OS_NAME" == "redhat" ]];then
		sshfilepath="/$ROOT_USERNAME/.ssh/authorized_keys"
	else
		sshfilepath="/home/$ROOT_USERNAME/.ssh/authorized_keys"
	fi
	sed -i '/sshfilepath/d' $dirpath$srcip/$tempvarfile
	echo "sshfilepath=$sshfilepath" >> $dirpath$srcip/$tempvarfile
}
#This Function will validate region
validregion(){
	source $dirpath$srcip/$configfile
	ibmcloud regions | awk '{print $1}' > $dirpath$srcip/regionvalidfile
	sed -i '/Listing/d' $dirpath$srcip/regionvalidfile
    sed -i '/Name/d' $dirpath$srcip/regionvalidfile
    if grep -E "^$REGION$" $dirpath$srcip/regionvalidfile >/dev/null 2>&1 ;then
        passed "Region is valid"
    else
        failed "Not a valid region($REGION)"
        exit 1
    fi
}
#This Function will validate cos bucket
validatecosbucket(){
	userbucketregion=`ibmcloud cos bucket-location-get --bucket $BUCKET | grep "Region:" | awk '{print $2}'`
	userbucketclass=`ibmcloud cos bucket-location-get --bucket $BUCKET | grep "Class:" | awk '{print $2}'`
	if [[ $userbucketregion == $REGION ]];then
		if ibmcloud cos objects --bucket "$BUCKET" >/dev/null 2>&1 ;then
        	passed "Entered COS bucket($BUCKET) is used for uploading image"
    	else
           	failed "Not able to find COS object details, Please check permission"
			exit 1
    	fi
	else
		failed "Please enter COS bucket from $REGION, configured COS bucket($BUCKET) is in different region($userbucketregion)"
		exit 1
	fi
}
#This Function will validate custom name
validatecustomimagename(){
	source $dirpath$srcip/$tempvarfile
	if ibmcloud is images >/dev/null 2>&1 ;then
		:
	else
		error "Not able to find custom image details from IBM Cloud, Please check permission"
	fi
	imageexist=`ibmcloud is images | awk -v image=$CUSTOM_IMAGE_NAME '$2 == image {print $1}'`
	
	if [[ -z $imageexist && $CUSTOM_IMAGE_NAME != *['!'@#\$%^\&*()_+]* ]] ;then
			passed "Custom image name is valid"
	else
		failed "Custom image already exists with same name or contains special characters, Please enter different name"
		exit 1
	fi
	if ibmcloud cos object-head --bucket $BUCKET --key $cosobjectname > /dev/null 2>&1;then
		failed "Image Template already exists with same name in COS bucket, Please re-try with different name"
		exit 1
	fi

}
#This Function will validate vsi name
validatevsiname(){
	vsiexist=`ibmcloud is instances | awk -v instance=$VSI_NAME '$2 == instance {print $1}'`
    if [[ -z $vsiexist && $VSI_NAME != *['!'@#\$%^\&*()_+]* ]] ;then
		passed "VSI name is valid"
    else
        failed "VPC VSI already exists with same name or contains special characters, Please re-try different name"
        exit 1
    fi
}
#This Function will validate instance profile
validateinstanceprofile(){
    ibmcloud is instance-profiles | awk '{print $1}' > $dirpath$srcip/instanceprofilevalidfile
	sed -i '/Listing/d' $dirpath$srcip/instanceprofilevalidfile
	sed -i '/Name/d' $dirpath$srcip/instanceprofilevalidfile
	if grep -E "^$INSTANCE_PROFILE_NAME$" $dirpath$srcip/instanceprofilevalidfile >/dev/null 2>&1 ;then 
		passed "Instance profile is valid"
	else
		failed "Not a valid instance profile for $REGION region"
		exit 1
	fi
}
#This Function will validate ssh key
validatevsisshkey(){
    ibmcloud is keys | awk '{print $2}' > $dirpath$srcip/vsisshkeyvalidfile
    sed -i '/keys/d' $dirpath$srcip/vsisshkeyvalidfile
    sed -i '/Name/d' $dirpath$srcip/vsisshkeyvalidfile
    if grep -E "^$VSI_SSH_KEYNAME_NAME$" $dirpath$srcip/vsisshkeyvalidfile >/dev/null 2>&1 ;then
		sshkeyid=`ibmcloud is keys | awk -v sshkey=$VSI_SSH_KEYNAME_NAME '$2 == sshkey {print $1}'`
		sed -i '/sshkeyid/d' $dirpath$srcip/$tempvarfile
		echo "sshkeyid=$sshkeyid" >> $dirpath$srcip/$tempvarfile
		passed "ssh key is valid"
	else
		failed "Not a valid ssh key for $REGION region"
		exit 1
	fi
}
#This Function will validate resource group
validateresourcegroup(){
	ibmcloud resource groups | awk '{print $1}' > $dirpath$srcip/resourcegroupvalidfile
    sed -i '/Retrieving/d' $dirpath$srcip/resourcegroupvalidfile
	sed -i '/OK/d' $dirpath$srcip/resourcegroupvalidfile
    sed -i '/Name/d' $dirpath$srcip/resourcegroupvalidfile
    if grep -E "^$RESOURCE_GROUP$" $dirpath$srcip/resourcegroupvalidfile >/dev/null 2>&1 ;then
		ibmcloud resource group $RESOURCE_GROUP > $dirpath$srcip/tmprg.txt	
	    resourcegroupid=`cat $dirpath$srcip/tmprg.txt | grep "ID:" | grep -v "Account ID:" | awk '{print $2}'`
		sed -i '/resourcegroupid/d' $dirpath$srcip/$tempvarfile
		echo "resourcegroupid=$resourcegroupid" >> $dirpath$srcip/$tempvarfile
		passed "Resource is valid"
    else
        failed "Not a valid Resource Group"
		exit 1
    fi
}
#This Function will validate vpc
validatevpc(){
	ibmcloud is vpcs | awk '{print $2}' > $dirpath$srcip/vpcnamevalidfile
    sed -i '/vpcs/d' $dirpath$srcip/vpcnamevalidfile
    sed -i '/Name/d' $dirpath$srcip/vpcnamevalidfile
    if grep -E "^$VPC_NAME$" $dirpath$srcip/vpcnamevalidfile >/dev/null 2>&1 ;then
		vpcid=`ibmcloud is vpcs | awk -v vpc=$VPC_NAME '$2 == vpc {print $1}'`
		sed -i '/vpcid/d' $dirpath$srcip/$tempvarfile
		echo "vpcid=$vpcid" >> $dirpath$srcip/$tempvarfile
		passed "VPC is valid"
    else
        failed "Not a valid VPC"
		exit 1
    fi
}
#This Function will validate subnet
validatesubnet(){
	source $dirpath$srcip/$configfile
	ibmcloud is subnets | grep "$VPC_NAME" | awk '{print $2}' > $dirpath$srcip/subnetnamevalidfile
    if grep -E "^$SUBNET_NAME$" $dirpath$srcip/subnetnamevalidfile >/dev/null 2>&1 ;then
		subnetid=`ibmcloud is subnets | awk -v subnet=$SUBNET_NAME '$2 == subnet {print $1}'`
		sed -i '/subnetid/d' $dirpath$srcip/$tempvarfile
		echo "subnetid=$subnetid" >> $dirpath$srcip/$tempvarfile
		subnetregion=`ibmcloud is subnets | awk -v subnet=$SUBNET_NAME '$2 == subnet {print $9}'`
		regionzone=$(echo "$subnetregion" | grep -o -E '[0-9]+')
		if [[ ! -z $regionzone ]] ;then
			if ! [[ "$regionzone" =~ ^[0-9]+$ ]];then
				:
			fi
		else
			error "Not able find subnet region zone, Please check permission"
			exit 1
		fi
		regionzone="$REGION-$regionzone" 
		if [[ "$regionzone" ==  "$subnetregion" ]] ;then
			sed -i '/regionzone/d' $dirpath$srcip/$tempvarfile
			echo "regionzone=$regionzone" >> $dirpath$srcip/$tempvarfile
			passed "Subnet is valid"
		else
			error "Configred region($regionzone) and Subnet region($subnetregion) not same, Please check configuration file"
			failed "Not a valid subnet for $VPC_NAME VPC"
			exit 1
		fi
	fi
}
#This Function will test the connection to source machine
networkCommChk(){
	source $dirpath$srcip/$tempvarfile 
	nmap -p $sshport $srcip >> $dirpath$srcip/$comres
    if [[ `cat $dirpath$srcip/$comres | grep "Host is up"` ]];then
		loginfo  "$srcip is reachable"
        if [[ `cat $dirpath$srcip/$comres | grep "$sshport" | grep "open"` ]];then
            networkstatus="success"
			loginfo "Port $sshport is open"
			loginfo "Network Communication check is successful"
        else
			networkstatus="portnotopen"
            loginfo "Port $sshport is not open"
		    loginfo "Please install ssh and open port $sshport"
			rm -rf $dirpath$srcip/$comre
	    	exit 1
        fi
        rm -rf $dirpath$srcip/$comres
    else
		networkstatus="failed"
        loginfo "Host is not reachable"
        rm -rf $dirpath$srcip/$comres
		exit 1
    fi
	sed -i '/srcip/d' $dirpath$srcip/$tempvarfile
	sed -i '/networkstatus/d' $dirpath$srcip/$tempvarfile
	echo "srcip=$srcip" >> $dirpath$srcip/$tempvarfile
	echo "networkstatus=$networkstatus" >> $dirpath$srcip/$tempvarfile
}
#This Function will create all required directories
createdirstructure(){
	srcip=$1
	if [[ -d "$dirpath$srcip" ]];then
		source $dirpath$srcip/$tempvarfile
		question "Do you want to continue with migration [Default y]"
		read -t 10  migrationstate
		migrationstate=${migrationstate:-y}
		printf "\n"
		if [[ "$migrationstate" == "y" ]];then			
			ibmcloudlogin
			if [[ -f $dirpath$srcip/$tempvarfile ]];then
				source $dirpath$srcip/$tempvarfile
				if [[ "$prerequisitestatus" == "success" || -f $dirpath$srcip/win_precheckreport ]];then
						migratemain
				else
					connectvalidmain
				fi
			else
				connectvalidmain	
			fi
		else
			rm -rf $dirpath$srcip
			mkdir -p $dirpath$srcip
			echo "srcip=$srcip" >> $dirpath$srcip/$tempvarfile
			source $dirpath$srcip/$tempvarfile
			migratefrom
			connectvalidmain	
		fi
    else
        mkdir -p $dirpath$srcip
		echo "srcip=$srcip" > $dirpath$srcip/$tempvarfile
		source $dirpath$srcip/$tempvarfile
		migratefrom
		connectvalidmain
    fi
}
#This Function will check migration category (IBM Classic or VMware) 
migratefrom(){
	PS3='Please choose an appropriate option from above to migrate workload to IBM Cloud VPC: '
	options=("Migrate VMware Workload" "Migrate IBM Cloud Classic VSI")
	select opt in "${options[@]}" "Quit"
	do
	case $opt in
    	"Migrate VMware Workload")
			printf "\n"
        	loginfo "Migrate VMware Workload"
	    	loginfo "Please make sure that network communication between VMware and IBM Cloud VPC is enabled" 
			sed -i '/migratefrom/d' $dirpath$srcip/$tempvarfile
			echo "migratefrom=vmware" >> $dirpath$srcip/$tempvarfile
			break;;
        "Migrate IBM Cloud Classic VSI")
			printf "\n"
            loginfo "Migrating IBM Cloud Classic Workload"
			loginfo "Please make sure that network communication between IBM Cloud Classic and IBM Cloud VPC is enabled"
			sed -i '/migratefrom/d' $dirpath$srcip/$tempvarfile
			echo "migratefrom=classic" >> $dirpath$srcip/$tempvarfile
			break;;
        "Quit")
            break;;
        *) echo "invalid option selected $REPLY";;
    esac
	done
}
#This Function will create image template and export to cos and later download image to appliance for converting 
classicimageexport(){
	source $dirpath$srcip/$tempvarfile
	source $dirpath$srcip/$configfile
	if [[ -z "$vhdcosobjectname" ]];then
		imageexportname="$CUSTOM_IMAGE_NAME.vhd"
		cosobjectname="$CUSTOM_IMAGE_NAME-0.vhd"
		if ibmcloud cos object-head --bucket $BUCKET --key $cosobjectname > /dev/null 2>&1;then
			failed "Image Template already exists with same name in COS bucket, Please change custom image name"
			exit 1
		fi
		sed -i '/imageexportname/d' $dirpath$srcip/$tempvarfile
		sed -i '/cosobjectname/d' $dirpath$srcip/$tempvarfile
		echo "imageexportname=$imageexportname" >> $dirpath$srcip/$tempvarfile
		echo "cosobjectname=$cosobjectname" >> $dirpath$srcip/$tempvarfile
		classicinstanceid=`ibmcloud sl vs list | grep $srcip | awk '{print $1}'`
		sed -i '/classicinstanceid/d' $dirpath$srcip/$tempvarfile
		echo "classicinstanceid=$classicinstanceid" >> $dirpath$srcip/$tempvarfile
		loginfo "Exporting classic VSI into Image Template starting..."
		if ibmcloud sl vs capture $classicinstanceid --name $CUSTOM_IMAGE_NAME --note $tempalatenote ;then
			success "Exporting classic VSI into Image Template in started"
			sleep 1m
			imageid=`ibmcloud sl image list --private --name $CUSTOM_IMAGE_NAME | grep "System" | sort -nr | head -n 1 | awk '{print $1}'`
			while [[ -z $imageid ]];
			do
				loginfo "Exporting classic VSI into Image Template is in progress..."
				sleep 10
				imageid=`ibmcloud sl image list --private --name $CUSTOM_IMAGE_NAME | grep "System" | sort -nr | head -n 1 | awk '{print $1}'`
			done
			loginfo "Image Template ID: $imageid"
			imagetemplate="pending"
			while [[ "$imagetemplate" == "pending" ]];
			do
				if ibmcloud sl image detail $imageid | grep "TEMPLATE" > /dev/null 2>&1;then
					imagetemplate="pending"
					sleep 20
					loginfo "Exporting classic VSI into Image Template is in progress..."
				else
					imagetemplate="completed"
					imagesize=`ibmcloud sl image detail $imageid | grep "disk_space" | awk '{print $2}' | cut -f1 -d"G"`
					loginfo "Image Template Size is : $imagesize"
					passed "Exporting classic VSI into Image Template is completed"
				fi	
			done
			if ibmcloud sl image export $imageid cos://$REGION/$BUCKET/$imageexportname $API_KEY ;then
				imagecreation="success"	
				printf "\n"
			else
				imagecreation="failed"
				exit 1
			fi
			if [[ "$imagecreation" == "success" ]];then
				objectexist="absent"
				while [[ $objectexist == "absent" ]];
				do
					loginfo "Waiting for Image Template to be uploaded in COS bucket..." 
					if ibmcloud cos object-head --bucket $BUCKET --key $cosobjectname > /dev/null 2>&1;then
						cosobjectsize=`ibmcloud cos object-head --bucket $BUCKET --key $cosobjectname | grep "Object Size" | awk '{print $3}'`
						if [[ "$imagesize" == "$cosobjectsize" ]];then
							echo "objectexist=present" >> $dirpath$srcip/$tempvarfile
							echo "vhdcosobjectname=$cosobjectname" >> $dirpath$srcip/$tempvarfile
							passed "Classic Image Template export to COS bucket is successful"
							migratemain
							
						else
							sleep 1m    
            				objectexist="absent"
						fi
					else
						sleep 1m	
						objectexist="absent"
					fi
				done
			else
				failed "Image Template is uploading to COS bucket"
				exit 1
			fi
			source $dirpath$srcip/$tempvarfile
		else
			failed "Exporting classic VSI into Image Template is failed"
		fi
	fi
}
#This Function will check for vhd/vmdk file is present in the migration path or not
checkimagefileexistance(){
	imgext=$1
    count=`ls -1 $dirpath$srcip/*.$imgext 2>/dev/null | wc -l`
    if [[ $count == 1 ]];then
		if [[ "$imgext" == "vmdk" ]];then
			failed "Required both raw file (eg: vmdisk-flat.vmdk) and descriptor file (eg: vmdisk.vmdk), Please upload both vmdk file"
			sed -i '/osdiskimage/d' $dirpath$srcip/$tempvarfile
			echo "osdiskimage=absent" >> $dirpath$srcip/$tempvarfile
			exit 1
		fi
    elif [[ $count == 0 ]];then
		if [[ "$scriptruncount" == "1" ]];then
			sed -i '/scriptruncount/d' $dirpath$srcip/$tempvarfile
			if [[ "$imgext" == "vmdk" ]];then
            	loginfo "Please shutdown the VMware ESXi virtual machine and upload vmdk file of OS disk to the appliance in $dirpath$srcip path which contains two files downloaded from VMware datastore. For example: vmdisk-flat.vmdk and vmdisk.vmdk"
				sed -i '/osdiskimage/d' $dirpath$srcip/$tempvarfile
				echo "osdiskimage=absent" >> $dirpath$srcip/$tempvarfile
				exit 0
			fi 
		else
			failed "$imgext file is not present"
			if [[ "$imgext" == "vmdk" ]];then
				pkill -9 -f ibmcloudloginstatus.sh
				rm -rf $dirpath$srcip/ibmcloudloginstatus.sh
            	loginfo "Please shutdown the VMware ESXi virtual machine and upload vmdk file of OS disk to the appliance in $dirpath$srcip path which contains two files downloaded from VMware datastore. For example: vmdisk-flat.vmdk and vmdisk.vmdk"
				sed -i '/osdiskimage/d' $dirpath$srcip/$tempvarfile
				echo "osdiskimage=absent" >> $dirpath$srcip/$tempvarfile
            	exit 1
        	fi
		fi 
	elif [[ $count == 2 ]];then
		if [[ "$imgext" == "vmdk" ]];then
			if ls -1 $dirpath$srcip/*-flat.vmdk 2>/dev/null ;then
				passed "vmdk raw file is found"
				rawfile="-flat"
				vmdkfile=`ls -1 $dirpath$srcip/*$rawfile.vmdk`
				vmdkfile=`basename $vmdkfile`
				descfile=`echo $vmdkfile | sed s/"$rawfile"//`
				if ls -1 $dirpath$srcip/$descfile 2>/dev/null ;then
					passed "vmdk descriptor file is found"
					sed -i '/IMAGE_FILENAME/d' $dirpath$srcip/$configfile
        			echo "IMAGE_FILENAME=$descfile" >> $dirpath$srcip/$configfile
					sed -i '/osdiskimage/d' $dirpath$srcip/$tempvarfile
					echo "osdiskimage=present" >> $dirpath$srcip/$tempvarfile
					
				else
					failed "vmdk descriptor file is not found"
				fi
			else
				failed "vmdk raw file is not found"
			fi
		else
			failed "More number of $imgext files present, Please keep only OS disk"
			sed -i '/osdiskimage/d' $dirpath$srcip/$tempvarfile
			echo "osdiskimage=absent" >> $dirpath$srcip/$tempvarfile
        	exit 1	
		fi
    elif [[ $count -gt 2 ]];then
        failed "More number of $imgext files present, Please keep only OS disk"
		sed -i '/osdiskimage/d' $dirpath$srcip/$tempvarfile
		echo "osdiskimage=absent" >> $dirpath$srcip/$tempvarfile
        exit 1
    fi
}
#This Function is the starting point for migration
migratemain(){
	source $dirpath$srcip/$tempvarfile
	if [[ "$prerequisitestatus" == "success" || -f $dirpath$srcip/win_precheckreport ]];then
		if [[ "$migratefrom" == "classic" ]];then
        	classicimageexport
			source $dirpath$srcip/$tempvarfile
				if [[ "$objectexist" == "present" ]];then
					source $dirpath$srcip/$configfile
					bash migration.sh $dirpath$srcip $srccodepath
				else
					exit 1
				fi
    	elif [[ "$migratefrom" == "vmware" ]];then
			source $dirpath$srcip/$tempvarfile
			if [[ "$osdiskimage" == "present" ]];then
				source $dirpath$srcip/$configfile
				bash migration.sh $dirpath$srcip $srccodepath
			else
				checkimagefileexistance vmdk
			fi
    	fi
	else
		exit 1
	fi
}
#This function will connect to source machine and test ssh connection and also valid config file
connectvalidmain(){
	networkCommChk 
	source $dirpath$srcip/$tempvarfile
	getcheckvalidconfig	
	if [[ -f "$dirpath/migration.key" ]];then
		cat $dirpath/migration.key.pub
		source $dirpath$srcip/$tempvarfile
		printf "${LIGHT_BLUE}Please copy the ssh public key content and update in $sshfilepath file${NC}\n"
		question "Have you updated the ssh key in this path in $sshfilepath file, please confirm"
		read sshres
		sed -i '/sshres/d' $dirpath$srcip/$tempvarfile
		echo "sshres=$sshres" >> $dirpath$srcip/$tempvarfile		
		if [[ "$sshres" == "y" ]];then
			sshcopyconfirm
		elif [[ "$sshres" == "n" ]];then
			question "Do you want view the ssh pub key content?"
			read sshshowres
			if [[ "$sshshowres" == "y" ]];then
		    	printf "\n\n_________________________________________________________________________________\n"
		    	printf "Please copy the ssh public key content and update in $sshfilepath file\n"
    			printf " ____________________________________________________________________________________\n"
				cat $dirpath/migration.key.pub
				printf "\n___________________________________________________________________________________\n"
				sshcopyconfirm
			fi
		else
			failed "\n Please enter valid option"
			exit 1
		fi
	else
		loginfo "SSH Key will be generated for this appliance, Please make sure to remove public key from authorized file"
    	generatessh
	fi
    source $dirpath$srcip/$tempvarfile
	if [[ "$sshconcheckstatus" == "success" && "$OS_NAME" == "windows" ]];then
			windowsprecheckcopyvalidate
	elif [[ "$sshconcheckstatus" == "success" ]];then
			copyexecprechecklinux
	else
		exit 1
	fi
}
#Main Code starts here
main(){
	input "Please provide IP Address of the server to migrate"
    read srcip
    loginfo "Source machine IP is: $srcip"
	createdirstructure $srcip
}
main
