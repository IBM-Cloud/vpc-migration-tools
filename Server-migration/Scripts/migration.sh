#!/bin/bash 

#-------------------------------------------------------------------------------------------------------------------------
# Script Name :  migration.sh     
# Prepared By : robert.ebenezer.bhakiyaraj.s@ibm.com
# Create Date : 19 Feb 2021
# Version: 1.0
# This script will  convert images /vmdk/vhd to qcow2, upload to COS bucker, Create custom Image and create vsi with custom image
#--------------------------------------------------------------------------------------------------------------------------
### Variable Declaration & Assignment
### Configuration file name
MIGRATEPATH=$1
srccodepath=$2
#MIGRATEPATH="/data/10.45.22.50"
#srccodepath="/root/Migration-DIY-Catalog/scripts/"
CONFIGFILE="config"
source $MIGRATEPATH/$CONFIGFILE
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
# This is a status variable that will hold the success and failure of a task.
failure=false

#temporary file and directory name declaration
tempvarfile=".var.tmp"
tmpdir="$MIGRATEPATH/tmp"
customimagedetailstmp="$MIGRATEPATH/customimagedetails.tmp"
vsidetailstmp="$MIGRATEPATH/vsidetails.tmp"
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
# The following function will convert vhd/vmdk to qcow2 format.
convert_to_qcow2 () {
	echo "Converting to qcow2 is in progress..."
    if qemu-img convert -p -f $format -O $dstformat -o cluster_size=512k $MIGRATEPATH/$IMAGE_FILENAME $MIGRATEPATH/$destinationfilename
    then
		qemu-img resize $MIGRATEPATH/$destinationfilename 100G
        failure="false"
    else
        failure="true"
    fi
    if [ $failure == false ] ; then
		sed -i '/imageconversion/d' $MIGRATEPATH/$tempvarfile
		echo "imageconversion=completed" >> $MIGRATEPATH/$tempvarfile	
        passed "Image conversion is successful"
    else
        failed "Image conversion is failed"
		sed -i '/imageconversion/d' $MIGRATEPATH/$tempvarfile
		echo "imageconversion=failed" >> $MIGRATEPATH/$tempvarfile	
        exit 1
    fi
}
# The following function will check and create variables for image convertion based on format and also checks whether already exist.
convert_image () {
	failure="false"
	srcpath=`dirname "$MIGRATEPATH/$IMAGE_FILENAME"`
	srcfile=$(basename "$MIGRATEPATH/$IMAGE_FILENAME")
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
	if [[ -f $MIGRATEPATH/$destinationfilename ]] ;then
		question "File exist with same name as output file and do you want to replace(Default n )"
		read -t 10  convertuseropt
		convertuseropt=${convertuseropt:-n}
		if [[ "$convertuseropt" = "y" ]];then
			rm -rf $MIGRATEPATH/$destinationfilename
			coscheck="upload"
			convert_to_qcow2 
		else
			printf "\n"
			loginfo "Image conversion is not done"
		fi
	else
		convert_to_qcow2 
	fi
}
# The following function will upload qcow2 files to cos.
check_cos_object () {
	source $MIGRATEPATH/$tempvarfile
	if [[ "$migratefrom" == "vmware" ]];then
		upload_object=`basename $MIGRATEPATH/$destinationfilename`
		objectstatus=`ibmcloud cos objects --bucket "$BUCKET" --prefix "$upload_object" | grep "$upload_object" | awk '{print $1}'`
		if [[ "$objectstatus" == "$upload_object" ]];then
			if [[ "$convertuseropt" = "y" ]] && [[ "$coscheck" = "upload" ]];then
				loginfo "COS object will be overwritten with newly converted image"
				coscheck="noupload"
				cos_upload
			else
				passed "Image file: $objectstatus present in COS bucket"
			fi
		else
			loginfo "Image file will be uploaded to COS Bucket"
			cos_upload
		fi
	elif [[ "$migratefrom" == "classic" ]];then
		upload_object=$vhdcosobjectname
		objectstatus=`ibmcloud cos objects --bucket "$BUCKET" --prefix "$upload_object" | grep "$upload_object" | awk '{print $1}'`
		if [[ "$objectstatus" == "$upload_object" ]];then
			passed "Image file: $objectstatus is present in COS bucket"
		fi
	fi
}
#This Function will upload parts
cos_part_upload (){
	partno=$1
	file=$2
	imagename=$3
	uploadid=$4
	etag=`ibmcloud cos part-upload --bucket $BUCKET --key $imagename --upload-id $uploadid --part-number $partno --body $file | grep ETag | awk '{print $2}' | tr -d '"'`
}
#This Function will create json file
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
#This function will upload image to cos
cos_upload (){
	PARTFILESIZE="1000m"
	rm -rf $tmpdir/parted-files*
	mkdir $tmpdir/parted-files
	partfilepath="$tmpdir/"
    partfilesuffix="parted-files/part-file-"
	imagename=`basename $MIGRATEPATH/$destinationfilename`
	etagfile="etag.json"
	etagpath="$partfilepath$etagfile"
	loginfo "Splitting image file into parts is in progress..."
	nohup split -b $PARTFILESIZE $MIGRATEPATH/$destinationfilename  $partfilepath$partfilesuffix > $MIGRATEPATH/nohupsplitimage.out 2>&1 &
	splitimagepid=$!
	while [[ ! -z $splitimagepid ]];
	do
		if ps -p $splitimagepid > /dev/null 2>&1 ;then
			loginfo "Splitting image file into parts is in progress..."
			sleep 1m
		else
			splitimagepid=""
		fi
	done
	filecount=`ls $partfilepath$partfilesuffix* | wc -l`
    filecount=`echo $filecount`
	uploadid=""
	retrycountmultipartcreate=0
    while [[ -z $uploadid ]] && [[ $retrycountmultipartcreate -le 10 ]]
    do	
		if [[ $retrycountmultipartcreate -eq 0 ]];then
			loginfo "Creating multipart upload"
		else
			loginfo "Re-trying multipart upload"
		fi
		uploadid=`ibmcloud cos multipart-upload-create --bucket $BUCKET --key $imagename | grep "Upload ID" | awk '{print $3}'`
        sleep 5
		retrycountmultipartcreate=$((retrycountmultipartcreate + 1))
    done
	if [[ -z $uploadid ]];then
		pkill -9 -f ibmcloudloginstatus.sh
		rm -rf $MIGRATEPATH/ibmcloudloginstatus.sh
		error "Creating multipart upload is not successful, please try again..."
		exit 1
	else
    	loginfo "Upload ID is : $uploadid"
	fi
    partno=1
    partdetails=()
    for file in $partfilepath$partfilesuffix*
    do
        echo ""
        loginfo "Uploading Part No is : ($partno/$filecount) $file"
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
	loginfo "Existing Custom Image will be deleted and new custom image will be created with new image file"
	loginfo "Deleting Custom Image is in progress..."
	deleteimageid=$1
	ibmcloud is image-delete $deleteimageid -f
	sed -i '/imageid/d' $MIGRATEPATH/$tempvarfile
	sed -i '/customimagecreation/d' $MIGRATEPATH/$tempvarfile
	deleteimgstatus=`ibmcloud is image $deleteimageid | grep -e "Status  " | awk '{print $2}'`
	while [[ "$deleteimgstatus" = "deleting" ]]
	do
		sleep 20
		loginfo "Image deletion is in progress..."
		if ibmcloud is image $deleteimageid > /dev/null 2>&1 ;then
			deleteimgstatus=`ibmcloud is image $deleteimageid | grep -e "Status  " | awk '{print $2}'`
		else
			deleteimgstatus="deleted"
			loginfo "Existing Custom Image have been deleted"
		fi
	done
	imageid=""
}
# The following function will create custom image with uploaded qcow2 file.
create_custom_image (){
	CUSTOM_IMAGE_NAME=$1
	imgloc=$2
	osname=$3
    resourcegroupid=$4 
    action=$5
	imageid=""
	retrycountcustom=0
	source $MIGRATEPATH/$CONFIGFILE
	source $MIGRATEPATH/$tempvarfile
	if [[ "$action" = "create" ]];then
		while [[ $retrycountcustom -le 10  ]] && [[ -z $imageid ]]
		do
			if [[ $retrycountcustom -gt 0  ]];then
				loginfo "Re-trying Custom image creation"
			fi
			imgloc="cos://$REGION/$BUCKET/$cosobjectname"
			osname="$OS_NAME-$OS_VERSION-amd64"
			echo $CUSTOM_IMAGE_NAME
			echo $imgloc
			ibmcloud is image-create $CUSTOM_IMAGE_NAME  --file $imgloc --os-name $osname --resource-group-id $resourcegroupid > $customimagedetailstmp
        		imageid=`cat $customimagedetailstmp | grep ID | grep -v -E "image" | awk '{print $2}'`
			retrycountcustom=$((retrycountcustom + 1))
			loginfo "Creating Custom Image is in progress..."
			ibmcloud target -r $REGION 
			sleep 60
			imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`			
		done
    	else
	    	imageid=$action
		imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
    fi
    while [[ "$imgstatus" = "pending" ]]
    do
        loginfo "Creating Custom Image is in progress..."
		loginfo "In progress..creating Custome Image"
        imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
        sleep 40
    done
    if [[ "$imgstatus" = "available" ]];then
        failure="false"
    else
        failure="true"
    fi
    if [ $failure == false ] ; then
		sed -i '/customimagecreation/d' $MIGRATEPATH/$tempvarfile
		sed -i '/imageid/d' $MIGRATEPATH/$tempvarfile
		echo "customimagecreation=completed" >> $MIGRATEPATH/$tempvarfile
		echo "imageid=$imageid" >> $MIGRATEPATH/$tempvarfile	
        passed "Create Custom image is successful"
        loginfo "Custom Image Name: $CUSTOM_IMAGE_NAME"
        loginfo "Custom Image Id: $imageid"
        rm -rf $customimagedetailstmp
    else
		sed -i '/customimagecreation/d' $MIGRATEPATH/$tempvarfile
		echo "customimagecreation=failed" >> $MIGRATEPATH/$tempvarfile
        failed "Create Custom image is failed"
    fi 
}
# The following function will create custom image with uploaded qcow2 file.
check_custom_image () {
	source $MIGRATEPATH/$CONFIGFILE
	source $MIGRATEPATH/$tempvarfile
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
	imgloc="cos://$REGION/$BUCKET/$cosobjectname"
	CUSTOM_IMAGE_NAME=`echo $CUSTOM_IMAGE_NAME | tr '[:upper:]' '[:lower:]'`
	osname=`echo $osname | tr '[:upper:]' '[:lower:]'`
    if [[ ! -f "$customimagedetailstmp" ]] && [[ -z "$imageid" ]];then
        create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $resourcegroupid create
	elif [[ -z "$imageid" ]] && [[ "$customimagecreation" == "failed" ]];then
		create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $resourcegroupid create
	elif [[ "$convertuseropt" = "n" ]] && [[ ! -z "$imageid" ]];then
		loginfo "Existing custom image $imageid will be used for VSI creation, since qcow2 file is not converted with this execution"
		imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
		while [[ -z "$imgstatus" ]]
		do
			sleep 5
			imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
			sed -i '/imgstatus/d' $MIGRATEPATH/$tempvarfile
			echo "imgstatus=$imgstatus" >> $MIGRATEPATH/$tempvarfile
		done
	elif [[ "$customimagecreation" == "completed" ]] && [[ ! -z "$imageid" ]];then
		loginfo "Existing custom image $imageid will be used for VSI creation, since qcow2 file not converted with this execution"
		imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
		while [[ -z "$imgstatus" ]]
		do
			sleep 5
			imgstatus=`ibmcloud is image $imageid | grep -e "Status  " | awk '{print $2}'`
			sed -i '/imgstatus/d' $MIGRATEPATH/$tempvarfile
			echo "imgstatus=$imgstatus" >> $MIGRATEPATH/$tempvarfile
		done
    else
		question "Trying again the migration script after failure?(Default y )"
		read -t 10  userinput
		userinput=${userinput:-y}
		if [[ "$userinput" == "y" ]];then
			if [[ ! -z "$imageid" ]];then
				create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $resourcegroupid $imageid
			elif [[ -f "$customimagedetailstmp" ]];then
				imageid=`cat $customimagedetailstmp | grep ID | awk '{print $2}'`
				if [[ ! -z "$imageid" ]];then
					create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $resourcegroupid $imageid
				else
					rm -rf $customimagedetailstmp
					create_custom_image $CUSTOM_IMAGE_NAME $imgloc $osname $resourcegroupid create
				fi
			fi
		else
			loginfo "Please change image name and try again"
		fi
	fi
}
# The following function will check vsi creation status.
check_vsi (){
	source $MIGRATEPATH/$tempvarfile
	source $MIGRATEPATH/$CONFIGFILE
	while  [[ "$vsistatus" == "reason" ]]
	do
        vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
		sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
		echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
        sleep 10
	done
	while [[ "$vsistatus" == "starting" ]] || [[ "$vsistatus" == "pending" ]]
    do
        loginfo "Creating vsi is in progress... Status:- $vsistatus"
		vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
		while [[ -z $vsistatus ]]
		do
			sleep 10
			loginfo "Re-trying to get VSI status"
    		vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
		done
		sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
		echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
		loginfo "Next update in 40 Seconds"
    	sleep 40
   	done
    if [[ "$vsistatus" == "running" ]];then
    	failure="false"
		sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
		echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
		loginfo "Created VSI Status:- $vsistatus"
		rm -rf $vsidetailstmp
	else
		sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
		echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
    	failure="true"
	fi
	if [[ $failure == false ]] && [[ "$vsistatus" == "running" ]]; then
		loginfo "VSI Name :- $VSI_NAME"
		loginfo "VSI ID :- $vsiid"
		rm -rf $vsidetailstmp
		sed -i '/vsicreation/d' $MIGRATEPATH/$tempvarfile
		sed -i '/vsiid/d' $MIGRATEPATH/$tempvarfile
		echo "vsicreation=completed" >> $MIGRATEPATH/$tempvarfile
		echo "vsiid=$vsiid" >> $MIGRATEPATH/$tempvarfile
       	passed "Created VSI is successful"
	else
		sed -i '/vsicreation/d' $MIGRATEPATH/$tempvarfile
		echo "vsicreation=failed" >> $MIGRATEPATH/$tempvarfile
    	failed "Creating VSI is failed"
	fi
}
# The following function will create gen2 vsi with custom image.
create_vsi () {
	failure="false"	 
	source $MIGRATEPATH/$CONFIGFILE
	if [[ ! -f  "$vsidetailstmp" ]]; then
		loginfo "Creating vsi is in progress..."
		VSI_NAME=`echo $VSI_NAME | tr '[:upper:]' '[:lower:]'`
		retrycountvsi=0
		while [[ $retrycountvsi -le 10  ]] && [[ -z $vsiid ]]
		do
			if [[ $retrycountvsi -gt 0  ]];then
				loginfo "Re-trying VSI creation"
			fi
			if ibmcloud is instance-create $VSI_NAME $vpcid $regionzone $INSTANCE_PROFILE_NAME $subnetid --resource-group-id $resourcegroupid --image $imageid --keys $sshkeyid > $vsidetailstmp ;then
				sleep 10
				vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume|Network Inrerfaces" | grep -v -E "Interface|instance" | awk '{print $2}'`
				success "Creation of VSI from custom image is triggered, and VSI ID is: $vsiid"
				echo "vsiid=$vsiid" >> $MIGRATEPATH/$tempvarfile
				sleep 20	
			else
				retrycountvsi=$((retrycountvsi + 1))
				rm -rf $vsidetailstmp
			fi
			sleep 20
			if vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume|Network Inrerfaces" | grep -v -E "Interface|instance" | awk '{print $2}'` ; then
				:
			else
				loginfo "Re-trying VSI creation"
				rm -rf $vsidetailstmp
			fi
		done
		if [[ ! -z "$vsiid" ]]; then
			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			while [[ -z $vsistatus ]]
			do
				sleep 10
				loginfo "Re-trying to get VSI status"
    			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			done
			sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
			echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
			check_vsi
    	fi
	elif [[ -f  "$vsidetailstmp" ]]; then
		vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume|Network Inrerfaces" | grep -v -E "Interface|instance" | awk '{print $2}'`
		if [[ ! -z "$vsiid" ]]; then
			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			while [[ -z $vsistatus ]]
			do
				sleep 10
				loginfo "Re-trying to get VSI status"
    			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			done
			sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
			echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
			check_vsi
		elif [[ -z "$vsiid" ]]; then
			rm -rf $vsidetailstmp
			error "An error occured"
			create_vsi
    	else
			
        	failure="true"
    	fi
	else
		failure="true"
	fi
}
#This function will create temp directory
tmp_dir()
{
	if [[ -d "$tmpdir" ]];then
		failure=false
	else
		mkdir $tmpdir
	fi
}
#This function will remove temp directory
rm_tmp_dir()
{
	if [[ "$vsicreation" == "completed" ]];then
		question "$MIGRATEPATH directory will be deleted to save disk space [Default y]" 
		read -t 10  deltmp
		deltmp=${deltmp:-y}
		if [[ "$deltmp" == "y" ]];then
			rm -rf $MIGRATEPATH
		elif [[ "$deltmp" == "n" ]];then
			logInfo "$MIGRATEPATH directory will not be deleted"
		fi
	fi
}
#This function will login ibmcloud cli
ibmcloudlogin(){
	source $MIGRATEPATH/config
	if [[ -f $MIGRATEPATH/ibmcloudloginstatus.sh ]];then
		:
	else
		printf "IBMCloud CLI will be logged-in again, since existing session is expired\n"
		ibmcloud login -r $REGION --apikey $API_KEY 
		exit_status=$?
   		if [[ $exit_status -eq 0 ]];then
			cp $srccodepath/ibmcloudloginstatus.sh $MIGRATEPATH/ibmcloudloginstatus.sh
			nohup bash $MIGRATEPATH/ibmcloudloginstatus.sh > $MIGRATEPATH/nohupclisession.out 2>&1 &
		fi
	fi
}
#-----------------------------------------   SCRIPT START POINT  ------------------------------------------------------------
tmp_dir
ibmcloudlogin
source $MIGRATEPATH/$tempvarfile
#------------------------------------------ Image Conversion Script Starts here ---------------------------------------------
loginfo "Converting Image"
if [[ "$migratefrom" == "vmware" ]];then
	convert_image
	echo -e "\n"
	sleep 2;
