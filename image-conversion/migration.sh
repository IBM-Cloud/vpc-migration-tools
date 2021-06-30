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
# This variables are used for ibm loaction and there corresponding short keyword
sydney="au-syd"
frankfurt="eu-de"
london="eu-gb"
osaka="jp-osa"
tokyo="jp-tok"
washingtondc="us-east"
dallas="us-south"
#summary variable initialization
summary=""

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
    draw_line "-" 2 $RED
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
				ibmcloud resource group $RESOURCE_GROUP >> tmprg.txt	
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
    	passed "Config file check completed"
    else
    	failed "Config file check failed, Please check all parameters filled in config file"
		exit 1
    fi
}
# The following function will load configfile data to the script.
load_config () {
	logInfo "$CONFIGFILE loading..."
	source "$CONFIGFILE"
	check_credential
	check_config
}
# The following function will convert vhd/vmdk to qcow2 format.
convert_to_qcow2 () {
	echo "Converting to qcow2 in progress..."
    if qemu-img convert -p -f $format -O $dstformat -o cluster_size=512k $IMAGE_FILENAME $destinationfilename
    then
        failure="false"
    else
        failure="true"
    fi
    if [ $failure = false ] ; then
        passed "Image conversion successfull"
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
		read userdecision
		if [[ "$userdecision" = "y" ]];then
			rm -rf $destinationfilename
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
			passed "Image file: $objectstatus present in cos"
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
	rm -rf tmp-$0*
	mkdir -p tmp-$0/parted-files
	partfilepath="tmp-$0/"
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
        rm -rf $partfilepath
		check_cos_object
}
# The following function will create custom image with uploaded qcow2 file.
create_custom_image (){
	customimgname=$1
	imgloc=$2
	osname=$3
    RESOURCE_GROUP_ID=$4 
    tmpfilename=$5
    action=$6
	imageid=""
	retrycountcustom=0
	if [[ "$action" = "create" ]];then
		while [[ $retrycountcustom -le 10  ]] && [[ -z $imageid ]]
		do
			ibmcloud is image-create $customimgname  --file $imgloc --os-name $osname --resource-group-id $RESOURCE_GROUP_ID > $tmpfilename.txt
        	imageid=`cat $tmpfilename.txt | grep ID | awk '{print $2}'`
			retrycountcustom=$((retrycountcustom + 1))
			logInfo "Creating Custom Image in progess..."
			sleep 60
			imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`			
		done
    else
	    imageid=$action
		imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
    fi
    while [[ "$imgstatus" = "pending" ]]
    do
        logInfo "Creating Custom Image in progess..."
		logInfo "Next update in 40 Seconds"
        imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
        sleep 40
    done
    if [[ "$imgstatus" = "available" ]];then
        failure="false"
    else
        failure="true"
    fi
    if [ $failure = false ] ; then
        passed "Create Custom image successfull"
        logInfo "Custom Image Name: $customimgname"
        logInfo "Custom Image Id: $imageid"
        rm -rf $tmpfilename.txt
    else
        failed "Create Custom image failed"
    fi 
}

# The following function will create custom image with uploaded qcow2 file.
check_custom_image () {
	failure="false"
   	customimgname="${destinationfilename%.*}"
	customimgname=`basename $customimgname`	
	customimgname="${customimgname//_/-}"
	customimgname="${customimgname//./-}"
   	tmpfilename=$customimgname
	customimgname="$customimgname-$(date +%y%m%d%H%M)"
	OS_VERSION="${OS_VERSION//./-}"
	if [[ "$OS_NAME" == "redhat" ]];then
		OS_NAME="red"
	else
		dump=""	
	fi
	osname="$OS_NAME-$OS_VERSION-amd64"
	imgloc="cos://$REGION/$BUCKET/$upload_object"
	customimgname=`echo $customimgname | tr '[:upper:]' '[:lower:]'`
	osname=`echo $osname | tr '[:upper:]' '[:lower:]'`
    if [[ ! -f "$tmpfilename.txt" ]];then
        create_custom_image $customimgname $imgloc $osname $RESOURCE_GROUP_ID $tmpfilename create
    else
		question "Are you re-running the migration script after failure"
		read userinput
		if [[ "$userinput" == "y" ]];then
			imageid=`cat $tmpfilename.txt | grep ID | awk '{print $2}'`
            if [[ ! -z "$imageid" ]];then
				create_custom_image $customimgname $imgloc $osname $RESOURCE_GROUP_ID $tmpfilename $imageid
			else
				rm -rf $tmpfilename.txt
				create_custom_image $customimgname $imgloc $osname $RESOURCE_GROUP_ID $tmpfilename create
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
	if ibmcloud >/dev/null 2>&1 ;then
        failure=false
    else
        failure=true
        error "ibmcloud cli not found"
		failed "Credential Check"
		exit 1
    fi
	if [[ "$REGION" == "$credential_region" ]];then
		failure=false
	else
		failure=true
		error "Please configure ibm cloud cli login with same region as config file"
		failed "Credential Check"
		exit 1
	fi
    if ibmcloud resource groups >/dev/null 2>&1 ;then
		failure=false	
	else
		error "Not able to get Resource Group details, Please ensure to login ibmcloud cli 'ibmcloud login' and also check permission"
		failure=true
		failed "Credential Check"
		exit 1
	fi	
	if ibmcloud cos objects --bucket "$BUCKET" >/dev/null 2>&1 ;then
		failure=false
	else
		error "Not able to get COS object details, Please check permission and ibmcloud plugin installed(COS)"
        failure=true
		failed "Credential Check"
		exit 1
	fi
	if ibmcloud is images >/dev/null 2>&1 ;then
		failure=false
	else
		error "Not able to get custom image details, Please check permission and ibmcloud plugin installed(VPC)"
        failure=true
		failed "Credential Check"
		exit 1
	fi
	if [[ "$failure" == "false" ]];then
		passed "Credential Check"
	else
		failed "Credential Check"
		exit 1
	fi
}

#----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------   SCRIPT START POINT  ------------------------------------------------------------
#----------------------------------------------------------------------------------------------------------------------------
logInfo "Please Make sure Network Reset and Sysprep completed in windows machine before proceeding migration"
sleep 3s;

welcome_note "This is a Migration scritp will help to convert image, upload image to cos, creates custom image and finally create vpc gen2 vsi with custom image."
echo -e "\n"
sleep 2s;

#------------------------------------------ Check Config Starts here --------------------------------------------------------
heading "1. Checking Configuration File, IBMCloud cli and Permissions "
echo -e "\n"
load_config
echo -e "\n"
sleep 2s;
#------------------------------------------ Check Config Ends here ----------------------------------------------------------
#------------------------------------------ Image Conversion Scritp Starts here ---------------------------------------------
heading "2. Converting Image"
convert_image
echo -e "\n"
sleep 2s;
#------------------------------------------ Image Conversion Scritp Script Ends here ----------------------------------------
#------------------------------------------ Upload to COS Bucket Script Starts here -----------------------------------------
heading "3. Uploading to COS Bucket"
sleep 2s;
cos_upload_method
#----------------------------------------- Image Conversion Script Ends here ------------------------------------------------
#----------------------------------------- Create Custom Image Script Starts here -------------------------------------------
if [[ "$objectstatus" == "$upload_object" ]];then
	heading "4. Creating Custom image"
	sleep 2s;
	check_custom_image
fi
#----------------------------------------- Create Custom Image Script Ends here ---------------------------------------------
#----------------------------------------- End of the Script ----------------------------------------------------------------
welcome_note "   SUMMARY of the Pre-validated script "
printf "$summary"
footer
#----------------------------------------- End of the Script ----------------------------------------------------------------
