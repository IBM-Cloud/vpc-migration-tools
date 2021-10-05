#!/bin/bash 

#-------------------------------------------------------------------------------------------------------------------------
# Script Name :  migration.sh     
# Prepared By : robert.ebenezer.bhakiyaraj.s@ibm.com
# Create Date : 19 Feb 2021
# Version: 1.0
# This script will  convert images /vmdk/vhd to qcow2, upload to COS bucker, Create custom Image and create vsi with custom image
#--------------------------------------------------------------------------------------------------------------------------
### Configuration file name
CONFIGFILE="migration.cfg"

### Variable Declaration & Assignment

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
FAIL="[ ${RED}FAILURE${NC} ]"
OK="[ ${GREEN}OK${NC} ]"
# This is a status variable that will hold the success and failure of a task.
failure=false
# This variables are used for ibm location and there corresponding short keyword
sydney="au-syd"
frankfurt="eu-de"
london="eu-gb"
osaka="jp-osa"
tokyo="jp-tok"
washingtondc="us-east"
dallas="us-south"
#summary variable initialization
summary=""

#temporary file and directory name declaration
tmpdir="tmp-$0"
customimagedetailstmp="$tmpdir/customimagedetails.tmp"
vsidetailstmp="$tmpdir/vsidetails.tmp"
### Function Declaration

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
# The following function will be used to print text in blue color.
# The text will be aligned center.
# Argument 1 = This argument specify the text to be printed.
display () {
    printf "$YELLOW%*s$NC\n" $(((${#1}+$TOTAL_COLUMN)/2)) "$1"
}
# The following function will be used to print the header section of the screen.
# With some pattern design and a message that will be displayed in the center of the screen in green color.
# The text will be aligned center.
# Argument 1 = This argument specify the text to be printed.
heading () {
    draw_line "-" 2
    echo -e "\n\n"
    draw_line "*"
    echo -e "\n"
    display "$1"
    echo -e "\n"
    draw_line "*"
} 
# The following function will be used to print the footer section of the screen.
# With some pattern design and a message that will be displayed in the center of the screen in Red color.
# The text will be aligned center.
footer () {
    echo -e "\n\n\n"
    draw_line "-" 1
    display "END OF THE SCRIPT" $RED
    draw_line "-" 2 $GREEN
    echo -e "\n\n\n"
}
# The following function will be used to print any question with y/n option.
# The text will be aligned left in red color.
question () {
    printf "$RED%s$NC" "$1  [y/n]: "
}
# The following function will be used to print error message with prefix '[ERROR] '.
# The text will be aligned left in red color.
# Argument 1 = This argument specify the text to be printed.
error () {
    printf "$RED%s$NC\n" "[ERROR] $1"
    draw_line "-"
}
# The following function will be used to print log message with prefix '[INFO] '.
# The text will be aligned left in yellow color.
# Argument 1 = This argument specify the text to be printed.
logInfo () {
    printf "$YELLOW%s$NC\n" "[INFO] $1"
    draw_line "-"
}
# The following function will be used to print log message with prefix '[SUCCESS] '.
# The text will be aligned left in green color.
# Argument 1 = This argument specify the text to be printed.
success () {
    printf "$GREEN%s$NC\n" "[SUCCESS] $1"
    draw_line "-"
}
# The following function will be used to print log message with postfix '[PASSED] '.
# The text will be aligned left in green color.
# Argument 1 = This argument specify the text to be printed.
passed () {
    printf "$1";
    printf "$GREEN\033[${TOTAL_COL_10}G%s$NC\n" "[PASSED]"
	summary="${summary}$1 $GREEN\033[${TOTAL_COL_10}G[PASSED]$NC\n"
    for ((i=0; i<TOTAL_COLUMN; i++));
    do 
       summary="$summary$GREEN-$NC"; 
    done;
    draw_line "-"
}
# The following function will be used to print log message with postfix '[FAILED] '.
# The text will be aligned left in red color.
# Argument 1 = This argument specify the text to be printed.
failed () {
    printf "$1";
    printf "$RED\033[${TOTAL_COL_10}G%s$NC\n" "[FAILED]"
	summary="${summary}$1 $RED\033[${TOTAL_COL_10}G[FAILED]$NC\n"
    for ((i=0; i<TOTAL_COLUMN; i++));
    do 
       summary="$summary$GREEN-$NC"; 
    done;
    draw_line "-" 1
}
# The following function will test the required or compatible 'Operating System' and required or compatible
# version and will print the passed or failed messages correspondingly.
# If the Operating System is not compatible it will print the error and exit the script.
check_os_distro () {
    flag=false
    # Check the OS distro and version to ensure it is supported
    if [ -f /etc/os-release ]; then
        DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        DISTRO_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
    else
        flag=true
    fi
}
# The following function will be used to print welcome text in blue color with some pattern
# The text will be aligned center.
# Argument 1 = This argument specify the text to be printed.
welcome_note () {
    echo -e "\n\n\n\n"
    draw_line "*" 2
    echo -e "\n\n"
    display "$1"
    echo -e "\n\n"
    draw_line "*" 2
}
# The following function will check configfile is filled or not.
check_config () {
	failure="false"
	logInfo "Checking $CONFIGFILE file"
	if [[ ! -z "$REGION" ]] && [[ ! -z "$BUCKET" ]] && [[ ! -z "$IMAGE_FILENAME" ]] && [[ ! -z "$RESOURCE_GROUP" ]];then 
		if [[ ! -z "$OS_NAME" ]] && [[ ! -z "$OS_VERSION" ]] ;then
            	failure="false"
				ibmcloud resource group $RESOURCE_GROUP > tmprg.txt	
	        	RESOURCE_GROUP_ID=`cat tmprg.txt | grep "ID:" | grep -v "Account ID:" | awk '{print $2}'`		
				rm -rf tmprg.txt
        else
        	failure="true"
		fi
		if [[ ! -z "$PARTFILESIZE" ]];then
			PARTFILESIZE=${PARTFILESIZE//[!0-9]/}
			if [[ "$PARTFILESIZE" -ge 10 ]] && [[ "$PARTFILESIZE" -le  1000 ]];then
				failure="false"
				PARTFILESIZE="${PARTFILESIZE}m"
			else
				PARTFILESIZE="100m"
			fi
		else
			PARTFILESIZE="100m"
		fi
	else
		failure="true"
    fi
	if [ $failure = false ] ; then
    	passed "Configuration file check completed"
    else
    	failed "Configuration file check failed, Please check all parameters filled in config file"
		exit 1
    fi
}
# The following function will load configfile data to the script.
load_config () {
	logInfo "$CONFIGFILE loading..."
	source "$CONFIGFILE"
	check_config
	check_credential
}
# The following function will convert vhd/vmdk to qcow2 format.
convert_to_qcow2 () {
	echo "Converting to qcow2 in progress..."
    if qemu-img convert -p -f $format -O $dstformat -o cluster_size=512k $IMAGE_FILENAME $destinationfilename
    then
		qemu-img resize $destinationfilename 100G
        failure="false"
    else
        failure="true"
    fi
    if [ $failure = false ] ; then
        passed "Image conversion successful"
    else
        failed "Image conversion failed"
        exit 1
    fi
}
# The following function will check and create variables for image convertion based on format and also checks whether already exist.
convert_image () {
	failure="false"
	srcpath=`dirname "$IMAGE_FILENAME"`
	srcfile=$(basename "$IMAGE_FILENAME")
	if [[ "$srcpath" == *"."* ]];then
        path=""
	else
        tmp="/" 
        path="$srcpath$tmp"
	fi
	sourcefilename="${srcfile%.*}"
	srcformat="${srcfile##*.}"
	dstformat=".qcow2"
    destinationfilename="$path$sourcefilename$dstformat"
	dstformat=`echo $dstformat |tr -d '.'`
	if [[ "$srcformat" == "vhd" ]];then
       		format="vpc"
	elif [[ "$srcformat" == "vmdk" ]];then
       		format="vmdk"
	else
    	 	failed "Not supported format"
	fi
	if [[ -f $destinationfilename ]] ;then
		question "File exist with same name as output file and do want to replace"
		read convertuseropt
		if [[ "$convertuseropt" = "y" ]];then
			rm -rf $destinationfilename
			coscheck="upload"
			convert_to_qcow2 
		else
			logInfo "Image conversion not done"
		fi
	else
		convert_to_qcow2 
	fi
}
# The following function will upload qcow2 files to cos.
check_cos_object () {
	upload_object=`basename $destinationfilename`
	objectstatus=`ibmcloud cos objects --bucket "$BUCKET" --prefix "$upload_object" | grep "$upload_object" | awk '{print $1}'`
	if [[ "$userinput" == "y" ]];then
		if [[ "$objectstatus" == "$upload_object" ]];then
			if [[ "$convertuseropt" = "y" ]] && [[ "$coscheck" = "upload" ]];then
				logInfo "COS object will be overwritten with newly converted image"
				coscheck="noupload"
				cos_upload
			else
				passed "Image file: $objectstatus present in cos"
			fi
		else
			logInfo "Image file will be uploaded to cos"
			cos_upload
		fi
	elif [[ "$userinput" == "n" ]];then
		if [[ "$objectstatus" == "$upload_object" ]];then
			passed "Image file: $objectstatus present in cos"
		else
			logInfo "Object not found in COS, Please re-run the script once image upload completed"
		fi
	fi
}
cos_upload_method () {
	question "Please confirm whether converted image to be uploaded with script"
	read userinput
	if [[ "$userinput" == "y" ]];then
		check_cos_object 
   	elif [[ "$userinput" == "n" ]];then
	   	cos_manual
	fi
}
cos_manual (){
    upload_object=`basename $destinationfilename`
    imgloc="cos://$REGION/$BUCKET/$upload_object"
    echo -e  "Please upload converted image from the following path   ${YELLOW}''$destinationfilename'' ${NC}to ${YELLOW}''$BUCKET'' ${NC}COS bucket, to proceed further \n \n ${GREEN}We suggest to use IBM Aspera connect \n \n ${NC}Refer following link for Aspera installation ${YELLOW}\n https://www.ibm.com/aspera/connect/?_ga=2.134595447.766023478.1613905997-390697858.1610435302&cm_mc_uid=45064290964216104353014&cm_mc_sid_50200000=13124331614254049945 \n"    
	question "Please confirm once upload completed"
	read cosuserupload
	if [[ "$cosuserupload" == "y" ]];then
		check_cos_object
	fi
} 
cos_part_upload (){
	partno=$1
	file=$2
	imagename=$3
	uploadid=$4
	etag=`ibmcloud cos part-upload --bucket $BUCKET --key $imagename --upload-id $uploadid --part-number $partno --body $file | grep ETag | awk '{print $2}' | tr -d '"'`
}
cos_partdetails_json (){
		partno=$1
		etag=$2
		filecount=$3
		partdetails=$4
		partdetail="{\"PartNumber\": $partno, \"ETag\": \"$etag\"}"
		if [[ "$partno" -lt "$filecount" ]];then
			partdetails+=($partdetail,)
		else
			partdetails+=($partdetail)
		fi	
}
cos_upload (){
	rm -rf $tmpdir/parted-files*
	mkdir $tmpdir/parted-files
	partfilepath="$tmpdir/"
    partfilesuffix="parted-files/part-file-"
	imagename=`basename $destinationfilename`
	etagfile="etag.json"
	etagpath="$partfilepath$etagfile"
	logInfo "Splitting image file into parts in progress..."
	split -b $PARTFILESIZE $destinationfilename  $partfilepath$partfilesuffix
	filecount=`ls $partfilepath$partfilesuffix* | wc -l`
    filecount=`echo $filecount`
	uploadid=""
	retrycountmultipartcreate=0
    while [[ -z $uploadid ]] && [[ $retrycountmultipartcreate -le 10 ]]
    do	
		if [[ $retrycountmultipartcreate -eq 0 ]];then
			logInfo "Creating multipart upload"
		else
			logInfo "Re-trying multipart upload"
		fi
		uploadid=`ibmcloud cos multipart-upload-create --bucket $BUCKET --key $imagename | grep "Upload ID" | awk '{print $3}'`
        sleep 5
		retrycountmultipartcreate=$((retrycountmultipartcreate + 1))
    done
    logInfo "Upload ID : $uploadid"
    partno=1
    partdetails=()
    for file in $partfilepath$partfilesuffix*
    do
        echo ""
        logInfo "Uploading Part No : ($partno/$filecount) $file"
        etag=""
		retrycount=0
        while [[ -z $etag ]] && [[ $retrycount -le 10 ]]
        do
            cos_part_upload $partno $file $imagename $uploadid
            sleep 2
			retrycount=$((retrycount + 1))
        done
		if [[ -z $etag ]] && [[ $retrycount -eq 10 ]];then
			exit 1
		fi
        if [[ ! -z $etag ]];then
            rm -rf $file
            cos_partdetails_json $partno $etag $filecount $partdetails
        fi
        partno=$((partno + 1))
        done
        
        echo "{\"Parts\": [${partdetails[@]}]}" > $etagpath

        ibmcloud cos multipart-upload-complete --bucket $BUCKET --key $imagename --upload-id $uploadid --multipart-upload file://$etagpath
        rm -rf $tmpdir/parted-files*
		rm -rf $tmpdir/$etagfile
		check_cos_object
}
#Delete custom image
delete_custom_image()
{
	logInfo "Existing Custom Image will be deleted and new custom image will be created with new image file"
	logInfo "Deleting Custom Image in progress..."
	deleteimageid=$1
	ibmcloud is image-delete $deleteimageid -f
	deleteimgstatus=`ibmcloud is image $deleteimageid | grep -e "Status  " | awk '{print $2}'`
	while [[ "$deleteimgstatus" = "deleting" ]]
	do
		sleep 20s
		logInfo "Image deletion in progress..."
		if ibmcloud is image $deleteimageid > /dev/null 2>&1 ;then
			deleteimgstatus=`ibmcloud is image $deleteimageid | grep -e "Status  " | awk '{print $2}'`
		else
			deleteimgstatus="deleted"
			logInfo "Existing Custom Image have been deleted"
		fi
	done
	imageid=""
}
# The following function will create custom image with uploaded qcow2 file.
create_custom_image (){
	CUSTOM_IMAGE_NAME=$1
	imgloc=$2
	osname=$3
    RESOURCE_GROUP_ID=$4 
    action=$5
	imageid=""
	retrycountcustom=0
	if [[ "$action" = "create" ]];then
		while [[ $retrycountcustom -le 10  ]] && [[ -z $imageid ]]
		do
			if [[ $retrycountcustom -gt 0  ]];then
				logInfo "Re-trying Custom image creation"
			fi
			ibmcloud is image-create $CUSTOM_IMAGE_NAME  --file $imgloc --os-name $osname --resource-group-id $RESOURCE_GROUP_ID > $customimagedetailstmp
        	imageid=`cat $customimagedetailstmp | grep ID | awk '{print $2}'`
			retrycountcustom=$((retrycountcustom + 1))
			logInfo "Creating Custom Image in progress..."
			sleep 60s
			imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`			
		done
    else
	    imageid=$action
		imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
    fi
    while [[ "$imgstatus" = "pending" ]]
    do
        logInfo "Creating Custom Image in progress..."
		logInfo "Next update in 40 Seconds"
        imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
        sleep 40s
    done
    if [[ "$imgstatus" = "available" ]];then
        failure="false"
    else
        failure="true"
    fi
    if [ $failure = false ] ; then
        passed "Create Custom image successful"
        logInfo "Custom Image Name: $CUSTOM_IMAGE_NAME"
        logInfo "Custom Image Id: $imageid"
        rm -rf $customimagedetailstmp
    else
        failed "Create Custom image failed"
    fi 
}
# The following function will create custom image with uploaded qcow2 file.
check_custom_image () {
	failure="false"
	CUSTOM_IMAGE_NAME="${CUSTOM_IMAGE_NAME//_/-}"
	CUSTOM_IMAGE_NAME="${CUSTOM_IMAGE_NAME//./-}"
	OS_VERSION="${OS_VERSION//./-}"
	if [[ "$OS_NAME" == "redhat" ]];then
		OS_NAME="red"
	else
		dump=""	
	fi
	osname="$OS_NAME-$OS_VERSION-amd64"
	imgloc="cos://$REGION/$BUCKET/$upload_object"
	CUSTOM_IMAGE_NAME=`echo $CUSTOM_IMAGE_NAME | tr '[:upper:]' '[:lower:]'`
	osname=`echo $osname | tr '[:upper:]' '[:lower:]'`
    if [[ ! -f "$customimagedetailstmp" ]] && [[ -z "$imageid" ]];then
        create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $RESOURCE_GROUP_ID create
	elif [[ "$convertuseropt" = "n" ]] && [[ ! -z "$imageid" ]];then
		logInfo "Existing custom image $imageid will be used for VSI creation, since qcow2 file not converted with this execution"
		imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
		while [[ -z "$imgstatus" ]]
		do
			sleep 5s
			imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
		done
    else
		question "Are you re-running the migration script after failure"
		read userinput
		if [[ "$userinput" == "y" ]];then
			imageid=`cat $customimagedetailstmp | grep ID | awk '{print $2}'`
            if [[ ! -z "$imageid" ]];then
				create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $RESOURCE_GROUP_ID $imageid
			else
				rm -rf $customimagedetailstmp
				create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $RESOURCE_GROUP_ID create
			fi
		else
			logInfo "Please change image name and try again"
		fi
	fi
}
# The following function will check whether region in config file and region configured with credentials.
check_credential () {
	logInfo "Validating $CONFIGFILE file and Permission"
	credential_region=`ibmcloud cos config list | grep "Default Region" | awk '{print $3}'`
	REGION=`echo "${!REGION}"`
	if [[ "$REGION" == "$credential_region" ]];then
		failure=false
	else
		failure=true
		error "Please configure ibm cloud cli login with same region as config file"
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
    if ibmcloud resource groups >/dev/null 2>&1 ;then
		failure=false	
	else
		error "Not able to get Resource Group details, Please ensure to login ibmcloud cli 'ibmcloud login' and also check permission"
		failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi	
	if [[ -f "$IMAGE_FILENAME" ]];then
		failure=false	
	else
		error "Image file doesn't exist in given path"
		failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi	
	if ibmcloud cos objects --bucket "$BUCKET" >/dev/null 2>&1 ;then
		failure=false
	else
		error "Not able to get COS object details, Please check permission and ibmcloud plugin installed(COS)"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	if ibmcloud is images >/dev/null 2>&1 ;then
		failure=false
	else
		error "Not able to get custom image details, Please check permission and ibmcloud plugin installed(VPC)"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	vpcid=`ibmcloud is vpcs | awk -v vpc=$VPC_NAME '$2 == vpc {print $1}'`
	if [[ ! -z $vpcid ]];then
		failure=false
	else
		error "VPC not found, Please check permission and vpc name"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	subnetid=`ibmcloud is subnets | awk -v subnet=$SUBNET_NAME '$2 == subnet {print $1}'` 
	if [[ ! -z $subnetid ]];then
		failure=false
	else
		error "Subnet not found, Please check permission and subnet name"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resourcek"
		exit 1
	fi
	sshkeyid=`ibmcloud is keys | awk -v sshkey=$VSI_SSH_KEYNAME_NAME '$2 == sshkey {print $1}'`
	if [[ ! -z $sshkeyid ]] ;then
		failure=false
	else
		error "SSH key not found, Please check permission and sshkey name"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	subnetregion=`ibmcloud is subnets | awk -v subnet=$SUBNET_NAME '$2 == subnet {print $9}'`
	regionzone=$(echo "$subnetregion" | grep -o -E '[0-9]+')
	if [[ ! -z $regionzone ]] ;then
		if ! [[ "$regionzone" =~ ^[0-9]+$ ]];then
			failure=false
		fi
	else
		error "Not able get region zone, Please check permission"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	regionzone="$REGION-$regionzone" 
	if [[ "$regionzone" ==  "$subnetregion" ]] ;then
		failure=false
	else
		error "Configred region($regionzone) and Subnet region($subnetregion) not same, Please check configuration file"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	imageexist=`ibmcloud is images | awk -v image=$CUSTOM_IMAGE_NAME '$2 == image {print $1}' `
	if [[ -z $imageexist ]] ;then
		failure=false
	else
		error "Custom image already exist with same name"
		question "Are you re-running the migration script after failure or aborted or with new changes"
		read userinput
		if [[ "$userinput" == "y" ]];then
			imageid=$imageexist
        else
			failure=true
			error "Please change Custom image name and re-run the migration script"
			failed "Checking Credential and Validating configuration with ibmcloud resource"
			exit 1
		fi
	fi
	vsiexist=`ibmcloud is instances | awk -v instance=$VSI_NAME '$2 == instance {print $1}'`
	if [[ -z $vsiexist ]] ;then
		failure=false
	else
		error "VSI already exist with same name"
		logInfo "Please delete existing VSI or change the VSI name in config file"
        failure=true
		failed "Checking Credential and Validating configuration with ibmcloud resource"
		exit 1
	fi
	if [[ "$failure" == "false" ]];then
		passed "Checking Credential and Validating configuration with ibmcloud resource"
	else
		failed "Checking Credential and Validating configuration with ibmcloud resources"
		exit 1
	fi
}
# The following function will check vsi creation status.
check_vsi (){
	while [[ "$vsistatus" == "starting" ]] || [[ "$vsistatus" == "pending" ]]
    do
        logInfo "Creating vsi in progress... Status:- $vsistatus"
		vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
		while [[ -z $vsistatus ]]
		do
			sleep 2s
			logInfo "Re-trying to get VSI status"
    		vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
		done
		logInfo "Next update in 40 Seconds"
    	sleep 40
   	done
    if [[ "$vsistatus" == "running" ]];then
    	failure="false"
		rm -rf $vsidetailstmp
	else
    	failure="true"
	fi
}
# The following function will create gen2 vsi with custom image.
create_vsi () {
	failure="false"	 
	if [[ ! -f  "$vsidetailstmp" ]]; then
		logInfo "Creating vsi in progress..."
		VSI_NAME=`echo $VSI_NAME | tr '[:upper:]' '[:lower:]'`
		retrycountvsi=0
		while [[ $retrycountvsi -le 10  ]] && [[ -z $vsiid ]]
		do
			if [[ $retrycountvsi -gt 0  ]];then
				logInfo "Re-trying VSI creation"
			fi
			ibmcloud is instance-create $VSI_NAME $vpcid $regionzone $INSTANCE_PROFILE_NAME $subnetid --resource-group-id $RESOURCE_GROUP_ID --image-id $imageid --key-ids $sshkeyid > $vsidetailstmp
			vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume" | awk '{print $2}'`
			retrycountvsi=$((retrycountvsi + 1))
			sleep 20s	
		done
		if [[ ! -z "$vsiid" ]]; then
			while [[ -z $vsistatus ]]
			do
				sleep 2s
				logInfo "Re-trying to get VSI status"
    			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			done
			check_vsi
    	else
        	failure="true"
    	fi
	elif [[ -f  "$vsidetailstmp" ]]; then
		vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume" | awk '{print $2}'`
		if [[ ! -z "$vsiid" ]]; then
			while [[ -z $vsistatus ]]
			do
				sleep 2s
				logInfo "Re-trying to get VSI status"
    			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			done
			check_vsi
		elif [[ -z "$vsiid" ]]; then
			rm -rf $vsidetailstmp
			error "An error occured, Please re-run the script"
    	else
			
        	failure="true"
    	fi
	else
		failure="true"
	fi
    if [[ $failure = false ]] && [[ "$vsistatus" == "running" ]]; then
		logInfo "VSI Name :- $VSI_NAME"
		logInfo "VSI ID :- $vsiid"
       	passed "Created VSI successful"
	else
    	failed "Creating VSI failed"
	fi
}
install_ibmcloud_plugin()
{
	if [[ "$1" = "cos" ]] || [[ "$1" == "all" ]]; then
		if [[ `ibmcloud plugin install cloud-object-storage -f` ]];then
			passed "ibmcloud cos plugin installation successful"
			if ibmcloud cos >/dev/null 2>&1 ;then
    			failure=false
				passed "ibmcloud cos plugin tested successful"
			else
				failed "ibmcloud cos plugin test not successful"
				exit 1
			fi
		else
			failed "ibmcloud cos plugin installation not successful"
			exit 1
		fi
	fi
	if [[ "$1" = "vpc" ]] || [[ "$1" == "all" ]]; then
		if [[ `ibmcloud plugin install vpc-infrastructure -f` ]];then
			passed "ibmcloud vpc plugin installation successful"
			if ibmcloud is >/dev/null 2>&1 ;then
    			failure=false
				passed "ibmcloud vpc plugin tested successful"
			else
				error "Please re-run the migration script after ibmcloud cli login"
				exit 1
			fi
		else
			failed "ibmcloud vpc plugin installation not successful"
			exit 1
		fi
	fi
}
install_ibmcloud_cli()
{
	if [[ `curl -fsSL https://clis.cloud.ibm.com/install/linux | sh` ]];then
		if ibmcloud >/dev/null 2>&1 ;then
    		failure=false
			passed "ibmcloud cli installation successful"
			install_ibmcloud_plugin all
		else
			failed "ibmcloud cli installation not successful"
			exit 1
		fi
	fi
}
check_requisites_ibmcloud_cli()
{
	if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]] ; then
		if rpm -q tar >/dev/null 2>&1 ; then
			failure=false
			install_ibmcloud_cli
		else 
			if [[ `yum install tar -y` ]];then
				if rpm -q tar >/dev/null 2>&1 ; then
					failure=false
					install_ibmcloud_cli
				else
					failed "tar not found"
					exit 1
				fi
			else
				failed "tar not installed"
				exit 1
			fi
		fi
	elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]]; then
		packstatus=`dpkg --get-selections | grep "^tar" | awk '{print $2}'`
	    if [[ "$packstatus" = "install" ]]; then
			packstatus=""
			packstatus=`dpkg --get-selections | grep "^curl" | awk '{print $2}'`
			if [[ "$packstatus" = "install" ]]; then
				failure=false
				install_ibmcloud_cli
			else
				if [[ `apt-get install curl -y` ]];then
					packstatus=""
					packstatus=`dpkg --get-selections | grep "^curl" | awk '{print $2}'`
					if [[ "$packstatus" = "install" ]]; then
						logInfo "Installed curl"
						failure=false
						install_ibmcloud_cli
					else
						failed "curl not found"
						exit 1
					fi
				else
					failed "curl not installed"
					exit 1
				fi
			fi
		else 
			if [[ `apt-get install tar -y` ]];then
				packstatus=`dpkg --get-selections | grep "^tar" | awk '{print $2}'`
	        	if [[ "$packstatus" = "install" ]]; then
					logInfo "Installed tar"
					packstatus=""
					packstatus=`dpkg --get-selections | grep "^curl" | awk '{print $2}'`
					if [[ "$packstatus" = "install" ]]; then
						failure=false
						install_ibmcloud_cli
					else
						if [[ `apt-get install curl -y` ]];then
							packstatus=""
							packstatus=`dpkg --get-selections | grep "^curl" | awk '{print $2}'`
							if [[ "$packstatus" = "install" ]]; then
								logInfo "Installed curl"
								failure=false
								install_ibmcloud_cli
							else
								failed "curl not found"
								exit 1
							fi
						else
							failed "curl not installed"
							exit 1
						fi
					fi
				else
					failed "tar not found"
					exit 1
				fi
			else
				failed "tar not installed"
				exit 1
			fi
		fi	
	elif [[ `sw_vers | grep "mac"` ]];then
		if [[ `curl -fsSL https://clis.cloud.ibm.com/install/osx | sh` ]];then
			if ibmcloud >/dev/null 2>&1 ;then
    			failure=false
				passed "ibmcloud cli installation successful"
				install_ibmcloud_plugin all
			else
				failed "ibmcloud cli installation not successful"
				exit 1
			fi
		fi
	else
		failed "Not supported os for migration script, so ibmcloud cli installation not successful"
		exit 1
	fi
	
}
install_qemu()
{
	if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
	    if [[ `yum update -y && yum -y install qemu-kvm` ]];then
			if rpm -q qemu-kvm >/dev/null 2>&1 ; then
				if which qemu-img >/dev/null 2>&1 ;then
	    			failure=false
					logInfo "Installation successful"
			 		passed "Qemu-kvm installed"
				else 
            		failed "Qemu-kvm installation failed"
					exit 1
				fi
			else
				failed "Qemu-kvm installation failed"
				exit 1
			fi
		else 
            failed "Qemu-kvm installation failed"
			exit 1
		fi
	elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
        if [[ `apt-get update -y && apt-get install qemu-utils -y` ]];then
            packstatus=`dpkg --get-selections | grep qemu-utils | awk '{print $2}'`
	        if [[ "$packstatus" = "install" ]]; then
				if which qemu-img >/dev/null 2>&1 ;then
		        	logInfo "Installation successful"
			 		passed "Qemu-utils installed"
				else 
            		failed "Qemu-utils installation failed"
					exit 1
				fi
            else 
                failed "Qemu-utils installation failed"
				exit 1
			fi
		else 
            failed "Qemu-utils installation failed"
			exit 1
		fi
	elif [[ `sw_vers | grep "mac"` ]];then
		if [[ `brew install qemu` ]];then
			if which qemu-img >/dev/null 2>&1 ;then
				logInfo "Installation successful"
				passed "Qemu installed"
			else 
            	failed "Qemu installation failed"
				exit 1
			fi
        else 
            failed "Qemu installation failed"
			exit 1	
		fi
	fi
}
check_requisite_migration_script()
{
	check_os_distro
	if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
		if rpm -q qemu-kvm >/dev/null 2>&1 ; then
			if which qemu-img >/dev/null 2>&1 ;then
	    		failure=false
			fi
    	else
			install_qemu   
    	fi
	elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
		packstatus=`dpkg --get-selections | grep qemu-utils | awk '{print $2}'`
	    if [[ "$packstatus" = "install" ]]; then
			if which qemu-img >/dev/null 2>&1 ;then
				failure=false
			fi
    	else
			install_qemu   
    	fi
	elif [[ `sw_vers | grep "mac"` ]];then
		if which qemu-img >/dev/null 2>&1 ;then
			logInfo "Installation successful"
			passed "Qemu-kvm installed"
		else 
        	failed "Qemu-kvm installation failed"
			exit 1
		fi
	fi
	if ibmcloud >/dev/null 2>&1 ;then
        failure=false
    else
		check_requisites_ibmcloud_cli
    fi
	if ibmcloud plugin list | grep cloud-object-storage >/dev/null 2>&1 ;then
		if ibmcloud cos >/dev/null 2>&1 ;then
        	failure=false
			passed "ibmcloud cos plugin tested successful"
		else
			failed "ibmcloud cos plugin test not successful"
		fi
    else
		install_ibmcloud_plugin cos
    fi
	if ibmcloud plugin list | grep vpc-infrastructure >/dev/null 2>&1 ;then
		if ibmcloud is >/dev/null 2>&1 ;then
        	failure=false
			passed "ibmcloud vpc plugin tested successful"
		else
			error "Please re-run the migration script after ibmcloud cli login"
			failed "ibmcloud vpc plugin test not successful"
			exit 1
		fi
    else
		install_ibmcloud_plugin vpc
    fi
}
tmp_dir()
{
	if [[ -d "$tmpdir" ]];then
		failure=false
	else
		mkdir $tmpdir
	fi
}
rm_tmp_dir()
{
	if [ -d "$tmpdir" ]; then
		if [ "$(ls -A $tmpdir)" ]; then
     		tmp=false
			if [[ -f "$customimagedetailstmp" ]]; then
				imageid=`cat $customimagedetailstmp | grep ID | awk '{print $2}'`
				if [[ -z "$imageid" ]];then
					rm -rf $customimagedetailstmp
				fi
			fi
			if [[ -f "$vsidetailstmp" ]]; then
				vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume" | awk '{print $2}'`
				if [[ -z "$vsiid" ]];then
					rm -rf $vsidetailstmp
				fi
			fi
			if [ "$(ls -A $tmpdir)" ]; then
				rm -rf $tmpdir
			fi
		else
    		rm -rf $tmpdir
		fi
	else
		tmp=false
fi
}
#----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------   SCRIPT START POINT  ------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------
heading "Starting Migration Script"
draw_line "-" 1
logInfo "Please Make sure Network Reset and Sysprep completed in windows machine before proceeding migration"
sleep 3s;

welcome_note "This is a Migration script will help to convert image, upload image to cos, creates custom image and finally create vpc gen2 vsi with custom image."
echo -e "\n"
sleep 2s;
#------------------------------------------ Check migration script pre-requisites Starts here -------------------------------
heading "1. Checking migration script pre-requisites"
check_requisite_migration_script
sleep 2s;
#------------------------------------------ Check migration script pre-requisites Ends here ---------------------------------
#------------------------------------------ Check Configuration Starts here --------------------------------------------------------
heading "2. Checking Configuration File and Permissions "
echo -e "\n"
load_config
echo -e "\n"
sleep 2s;
#------------------------------------------ Check Configuration Ends here ----------------------------------------------------------
tmp_dir
#------------------------------------------ Image Conversion Script Starts here ---------------------------------------------
heading "3. Converting Image"
convert_image
echo -e "\n"
sleep 2s;
#------------------------------------------ Image Conversion Script Ends here -----------------------------------------------
#------------------------------------------ Upload to COS Bucket Script Starts here -----------------------------------------
heading "4. Uploading to COS Bucket"
sleep 2s;
cos_upload_method
#----------------------------------------- Image Conversion Script Ends here ------------------------------------------------
#----------------------------------------- Create Custom Image Script Starts here -------------------------------------------
if [[ "$objectstatus" == "$upload_object" ]];then
	if [[ -z $imageid ]] ;then
		heading "5. Creating Custom image"
		sleep 2s;
		check_custom_image
	elif [[ ! -z $imageid ]] && [[ "$convertuseropt" = "y" ]];then
		heading "5. Creating Custom image"
		sleep 2s;
		delete_custom_image $imageid
		sleep 2s;
		check_custom_image
	elif [[ ! -z $imageid ]];then
		heading "5. Checking Custom image"
		sleep 2s;
		check_custom_image	
	else
		failure=false
	fi
fi
#----------------------------------------- Create Custom Image Script Ends here ---------------------------------------------
#----------------------------------------- Create VSI Script Starts here ----------------------------------------------------
if [[ "$imgstatus" = "available" ]];then
	if [[ -f $vsidetailstmp ]];then
		vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume" | awk '{print $2}'`
		if [[ -z $vsiid ]];then
			rm -rf $vsidetailstmp
			heading "6. Creating VPC GEN2 VSI with Custom image(Migrated)"
			create_vsi
		else
			heading "6. Checking VPC GEN2 VSI with Custom image(Migrated)"
			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			check_vsi
		fi
	else	
    	failure="false"
		heading "6. Creating VPC GEN2 VSI with Custom image(Migrated)"
		sleep 2s;
		create_vsi
	fi
else
    failure="true"
fi
#----------------------------------------- Create VSI Script Ends here ------------------------------------------------------
#----------------------------------------- End of the Script ----------------------------------------------------------------
welcome_note "   Summary of the migration script "
printf "$summary"
rm_tmp_dir
footer
#----------------------------------------- End of the Script ----------------------------------------------------------------