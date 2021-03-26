#!/bin/bash 

######################################################################################################
# Script Name :  precheck.sh     
# Create Date : 02 Nov 2020
# Version: 1.0
# This is a rhel rhel_precheck script to ensure the system meets the minimum requirement for VPC.  This script will check the OS and minimum supported version,
# cloud-init, virtio drivers and FileSystem check.
#
# If it will not locate the cloud init it will install or will update the missing configuration.
######################################################################################################



### Varilable Declaration & Assignment
# This will hold the total number of columns of the screen
###
TOTAL_COLUMN=$(tput cols) 

### Varilable Declaration & Assignment
# Total column minus 10 columns
###
TOTAL_COL_10=$(($TOTAL_COLUMN-10));

### Varilable Declaration & Assignment
# The minimum cloud init virsion supported by this script
###
CLOUD_INIT_MINIMUM="0.7.9"


### Varilable Declaration & Assignment
# Type: Array
# Kernal parameters
###
CMDS=(
    "nomodeset"
    "nofb"
    "vga=normal"
    "console=ttyS0"
)

### Varilable Declaration & Assignment
# Type: Array
# Boot Config Drivers
###
BOOT_CONFIG_DRIVERS=(
    "VIRTIO_BLK"
    "VIRTIO_NET"
)

### Varilable Declaration & Assignment
# Type: Array
# Virtio Drivers
###
INITRAMFS_DRIVERS=(
    "VIRTIO"
    "virtio.ko"
    "virtio_pci"
    "virtio_ring"
)

############################################# Color Codes variable Starts Here  ##############################################
### Varilable Declaration & Assignment
# The color variable declare. 
# These variable will declare common color codes to that will used in printing message.
### 
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

### Varilable Declaration & Assignment
# This variable will be used to close the color codes. This will be used to ternminate the color code 
###
NC="\033[0m"

############################################# Color Codes variable Starts Here  ##############################################

FAIL="[ ${RED}FAILURE${NC} ]"
OK="[ ${GREEN}OK${NC} ]"


### Varilable Declaration & Assignment
# Required Operating System. This script will only work on the Rhel
###
REQ_OS='rhel'


### Varilable Declaration & Assignment
# Required Operating System Minimum Version. This script will only work on version 7 and above.
###
REQ_OS_VER='7'


### Varilable Declaration & Assignment
# This is a status variable that will hold the success and failure of a task.
###
failure=false


### Varilable Declaration & Assignment
# Type: Array
# List of Checks. This variable will hold the number of check the script will perform.
###
declare -A TASKS=(
    [os_version]="Operating System & Version Check"
    [cloud_init]="Cloud Init & Configuration Check"
    [virtio_driver]="Virtio drivers Check"
    [fs_tab]="FS Tab Check"
)

### Function Declaration
# The following function will be used to print the check list.
#
show_checklist() {
    index=1
    for key in "${!TASKS[@]}";
    do
        echo -e "${GREEN}$index. ${TASKS[$key]}${NC}"
        ((index++))
    done

}

### Function Declaration
# The following function will draw a line with three parameters as below:
#
# Arg1 = Character which will be used to draw the line. The default character is "*"
# Arg2 = This argument specify the number of line which will be drawn. The default number is 1"
# Arg3 = This argument specify the color of the character. The default color is "green"
##
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

### Function Declaration
# The following function will be used to print text in specifed color.
# The text will be aligned left.
# Argument 1 = This argument specify the text to be printed.
# Argument 2 = This argument specify the color of the character. The default color is "cyan"
##
note () {    
    if [[ ! -z "$2" ]]; then
        printf "$2%s$NC\n" "$1"
    else 
        printf "$CYAN%s$NC\n" "$1"
    fi
    
}