fi
#------------------------------------------ Image Conversion Script Ends here -----------------------------------------------
#------------------------------------------ Upload to COS Bucket Script Starts here -----------------------------------------
loginfo "Uploading to COS bucket"
if [[ "$migratefrom" == "vmware" ]];then
	check_cos_object
fi
#----------------------------------------- Image Conversion Script Ends here ------------------------------------------------
#----------------------------------------- Create Custom Image Script Starts here -------------------------------------------
if [[ "$objectstatus" == "$upload_object" ]];then
	if [[ -z $imageid ]] ;then
		echo $upload_object
		loginfo "Creating custom image"
		check_custom_image
	elif [[ ! -z $imageid ]] && [[ "$convertuseropt" = "y" ]];then
		loginfo "Creating custom image"
		delete_custom_image $imageid
		check_custom_image
	elif [[ ! -z $imageid ]];then
		loginfo "Checking custom image"
		check_custom_image	
	else
		failure=false
	fi
fi
#----------------------------------------- Create Custom Image Script Ends here ---------------------------------------------
#----------------------------------------- Create VSI Script Starts here ----------------------------------------------------
source $MIGRATEPATH/$tempvarfile
if [[ "$imgstatus" = "available" ]];then
	if ! [[ -z $vsiid ]];then
		loginfo "Checking VPC GEN2 VSI with custom image(Migrated)"
		vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
		sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
		echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
		check_vsi
	elif [[ -f $vsidetailstmp ]];then
		vsiid=`cat $vsidetailstmp | grep ID | grep -v -E "Image|VPC|Resource group|Boot volume" | awk '{print $2}'`
		if [[ -z $vsiid ]];then
			rm -rf $vsidetailstmp
			loginfo "Creating VPC GEN2 VSI with custom image(Migrated)"
			create_vsi
		else
			loginfo "Checking VPC GEN2 VSI with custom image(Migrated)"
			vsistatus=`ibmcloud is instance $vsiid | grep Status | awk '{ print $2 }'`
			sed -i '/vsistatus/d' $MIGRATEPATH/$tempvarfile
			echo "vsistatus=$vsistatus" >> $MIGRATEPATH/$tempvarfile
			check_vsi
		fi
	else	
    	failure="false"
		loginfo "Creating VPC GEN2 VSI with custom image(Migrated)"
		create_vsi
	fi
else
    failure="true"
fi
#----------------------------------------- Create VSI Script Ends here ------------------------------------------------------
#----------------------------------------- End of the Script -----------------------------------------------------------------
draw_line "*" 2
display "END OF THE SCRIPT" $RED
draw_line "*" 2 $GREEN
#----------------------------------------- End of the Script ----------------------------------------------------------------