### Function Declaration
# The following function will be used to print text in blue color.
# The text will be aligned center.
# Argument 1 = This argument specify the text to be printed.
##
note_center () {
    printf "$BLUE%*s$NC\n" $(((${#1}+$TOTAL_COLUMN)/2)) "$1"
}

### Function Declaration
# The following function will be used to print the header section of the screen.
# With some pattern dessign and a message that will be displayed in the center of the screen in green color.
# The text will be aligned center.
# Argument 1 = This argument specify the text to be printed.
##
heading () {
    draw_line "-" 2
    echo -e "\n\n"
    draw_line "*"
    echo -e "\n"
    note_center "$1"
    echo -e "\n"
    draw_line "*"
    # echo -e "\n\n"
} 

### Function Declaration
# The following function will be used to print the footer section of the screen.
# With some pattern dessign and a message that will be displayed in the center of the screen in Red color.
# The text will be aligned center.
##
footer () {
    echo -e "\n\n\n"
    draw_line "-" 1
    note_center "END OF THE SCRIPT" $RED
    draw_line "-" 2 $RED
    echo -e "\n\n\n"
}

### Function Declaration
# The following function will be used to print any question with y/n option.
# The text will be aligned left in red color.
##
question () {
    printf "$RED%s$NC" "$1  [y/n]: "
}

### Function Declaration
# The following function will be used to print error message with prefix '[ERROR] '.
# The text will be aligned left in red color.
# Argument 1 = This argument specify the text to be printed.
##
error () {
    printf "$RED%s$NC\n" "[ERROR] $1"
    draw_line "-"
}

### Function Declaration
# The following function will be used to print log message with prefix '[INFO] '.
# The text will be aligned left in yellow color.
# Argument 1 = This argument specify the text to be printed.
##
loginfo () {
    printf "$YELLOW%s$NC\n" "[INFO] $1"
    draw_line "-"
}

### Function Declaration
# The following function will be used to print log message with prefix '[SUCCESS] '.
# The text will be aligned left in green color.
# Argument 1 = This argument specify the text to be printed.
##
success () {
    printf "$GREEN%s$NC\n" "[SUCCESS] $1"
    draw_line "-"
}

### Function Declaration
# The following function will be used to print log message with postfix '[PASSED] '.
# The text will be aligned left in green color.
# Argument 1 = This argument specify the text to be printed.
##
passed () {
    printf "$1";
    printf "$GREEN\033[${TOTAL_COL_10}G%s$NC\n" "[PASSED]"
    draw_line "-"
}

### Function Declaration
# The following function will be used to print log message with postfix '[FAILED] '.
# The text will be aligned left in red color.
# Argument 1 = This argument specify the text to be printed.
##
failed () {
    printf "$1";
    printf "$RED\033[${TOTAL_COL_10}G%s$NC\n" "[FAILED]"
    draw_line "-" 1
}

### Function Declaration
# The following function will be used to print welcome text in blue color with some pattern
# The text will be aligned center.
# Argument 1 = This argument specify the text to be printed.
##
welcome_note () {
    echo -e "\n\n\n\n"
    draw_line "*" 2
    echo -e "\n\n"
    note_center "$1"
    echo -e "\n\n"
    draw_line "*" 2
}

### Function Declaration
# The following function will be used to compare two version and will return the 0, 1 and 2 status code.
# Argument 1 = Version 1 (Installed Version)
# Argument 2 = Version 2 (Required Version)
######### Return ########
# Status Code 0: [PASSED] The version is equal to Required version
# Status Code 1: [PASSED] The version is greater than the required version.
# Status Code 2: [FAILED] The version is less than the required version.
##
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            ver2[i]=0
        fi
        if [[ 10#${ver1[i]} > 10#${ver2[i]} ]]
        then
            return 1
        fi
        if [[ 10#${ver1[i]} < 10#${ver2[i]} ]]
        then
            return 2
        fi
    done
    return 0
}

### Function Declaration
# The following function will test the required or compatible 'Operating System' and required or compatible
# version and will print the passed or failed messages correspondigly.
# If the Operating System is not compatible it will print the error and exit the script.
##

check_os_distro () {
    heading "1. Operating System & Version Check"

    # Check the OS distro and verion to ensure it is supported
    if [ -f /etc/os-release ]; then
        DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        DISTRO_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
        dismsg="OS Check: Installed OS is ${DISTRO^^} and required OS is ${REQ_OS^^}"
        vermsg="OS Version Check: Installed OS Version is ${DISTRO_VERSION^^} and required version is >= ${REQ_OS_VER}"
        if [ $DISTRO = $REQ_OS ]; then
            passed "$dismsg"
            vercomp $DISTRO_VERSION $REQ_OS_VER
            if [ $? =  2 ]; then
                failed "$vermsg"
                error "This version is not supported by the script. The minimum supported version is ${REQ_OS_VER}"
                footer
                exit
            else
                passed "$vermsg"
            fi
        else
           failed "$dismsg"
           error "This Operating System is not supported by this script."
           footer
           exit
        fi
        passed "1. Operating System & Version Check"
    else
        failed "1. Operating System & Version Check"
    fi

    echo -e "\n\n"

}


### Function Declaration
# The following function will check Kernal parameters. 
# If any kernal parameters are missing then it will print error message for the missing parameter
# and will print the passed or failed messages correspondigly.
##
check_kernal_param () {
    sleep 2s
    flag=false
    cmdline=`cat /proc/cmdline 2> /dev/null`
    for i in "${CMDS[@]}"
    do
        if [[ $cmdline != *$i* ]]; then
            flag=true
            echo -e "${FAIL} Missing kernel parameter ${i}"
        fi
    done

    if [ $flag = true ] ; then
        failure=true
        failed "(i) Kernal Parameters."
    else
        passed "(i) Kernal Parameters."
    fi

}

### Function Declaration
# The following function will check Virtio Drivers. 
# If any vertio drivers are missing then it will print error message for the missing parameter
# and will print the passed or failed messages correspondigly.
##
check_virtio_drivers () {
    # Check kernel for virtio drivers and whether or not it is a module
    sleep 2s
    module=false
    boot_config=`grep -i virtio /boot/config-$(uname -r) 2> /dev/null`
    for i in "${BOOT_CONFIG_DRIVERS[@]}"
    do
        if [[ $boot_config = *$i=m* ]]; then
            module=true
        elif [[ $boot_config != *$i=y* ]]; then
            failure=true
            failed "Missing virtio driver ${i}"
        fi
    done
    if [ $failure = true ] ; then
        failure=true
        failed "(ii) Virtio Drivers."
    else
        passed "(ii) Virtio Drivers."
    fi
}

### Function Declaration
# The following function will check initfs and initrd. 
# If any vertio drivers are missing then it will print error message for the missing parameter
# and will print the passed or failed messages correspondigly.
##
check_initfs_initrd () {
    # Check initramfs or initrd for required modules
    if [ $module = true ] ; then
        initramfs=`lsinitrd /boot/initramfs-$(uname -r).img 2> /dev/null | grep virtio`
        if [ $? -ne 0 ]; then
            initramfs=`lsinitramfs /boot/initrd.img-$(uname -r) 2> /dev/null | grep virtio`
        fi
        for i in "${INITRAMFS_DRIVERS[@]}"
        do
            if [[ ${initramfs,,} != *${i,,}* ]]; then
                failure=true
                failed "Missing ${i,,} in temporary root filesystem of initramfs or initrd"
            fi
        done
        if [ $failure = true ] ; then
            failure=true
            failed "(iii) INIT RD/FS Modules."
        else
            passed "(iii) INIT RD/FS Modules."
        fi
    fi
}

### Function Declaration
# The following function will check cloudinit installation and configuration. 
# If it is not installed then it will install cloud init. if some configurations are missing then 
# it will print error message for the missing configurations and will fix. If cloud init version is less than the 
# required one then it will print error message to upgrade the cloud init and exit.
##
check_cloud_init (){
    cloudInitFlag=false
    # Determine if cloud-init is installed and its filepath
    cloud_init_status=`systemctl cat cloud-init 2>&1`
    if [ $? -eq 0 ]; then
        cloud_init=`[[ $cloud_init_status =~ "ExecStart="([^[:space:]]+)[[:space:]]* ]] && echo ${BASH_REMATCH[1]}`
        cloud_init_version=`${cloud_init} --version 2>&1 | cut -d' ' -f2 | cut -d'-' -f1`
    fi
    
    # Check that cloud-init is installed and meets the minimum version requirement
    if [ -z "$cloud_init_version" ]; then
        cloudInitFlag=true
        failed "Cloud Init is not installed.";

        loginfo "Installing cloud-init and configuring it." 
        
        yum install cloud-init -y
        if [[ $? -eq 0 ]]; then
            ################################## Setting the Cloud Init Configuration ##############################
            if [ -f /etc/cloud/cloud.cfg ]; then
                sed -i '/ - scripts-user/a\ - scripts\-vendor' /etc/cloud/cloud.cfg
                sed -i '/disable_vmware_customization: false/a\\ndatasource_list:["NoCloud","ConfigDrive"]' /etc/cloud/cloud.cfg
            fi
            draw_line "-"
            draw_line "-"
            cloudInitFlag=false
            success "Cloud-Init has been installed and configured."
        else
            draw_line "-"
            draw_line "-"
            error "Not able to install cloud-init."
        fi
    else
        errorFlag=false
        vercomp $cloud_init_version $CLOUD_INIT_MINIMUM
        res=$?
    
        if [ $res -eq  2 ]; then
            failed "Cloud-init version check"
            error "Cloud-init version ${CLOUD_INIT_MINIMUM} or greater is required"
            cloudInitFlag=true
        fi
    
        ci_ds_config=`grep -i "^datasource_list" /etc/cloud/cloud.cfg 2> /dev/null`
        if [[ -z $ci_ds_config ]]; then
            cloudInitFlag=true
            failed "Cloud-init Config: \"NoCloud\" and \"ConfigDrive\" configurations are not found in the datasource_list of \"/etc/cloud/cloud.cfg\""
            loginfo "Fixing the \"NoCloud\" and \"ConfigDrive\" configurations. Please wait."
            sed -i '/system_info:/i\\ndatasource_list:["NoCloud","ConfigDrive"]\n\n' /etc/cloud/cloud.cfg
        fi

        ci_ds_config=`grep -i "^datasource_list" /etc/cloud/cloud.cfg 2> /dev/null`
        if [[ ! -z $ci_ds_config && $ci_ds_config != *NoCloud* || $ci_ds_config != *ConfigDrive* ]]; then

            failed "Cloud-init Config: \"NoCloud\" and \"ConfigDrive\" configurations are not found in the datasource_list of \"/etc/cloud/cloud.cfg\""
            loginfo "Fixing the \"NoCloud\" and \"ConfigDrive\" configurations. Please wait."
            cloudInitFlag=true

            question "To fix \"NoCloud\" and \"ConfigDrive\" configurations we need to delete the existing datasource configuration. Do you want to proceed?"
            read userInput
            draw_line "-"

            if [[ $userInput = "y" ]]; then
                sed -i.bak 's/.*datasource_list.*//g' /etc/cloud/cloud.cfg
                success "We have deleted the datasource_list configuration from /etc/cloud/cloud.cfg"
            elif [[ $userInput = "n" ]]; then
                error "You need to do the \"NoCloud\" and \"ConfigDrive\" configuration manually. Exiting the script."
                exit;
            fi
        else 
            passed "Cloud-init Config: \"NoCloud\" and \"ConfigDrive\" configurations are found "
        fi

        ci_vendor_config=`grep -i "scripts\-vendor" /etc/cloud/cloud.cfg 2> /dev/null`
        if [[ $ci_vendor_config != *scripts\-vendor* ]]; then
            failed "Cloud-init Config Check: Module \"scripts-vendor\" is missing in cloud_final_modules of \"/etc/cloud/cloud.cfg\""
            cloudInitFlag=true

            loginfo "Fixing scripts-vendor configuration. Please wait."
            if [ -f /etc/cloud/cloud.cfg ]; then
                sed -i '/ - scripts-user/a\ - scripts\-vendor' /etc/cloud/cloud.cfg
            fi
            success "scripts-vendor configuration has been fixed."
        else
            passed "Cloud-init Config Check: Module \"scripts-vendor\" is found."
        fi
    fi
    cldinit="Cloud Init & Configuration Check";
    if [ $cloudInitFlag = false ]; then 
        passed "$cldinit"
    else 
        failed "$cldinit"
    fi
    echo -e "\n\n"

}

### Function Declaration
# The following function will check for the secondary drives that is not having 'nofail' option in
# /ets/fstab configuration file. It will update the configuration to have the 'nofail' option in it.
##
check_nofail_secondry () {
    failure=false
    secondary_volumes=($(cat /etc/fstab | grep -v ^\# | awk '$2 != "/" && $2 != "/boot" && $3 != "swap"  {print $1}'));
    if [ -z $secondary_volumes ]; then
        loginfo "There is no secondary volume attached with this instance"
        passed "FS Tab: Secondary Volume is not present"
    else
        # Ensure secondary drives in /etc/fstab has 'nofail' option
        fail_mounts=($(cat /etc/fstab | grep -v ^\# | awk '$2 != "/" && $2 != "/boot" && $3 != "swap" && $4 !~ "nofail" {print $1}'))
        for i in "${fail_mounts[@]}"
        do
            failure=true
            mark=$i
            failed "Mount $mark does not has 'nofail' option in /etc/fstab"
            loginfo "Fixing: Adding nofail option in /etc/fstab for $mark"
            search=`grep "^$mark" "/etc/fstab" 2> /dev/null`
            rep=${search/defaults/defaults,nofail}
            result=`sed -i.bak "/^$mark/c $rep" "/etc/fstab" 2> /dev/null`
            if [[ -z $result ]]; then
                    failure=false
                    success "Added nofail option in /etc/fstab for $mark"
            else
                    eror "Not able to add nofail option in /etc/fstab for $mark"
            fi
        done
        
        if [ $failure = false ] ; then
            passed "FS Tab: Secondary volume is present and it has 'nofail' option in /etc/fstab"
        else
            failed "FS Tab: Secondary volume is present and it has no 'nofail' option in /etc/fstab"
        fi
    fi

    echo -e "\n\n"
}

### Function Declaration
# The following function will function will check and install the Virtio Drivers
##
check_and_install_drivers () {
    failure=false
    heading "3. Virtio Drivers Check"
    check_kernal_param
    check_virtio_drivers
    check_initfs_initrd
    if [ $failure = false ] ; then
        passed "Virtio Drivers Check"
    else
        failed "Virtio Drivers Check"
    fi
    echo -e "\n\n"
}


####################################################################################################
####################################################################################################
######################                   SCRIPT START POINT                      ###################
####################################################################################################
####################################################################################################


welcome_note "This is a precheck script to ensure your system meets the minimum requirement for VPC.  This script will check the following:"

echo -e "\n"

sleep 2s;

echo -e "\n"

show_checklist

echo -e "\n"

sleep 2s;


################################## Checking OS version Script Starts here ##############################
check_os_distro
################################## Checking OS version Script Ends here ##############################

################################## Checking Cloud Init Script Starts here ##############################
heading "2. Cloud Init: Installation and Configuration Check"
sleep 2s;

check_cloud_init

################################## Checking Cloud Init Script Ends here ##############################


################################## Checking Virtio Drivers Starts here ##############################
check_and_install_drivers
################################## Checking Virtio Drivers Ends here ##############################

################################## Checking FS Tab Starts here ##############################
heading "4. FS Check"
check_nofail_secondry
################################## Checking FS Tab Ends here ##############################

######################## End of the Script #######################################################
footer
######################## End of the Script #######################################################