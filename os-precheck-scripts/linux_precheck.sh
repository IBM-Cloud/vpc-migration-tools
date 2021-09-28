#!/bin/bash 

#----------------------------------------------------------------------------------------------------------------------
# Script Name :  linux_precheck.sh     
# Prepared By : Vikash.Kumar.Shrivastva@ibm.com
# Create Date : 02 Nov 2020
# Version: 1.0
# This is a pre-check script to ensure the system meets the minimum requirement for VPC.  This script will check the OS and minimum supported version,
# cloud-init, virtio drivers and FileSystem check.
# If it will not locate the cloud init it will install or will update the missing configuration.
#
# Script Name : Pre_check_and_configuring.sh
# Modified and added new features By : Robert.Ebenezer.Bhakiyaraj.S@ibm.com
# Create Date : 30 Mar 2021
# Version: 2.0
# This script will check all pre-requisites for linux operating systems.
# New Features :- disk size check, ssh check, network check, summary, virtio driver installation, guestfs library installation
# Modified logic :- cloud-init, Kernel parameter, virtio drivers and fstab check(FileSystem check)
# If any configuration is missing it will configure and if any package is missing it will install
#-------------------------------------------------------------------------------------------------------------------------
### Variable Declaration & Assignment
# This will hold the total number of columns of the screen
TOTAL_COLUMN=$(tput cols) 
# Total column minus 10 columns
TOTAL_COL_10=$(($TOTAL_COLUMN-10));
# The minimum cloud init version supported by this script
CLOUD_INIT_MINIMUM="0.7.9"
#--------------------------------------- Color Codes variable Starts Here  -----------------------------------------------------
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
#----------------------------------------- Color Codes variable Starts Here  --------------------------------------------------
FAIL="[ ${RED}FAILURE${NC} ]"
OK="[ ${GREEN}OK${NC} ]"
# This variable will hold the current installed distribution.
DISTRO=''
# Required Operating System Minimum Version. This script will only work on version 7 and above.
REQ_OS_VER='9'
# This is a status variable that will hold the success and failure of a task.
failure=false
# List of Checks. This variable will hold the number of check the script will perform.
declare -a TASKS=(
    "Operating System & Version Check"
    "Cloud Init: Installation and Configuration Check"
    "Virtio Drivers Check"
    "FS Tab Check"
    "Disk Size Check"
    "Check SSH Installation and Configuration"
    "Check for DHCP"
    "Check libguestfs Installation (Optional)"	
)
# List of Checks. This variable will hold the number of check the script will perform.
declare -A DISTRO_LIST=(
    [ubuntu]="16"
    [debian]="9"
    [rhel]="7"
    [centos]="7"
)
# List of Commands. This variable will hold the cloud-init installation command for different distributions.
declare -A COMMAND_LIST=(
    [ubuntu]="apt-get update -y && apt-get install cloud-init -y"
    [debian]="apt-get update -y && apt-get install cloud-init -y"
    [rhel]="yum install -y cloud-init"
    [centos]="yum install -y cloud-init"
)
#summary variable initialization
summary=""
failedcount=()
passedcount=()
failedsummary=""

### Function Declaration

# The following function will be used to print the check list.
show_checklist() {
    index=1
    for check in "${TASKS[@]}";
    do
        echo -e "${GREEN}$index. ${check}${NC}"
        ((index++))
    done
}
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
    # echo -e "\n\n"
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
    passedcount+=('passed')
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
    failedsummary="${failedsummary}$1 $RED\033[${TOTAL_COL_10}G[FAILED]$NC\n"
    failedcount+=('failed')
    for ((i=0; i<TOTAL_COLUMN; i++));
    do 
       summary="$summary$GREEN-$NC";
       failedsummary="$failedsummary$GREEN-$NC";
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
# The following function will be used to compare two version and will return the 0, 1 and 2 status code.
# Argument 1 = Version 1 (Installed Version)
# Argument 2 = Version 2 (Required Version)
#---------- Return -------------
# Status Code 0: [PASSED] The version is equal to Required version
# Status Code 1: [PASSED] The version is greater than the required version.
# Status Code 2: [FAILED] The version is less than the required version.
verOSComp (){
  cur_os_ver=$1
  cur_os_ver=`echo ${cur_os_ver%.*}`
  req_os_ver=$2  
  if [[ $cur_os_ver -eq $req_os_ver ]];then
	  return 0
  elif [[ $cur_os_ver -gt $req_os_ver ]];then
	  return 0
  elif [[ $cur_os_ver -lt $req_os_ver ]];then
	  return 2
  fi
}
#OS Version comparison with minimum version requirement
verComp () {
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
# The following function will test the required or compatible 'Operating System' and required or compatible
# version and will print the passed or failed messages correspondingly.
# If the Operating System is not compatible it will print the error and exit the script.
check_os_distro () {
    heading "1. Operating System & Version Check"
    flag=false
    # Check the OS distro and version to ensure it is supported
    if [ -f /etc/os-release ]; then
        DISTRO=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        DISTRO_VERSION=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
        if [[ -n "${DISTRO_LIST[$DISTRO]}" ]]; then 
            REQ_OS_VER="${DISTRO_LIST[$DISTRO]}"
            disMsg="OS Check: Installed distribution is ${DISTRO^^} and supported distributions are: ${!DISTRO_LIST[@]}"
            verMsg="OS Version Check: Installed Distro Version is ${DISTRO_VERSION^^} and supported version is ${REQ_OS_VER} or above"
            passed "$disMsg"
            verOSComp $DISTRO_VERSION $REQ_OS_VER
            if [ $? =  2 ]; then
                flag=true
                failed "$verMsg"
            else
                passed "$verMsg"
            fi
        else
           flag=true
           failed "$disMsg"
           error "This Operating System is not supported by this script."
           footer
           exit
        fi
    else
        flag=true
    fi
    if [[ $flag = true ]]; then
        failed "Operating System & Version Check"
    else
        passed "Operating System & Version Check"
    fi
    echo -e "\n\n"
}
# The following function will check Kernel parameters. 
# If any kernel parameters are missing then it will print error message for the missing parameter
# and will print the passed or failed messages correspondingly.
check_kernel_param () {
	if grep -q "nomodeset nofb vga=normal console=tty1 console=ttyS0" "/etc/default/grub"; then
        passed "Already Kernel Parameter configured"
	else
        error "Kernel Parameter Not configured"
        logInfo "Taking backup for grub file"
        cp=`cp -avf /etc/default/grub /etc/default/grub-backup  2> /dev/null` 
		logInfo "Adding Kernel Parameter in grub file" 
        sed -i '/GRUB_CMDLINE_LINUX/d' /etc/default/grub 
		if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
			echo 'GRUB_CMDLINE_LINUX="crashkernel=auto spectre_v2=retpoline rd.lvm.lv=centos/root rd.lvm.lv=centos/swap rhgb quiet nomodeset nofb vga=normal console=tty1 console=ttyS0"' >> /etc/default/grub
        elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
			echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet"' >> /etc/default/grub 
			echo 'GRUB_CMDLINE_LINUX="find_preseed=/preseed.cfg noprompt nomodeset nofb vga=normal console=tty1 console=ttyS0"' >> /etc/default/grub
        fi
		logInfo "Re-checking Kernel Parameter"
        if grep -q "nomodeset nofb vga=normal console=tty1 console=ttyS0" "/etc/default/grub"; then
            passed "Kernel Parameter configured"
		else
			failed "Failed to configure Kernel Parameter"
        fi
    fi
}
#Checking virtio driver module loaded or not
check_virtio_drivers_dependencies()
{ 
    if [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]] && [[ "$DistroVer" -le "${DISTRO_LIST[$DISTRO]}" ]] ;then
       	failure=false
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "block/virtio_blk"` ]];then
          	failure=true
            error "Virtio driver missing : virtio_blk"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "net/virtio_net"` ]];then
          	failure=true
            error "Virtio driver missing : virtio_net"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "virtio/virtio_pci.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio_pci.ko"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "virtio/virtio.ko"` ]];then
           	failure=true
            error "Virtio driver missing : virtio.ko"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "virtio/virtio_ring"` ]];then
            failure=true
            error "Virtio driver missing : virtio_ring"
        fi
    elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]] && [[ "$DistroVer" -gt "${DISTRO_LIST[$DISTRO]}" ]] ;then
	   	failure=false
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "block/virtio_blk"` ]];then
            failure=true
            error "Virtio driver missing : virtio_blk"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "net/virtio_net"` ]];then
            failure=true
            error "Virtio driver missing : virtio_net"
        fi
	    if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio_pci.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio_pci.ko"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio.ko"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio_ring"` ]];then
            failure=true
            error "Virtio driver missing : virtio_ring"
        fi
    elif [[ "$DISTRO" == "ubuntu" ]] && [[ "$DistroVer" -le "${DISTRO_LIST[$DISTRO]}" ]] ;then
        failure=false
		if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "block/virtio_blk"` ]];then
            failure=true
            error "Virtio driver missing : virtio_blk"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "net/virtio_net"` ]];then
            failure=true
            error "Virtio driver missing : virtio_net"
        fi
	    if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio_pci.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio_pci.ko"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio.ko"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio_ring"` ]];then
            failure=true
            error "Virtio driver missing : virtio_ring"
        fi
	elif [[ "$DISTRO" == "ubuntu" ]] && [[ "$DistroVer" -gt "${DISTRO_LIST[$DISTRO]}" ]] ;then
        failure=false
		if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "block/virtio_blk"` ]];then
            failure=true
            error "Virtio driver missing : virtio_blk"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "net/virtio_net"` ]];then
            failure=true
            error "Virtio driver missing : virtio_net"
        fi
	    if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio_pci.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio_pci.ko"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio.ko"
        fi
        if [[ ! `grep -E "virtio.*" < /lib/modules/"$(uname -r)"/modules.builtin | grep -E "virtio/virtio_ring"` ]];then
            failure=true
            error "Virtio driver missing : virtio_ring"
        fi
    elif [[ "$DISTRO" == "debian" ]] && [[ "$DistroVer" -le "${DISTRO_LIST[$DISTRO]}" ]] ;then
        failure=false
		if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "block/virtio_blk"` ]];then
            failure=true
            error "Virtio driver missing : virtio_blk"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "net/virtio_net"` ]];then
            failure=true
            error "Virtio driver missing : virtio_net"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "virtio/virtio_pci.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio_pci.ko"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio  | grep -E "virtio/virtio.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio.ko"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio  | grep -E "virtio/virtio_ring"` ]];then
            failure=true
            error "Virtio driver missing : virtio_ring"
        fi
    elif [[ "$DISTRO" == "debian" ]] && [[ "$DistroVer" -gt "${DISTRO_LIST[$DISTRO]}" ]] ;then
        failure=false
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "block/virtio_blk"` ]];then
            failure=true
            error "Virtio driver missing : virtio_blk"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "net/virtio_net"` ]];then
            failure=true
            error "Virtio driver missing : virtio_net"
        fi
	    if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio | grep -E "virtio/virtio_pci.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio_pci.ko"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio  | grep -E "virtio/virtio.ko"` ]];then
            failure=true
            error "Virtio driver missing : virtio.ko"
        fi
        if [[ ! `lsinitrd /boot/initramfs-$(uname -r).img | grep virtio  | grep -E "virtio/virtio_ring"` ]];then
            failure=true
            error "Virtio driver missing : virtio_ring"
        fi
    else
        logInfo "OS not supported"
        failure=true
    fi    
    echo $failure
}
# The following function will preload Virtio Drivers in temp kernel. 
# If any Virtio drivers are missing then it will print error message for the missing parameter
# and will print the passed or failed messages correspondingly.
preload_virtio_driver()
{
    mkinitrd -f --allow-missing \
            --with=xen-blkfront --preload=xen-blkfront \
            --with=virtio_blk --preload=virtio_blk \
            --with=virtio_pci --preload=virtio_pci \
            --with=virtio_console --preload=virtio_console \
            /boot/initramfs-$(uname -r).img $(uname -r)
}
#configure dracut configuration with required module to load in kernel
config_dracut()
{   
    if [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]];then
        cp -avf /etc/dracut.conf /etc/dracut.conf-backup  2> /dev/null
        sed -i '/add_drivers+=/d' /etc/dracut.conf
        sed -i '/force_drivers+=/d' /etc/dracut.conf
        echo "force_drivers+=\"virtio_blk virtio_net virtio_pci virtio_ring virtio\"" >>  /etc/dracut.conf
        dracut -f --regenerate-all
    elif [[ "$DISTRO" == "ubuntu" ]];then
        cp -avf /etc/dracut.conf.d/10-debian.conf /etc/dracut.conf.d/10-debian.conf-backup  2> /dev/null
        sed -i '/add_drivers+=/d' /etc/dracut.conf.d/10-debian.conf
        sed -i '/force_drivers+=/d' /etc/dracut.conf.d/10-debian.conf
        echo "force_drivers+=\"virtio_blk virtio_net virtio_pci virtio_ring virtio\"" >>  /etc/dracut.conf.d/10-debian.conf
        dracut -f --regenerate-all
    elif [[ "$DISTRO" == "debian" ]];then
        cp -avf /etc/dracut.conf.d/10-debian.conf /etc/dracut.conf.d/10-debian.conf-backup  2> /dev/null
        sed -i '/add_drivers+=/d' /etc/dracut.conf.d/10-debian.conf
        sed -i '/force_drivers+=/d' /etc/dracut.conf.d/10-debian.conf
        echo "force_drivers+=\"virtio_blk virtio_net virtio_pci virtio_ring virtio\"" >>  /etc/dracut.conf.d/10-debian.conf
        dracut -f --regenerate-all
    fi
}
#check installation of dracut package for virtio module
check_install_dracut()
{
    if [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]];then
        if rpm -q dracut  >/dev/null 2>&1; then
    		logInfo "Package is already installed!"
            config_dracut
        else
            if [[ `yum -y install dracut` ]];then
                if rpm -q dracut  >/dev/null 2>&1; then
    		        logInfo "Package is installed!"
                    logInfo "Installation successfull"
                    config_dracut
                else
                    logInfo "Installation not successfull"
                fi
            fi
        fi
    elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
        packstatus=`dpkg --get-selections | grep dracut-core | awk '{print $2}'`
	    if [[ "$packstatus" = "install" ]]; then
    		logInfo "Package is already installed!"
            config_dracut
        else
            if [[ `apt-get install dracut-core -y` ]];then
                packstatus=`dpkg --get-selections | grep dracut-core | awk '{print $2}'`
	            if [[ "$packstatus" = "install" ]]; then
    		        logInfo "Package is installed!"
                    logInfo "Installation successfull"
                    config_dracut
                else
                    logInfo "Installation not successfull"
                fi
            fi
        fi
    fi
}
# The following function will check Virtio Drivers. 
# If any Virtio drivers are missing then it will print error message for the missing parameter
# and will print the passed or failed messages correspondingly.
check_virtio_drivers ()
{
    NET=`grep -i virtio /boot/config-$(uname -r) | grep  "CONFIG_VIRTIO_NET="`
    BLK=`grep -i virtio /boot/config-$(uname -r) | grep  "CONFIG_VIRTIO_BLK="`
    NETSTATUS=${NET: -1}
    BLKSTATUS=${BLK: -1}
    if [[ "$BLKSTATUS"  == "m" ]] && [[ "$NETSTATUS" ==  "m" ]];then
        passed "Virtio Module Installed"
        DistroVer=`echo $DISTRO_VERSION | cut -f1 -d"."`
        if [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]] && [[ "$DistroVer" -le "${DISTRO_LIST[$DISTRO]}" ]] ;then
            failure=$(check_virtio_drivers_dependencies)
            if [[ "$failure" == "false" ]];then
        	    success "Virtio Module loaded"
            else
        	    error "Virtio Module Not Loaded"
			    logInfo "Attempting to load Virtio Module"
                preload_virtio_driver
            fi
            #re-checking
            failure=$(check_virtio_drivers_dependencies)
            if [[ "$failure" == "false" ]];then
			    failure=false
			    passed "Virtio Module loaded"
		    else
			    failure=true
			    failed "Virtio Module Not Loaded"
		    fi
        elif [[ "$DISTRO" == "centos" || "$DISTRO" == "rhel" ]] && [[ "$DistroVer" -gt "${DISTRO_LIST[$DISTRO]}" ]] ;then
	        failure=false
	        failure=$(check_virtio_drivers_dependencies)
	        if [[ "$failure" == "false" ]];then
                failure=false
                success "Virtio Module loaded"
            else
                error "Virtio Module Not Loaded"
			    logInfo "Attempting to load Virtio Module"
                check_install_dracut
            fi
            #re-checking
            failure=$(check_virtio_drivers_dependencies)
            if [[ "$failure" == "false" ]];then
			    failure=false
			    passed "Virtio Module loaded"
		    else
			    failure=true
			    failed "Virtio Module Not Loaded"
		    fi
        elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
    	    failure=$(check_virtio_drivers_dependencies)
            if [[ "$failure" == "false" ]];then
		        failure=false
                success "Virtio Module loaded"
            else
                error "Virtio Module Not Loaded"
			    logInfo "Attempting to load Virtio Module"
                check_install_dracut
            fi
            #re-checking
            failure=$(check_virtio_drivers_dependencies)
            if [[ "$failure" == "false" ]];then
			    failure=false
			    passed "Virtio Module loaded"
		    else
			    failure=true
			    failed "Virtio Module Not Loaded"
		    fi
	    else
		    failure=true
     	    failed "Not Support OS Distribution"
	    fi
    elif [[ "$BLKSTATUS"  = "y" ]] && [[ "$NETSTATUS" =  "y" ]];then
		failure=false
     	passed "Virtio Module Installed and Loaded"
    else	
		failure=true
		error "Re-build kernel with latest version, "
     	failed "Virtio Module check failed"     		
    fi
}
# The following function will check cloud-init configuration. 
# if some configurations are missing then 
# it will print error message for the missing configurations and will fix. If cloud init version is less than the 
# required one then it will print error message to upgrade the cloud init and exit.
check_cloud_init_config (){
	ci_ds_config=`grep -i "^datasource_list" /etc/cloud/cloud.cfg 2> /dev/null`
    if [[ $ci_ds_config ]]; then
	    sed -i "/^datasource_list/d" /etc/cloud/cloud.cfg 2> /dev/null
        if [[ "$?" -eq 0 ]];then
		    success "We have deleted the datasource_list configuration from /etc/cloud/cloud.cfg"
		    cloudInitFlag=false
            passed "datasource removed from /etc/cloud/cloud.cfg and expected configuration"
	    else
	        cloudInitFlag=true
		    failed "Not able to delete datasource from /etc/cloud/cloud.cfg"
	    fi
	else
	    cloudInitFlag=false
	    passed "datasource not found in /etc/cloud/cloud.cfg and expected configuration"
	fi
	ci_vendor_config=`grep -i "scripts\-vendor" /etc/cloud/cloud.cfg 2> /dev/null`
    if [[ $ci_vendor_config != *scripts\-vendor* ]]; then
        error "Cloud-init Config Check: Module \"scripts-vendor\" is missing in cloud_final_modules of \"/etc/cloud/cloud.cfg\""
        cloudInitFlag=true
        logInfo "Fixing scripts-vendor configuration. Please wait."
        if [ -f /etc/cloud/cloud.cfg ]; then
            sed -i '/ - scripts-user/a\ - scripts\-vendor' /etc/cloud/cloud.cfg
		    cloudInitFlag=false
	    else
	        cloudInitFlag=true
	        error "/etc/cloud/cloud.cfg not found"
        fi
        passed "scripts-vendor configuration has been fixed."
    else
	    cloudInitFlag=false
        passed "Cloud-init Config Check: Module \"scripts-vendor\" is found."
    fi
}
remove_cloud_init (){
    logInfo "Already cloud-init exist and will be removed and cleaned"
    DistroVer=`echo $DISTRO_VERSION | cut -f1 -d"."`
    if [[ "$DISTRO" == "ubuntu" ]] && [[ "$DistroVer" -gt "${DISTRO_LIST[$DISTRO]}" ]] ;then
        if [[ `sudo apt-get remove cloud-init -y && sudo apt-get purge cloud-init -y && sudo rm -rf /etc/cloud/ && sudo rm -rf /var/lib/cloud/` ]];then
            packstatus=`dpkg --get-selections | grep cloud-init | awk '{print $2}'`
	        if [[ ! "$packstatus" = "install" ]]; then
		        logInfo "Removed and cleaned successfull"
            fi
        fi
    fi

}
# The following function will check cloud-init installation and configuration. 
# If it is not installed then it will install cloud init. if some configurations are missing then 
# it will print error message for the missing configurations and will fix. If cloud init version is less than the 
# required one then it will print error message to upgrade the cloud init and exit.
check_cloud_init (){
    cloudInitFlag=false
    # Determine if cloud-init is installed and its filepath
    cloud_init_status=`cloud-init --version 2>&1`
    if [ $? -eq 0 ]; then
        remove_cloud_init
    fi
    cloud_init_status=`cloud-init --version 2>&1`
    if [ $? -eq 0 ]; then 
        cloud_init=`[[ $cloud_init_status =~ "ExecStart="([^[:space:]]+)[[:space:]]* ]] && echo ${BASH_REMATCH[1]}`
        cloud_init_version=`${cloud_init} --version 2>&1 | cut -d' ' -f2 | cut -d'-' -f1`
    fi
    # Check that cloud-init is installed and meets the minimum version requirement
    if [ -z "$cloud_init_version" ]; then
        cloudInitFlag=true
        logInfo "Cloud Init is not installed.";
        logInfo "Installing cloud-init and configuring it." 
        eval "${COMMAND_LIST[$DISTRO]}"
        if [[ $? -eq 0 ]]; then
            passed "Cloud-Init Install successful"
        ################################## Setting the Cloud Init Configuration ##############################
            if [ -f /etc/cloud/cloud.cfg ]; then
	        check_cloud_init_config  
            fi
            draw_line "-"
            draw_line "-"
            cloudInitFlag=false
            success "Cloud-Init has been installed and configured."
        else
            draw_line "-"
            draw_line "-"
            error "Not able to install cloud-init."
            failed "Cloud-Init NOT Installed"
            cloudInitFlag=true
        fi
    else
        errorFlag=false
        verComp $cloud_init_version $CLOUD_INIT_MINIMUM
        res=$?
    
        if [ $res -eq  2 ]; then
            failed "Cloud-init version check"
            error "Cloud-init version ${CLOUD_INIT_MINIMUM} or greater is required"
            cloudInitFlag=true
        fi
        cloudInitFlag=false
        check_cloud_init_config        
    fi
    echo -e "\n\n"
}
# The following function will check for the secondary drives in /ets/fstab configuration file. 
check_secondary () {
    failure=false
    filepath="/etc/fstab"
    secondary_volumes=($(cat $filepath | grep -v ^\# | awk '$2 != "/" && $2 != "/boot" {print $1}'));
    if [ -z $secondary_volumes ]; then
        passed "Fstab file does not have entries apart from OS partitions in $filepath and expected configuration"
    else
        logInfo "Taking backup of $filepath file to $filepath-backup "
        cp -avf "$filepath" "$filepath-backup"
        fail_mounts=($(cat $filepath | grep -v ^\# | awk '$2 != "/" && $2 != "/boot" {print $1}'))
        for i in "${fail_mounts[@]}"
        do
            failure=true
            mark=$i
            search=`grep "^$mark" "$filepath" 2> /dev/null`
            mark=`basename "$mark"`
            if sed -i "/$mark/d" $filepath 2> /dev/null
            then
                failure=false
                success "Removed entry $mark from $filepath"
            else
                failure=true
                error "Not able to remove $mark from $filepath"
            fi
        done
        secondary_volumes=($(cat $filepath | grep -v ^\# | awk '$2 != "/" && $2 != "/boot" {print $1}'));
        if [ $failure = false ] && [[ -z $secondary_volumes ]]; then
            passed "Fstab file does not have entries apart from OS partitions in $filepath"
        else
            failed "Fstab file does have entries apart from OS partitions in $filepath"
        fi
    fi
    echo -e "\n\n"
}
#The following function will check whether disk size is smaller than 100GB
check_disk_size(){
	heading "5. Disk Size Check"
    if [[ "$DISTRO" == "rhel" ]] && [[ "$DistroVer" -gt "${DISTRO_LIST[$DISTRO]}" ]] ;then
        diskname=`eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's/[0-9]*$//' | sed 's/[p]*$//'`
    else
	    diskname=`eval $(lsblk -oMOUNTPOINT,PKNAME -P | grep 'MOUNTPOINT="/"'); echo $PKNAME | sed 's/[0-9]*$//'`
    fi
	actualsize=`lsblk -l -oTYPE,NAME,SIZE | grep disk | grep $diskname | awk '{print $3}' | sed 's/.$//'`
    size=`echo $actualsize | cut -f1 -d"."`
	logInfo "Accepted Disk Size less than 99GB"
	if [ "$size" -lt 99 ]
	then
		passed "OS File system disk size is $actualsize GB and Accepted"
	else
		failed "OS File system disk size should be smaller than 99GB"
	fi
}
#The following function will check and configure ssh
ssh_config ()
{
    logInfo "Checking for ssh configuration"
    if [[ -d "/root/.ssh/" ]];then
        if [[ -f "/root/.ssh/authorized_keys" ]];then
            chmod 700 /root/.ssh
            chmod 600 /root/.ssh/*
        else
            touch /root/.ssh/authorized_keys
            chmod 700 /root/.ssh
            chmod 600 /root/.ssh/*
        fi
    else
        mkdir /root/.ssh
        touch /root/.ssh/authorized_keys
        chmod 700 /root/.ssh
        chmod 600 /root/.ssh/*
    fi
    passed "ssh configuration completed"
}
# The following function will check status installation and service 
check_install_and_service_ssh(){
    heading "6. Check SSH Installation and configuration"
    if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
	    if rpm -q openssh-server  >/dev/null 2>&1 && rpm -q openssh-clients >/dev/null 2>&1; then
    		logInfo "Package  is installed!"
    		if [[ `systemctl status sshd | grep "active (running)"` ]];then
        		logInfo "SSH is running"
        		systemctl enable sshd
        		ssh_config
    		else
        		logInfo "SSH Not running and Starting now"
        		systemctl start sshd
        		systemctl enable sshd
        		ssh_config
    		fi
	    else
    		error "Package is NOT installed!"
    		logInfo "Installing ssh"
    		if [[	`yum -y install openssh-server openssh-clients` ]];then
			    logInfo "Installation successfull"
    			if [[ `systemctl status sshd | grep "active (running)"` ]];then
        			logInfo "SSH is running"
        			systemctl enable sshd
        			ssh_config
    			else
				    logInfo "Starting ssh"
        			systemctl start sshd
        			systemctl enable sshd
        			ssh_config
    			fi
		    else
			    failed "Installed Failed"
		    fi
	    fi
    elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
	    packstatus=`dpkg --get-selections | grep openssh-server | awk '{print $2}'`
	    if [[ "$packstatus" = "install" ]]; then
    		logInfo "Package  is installed!"
    		if [[ `systemctl status ssh | grep "active (running)"` ]];then
    			logInfo "SSH is running"
    			systemctl enable ssh
    			ssh_config
    		else
			    logInfo "SSH Not running and Starting now"
    			systemctl start ssh
    			systemctl enable ssh
    			ssh_config
    		fi
	    else
    		error "Package  is NOT installed!"
    		if [[ `apt-get install openssh-server -y` ]];then
			    logInfo "Installation successfull"
    			if [[ `systemctl status ssh | grep "active (running)"` ]];then
        			logInfo "SSH is running"
        			systemctl enable ssh
        			ssh_config
    			else
				    logInfo "SSH Not running and Starting now"
        			systemctl start ssh
        			systemctl enable ssh
        			ssh_config
    			fi
		    else
			    failed "Installed Failed"
		    fi 
	    fi
    fi
}
# The following function will check DHCP configuration
check_DHCP ()
{
heading "7. Check for DHCP"
netarr=()
if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
	for net in  $(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}');do
        if [[ `ip -4 addr show $net | grep dynamic` ]];then
			logInfo "DHCP configured in $net"
			netarr+=("true")
		else
			logInfo "DHCP not configured for $net"
			netarr+=("false")
		fi
	done
elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
    for net in  $(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}');do
		if [[ `ip -4 addr show $net | grep dynamic` ]];then
			logInfo "DHCP configured in $net"
			netarr+=("true")
		else
			logInfo "DHCP not configured for $net"
			netarr+=("false")
		fi
	done
    if [[ "${netarr[*]}" == *"false"* ]]; then
	    for net in  $(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}');do
        	ifaceNet=`cat /etc/network/interfaces | grep "iface $net"`
        	if [[ "$ifaceNet" == *"dhcp"* ]];then
                	logInfo "DHCP configured in $net"
                	netarr+=("true")
        	else
                	logInfo "DHCP not configured for $net"
                	netarr+=("false")
        	fi
	    done
    fi
    if [[ "${netarr[*]}" == *"false"* ]]; then
        logInfo "Checking other network config files"
	    for net in  $(ip link | awk -F: '$0 !~ "lo|vir|wl|^[^0-9]"{print $2;getline}');do
            cd /etc/network/interfaces.d/
            for file in *; do
                if [[ ! -d "$file" ]];then
                    echo $file
                    ifaceNet=`cat $file | grep "iface $net"`
        	        if [[ "$ifaceNet" == *"dhcp"* ]];then
                	    logInfo "DHCP configured in $net"
                	    netarr+=("true")
        	        else
                	    logInfo "DHCP not configured for $net"
                	    netarr+=("false")
        	        fi
                fi
            done
        done
    fi
fi
if [[ "${netarr[*]}" == *"true"* ]]; then
    passed "DHCP Configuration Present"
else
    failed "DHCP Not Configured, Please make sure that at least one network interface is set to auto-configure (DHCP)"
    
fi
}
# The following function will check and install the Virtio Drivers
check_and_install_drivers () 
{
    failure=false
    heading "3. Virtio Drivers Check"
    check_kernel_param
    check_virtio_drivers   
    if [ $failure = false ] ; then
        passed "Virtio Drivers Check"
    else
        failed "Virtio Drivers Check"
    fi
    echo -e "\n\n"
}
#spinner for progress
spin() 
{
    printf "\b${sp:sc++:1}"
    ((sc==${#sp})) && sc=0
}
endspin() 
{
    printf "\r%s\n" "$@"
}
#install guestfs library for secondary volume migration
install_libguestfs-virtd_service()
{   
    if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
        #spin
        if [[ `yum update -y && yum -y install libguestfs-tools` ]];then
            if rpm -q libguestfs-tools >/dev/null 2>&1 ; then
		        logInfo "libguestfs-tools installation successfull"
                passed "libguestfs-tools installed"
                #endspin
            else
                failed "libguestfs-tools installation Failed"
            fi
        else
            failed "libguestfs-tools installation Failed"
        fi
    elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
        if [[ `apt-get update -y && apt-get install libguestfs-tools -y` ]];then
            packstatus=`dpkg --get-selections | grep libguestfs-tools | awk '{print $2}'`
	        if [[ "$packstatus" = "install" ]]; then
		        logInfo "libguestfs-tools installation successfull"
                passed "libguestfs-tools installed"
            else 
                failed "libguestfs-tools installation Failed"
            fi
		else
		    failed "libguestfs-tools installation Failed"
        fi
    fi        
}
#start guestfs service for secondary volume migration
start_enable_libguestfs-virtd_service()
{
    if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
        if [[ `systemctl status libvirtd | grep "active (running)"` ]];then
        	logInfo "libvirtd is running"
        	systemctl enable libvirtd
			passed "libvirtd running"
    	else
        	logInfo "libvirtd Not running and Starting now"
        	systemctl start libvirtd
        	systemctl enable libvirtd
			passed "libvirtd running"
    	fi
    fi
}
#check guestfs library installed or not and service running or not used for secondary volume migration
check_libguestfs-virtd()
{
    if [[ "$DISTRO" == "centos" ]] || [[ "$DISTRO" == "rhel" ]];then
	    if rpm -q libguestfs-tools >/dev/null 2>&1 ; then
            if systemctl status libvirtd | grep running >/dev/null 2>&1 ;then
                failure=false
            else
                question "Do you want to start guestfs service which is used in secondary volume migration"
	            read userinput
	            if [[ "$userinput" == "y" ]];then
                    heading "8. Check libguestfs Installation"
		            start_enable_libguestfs-virtd_service
	            fi
            fi
        else
            question "Do you want to install guestfs library which is used in secondary volume migration"
	        read userinput
	        if [[ "$userinput" == "y" ]];then
                heading "8. Check libguestfs Installation"
		        install_libguestfs-virtd_service
                start_enable_libguestfs-virtd_service
	        fi
        fi
    elif [[ "$DISTRO" == "ubuntu" ]] || [[ "$DISTRO" == "debian" ]];then
	    packstatus=`dpkg --get-selections | grep libguestfs-tools | awk '{print $2}'`
	    if [[ "$packstatus" = "install" ]]; then
            failure=false
        else
            question "Do you want to install guestfs library which is used in secondary volume migration"
	        read userinput
	        if [[ "$userinput" == "y" ]];then
                heading "8. Check libguestfs Installation"
		        install_libguestfs-virtd_service
	        fi
        fi
    fi
}
summary_report()
{
    welcome_note "   Summary of the pre-validated script "
    printf "$summary"
    echo -e "\n"
    heading "   Summary report "
    echo -e "\n"
    total=$((${#passedcount[@]} + ${#failedcount[@]}))
    printf "(  $RED${#failedcount[@]} $NC failed out of $YELLOW$total $NC )"
    echo -e "\n"
    if [[ ${#failedcount[@]} -ne 0 ]];then
        echo "Following checks failed : -"
        echo -e "\n"
        printf "$failedsummary"
    else
        echo "All pre-requisite checks passed"
    fi
    echo -e "\n"
    draw_line "*" 
    
}
#---------------------------------------------------------------------------------------------------
#----------------------------          SCRIPT START POINT           --------------------------------
#---------------------------------------------------------------------------------------------------
welcome_note "This is a pre-check script to ensure your system meets the minimum requirement for VPC.  This script will check the following:"
echo -e "\n"
sleep 2s;
echo -e "\n"
show_checklist
echo -e "\n"
sleep 2s;
#-------------------------------- Checking OS version Script Starts here ---------------------------
check_os_distro
#-------------------------------- Checking OS version Script Ends here -----------------------------
#-------------------------------- Checking Cloud Init Script Starts here ---------------------------
heading "2. Cloud Init: Installation and Configuration Check"
sleep 2s;
check_cloud_init
#-------------------------------- Checking Cloud Init Script Ends here -----------------------------
#-------------------------------- Checking Virtio Drivers Starts here ------------------------------
check_and_install_drivers
#-------------------------------- Checking Virtio Drivers Ends here --------------------------------
#-------------------------------- Checking FS Tab Starts here --------------------------------------
heading "4. FS Tab Check"
check_secondary
#-------------------------------- Checking FS Tab Ends here ----------------------------------------
#-------------------------------- Checking Disk Size  Script starts here ---------------------------
check_disk_size
#-------------------------------- Checking Disk Size  Script Ends here -----------------------------
#-------------------------------- Checking ssh  Script starts here ---------------------------------
check_install_and_service_ssh
#-------------------------------- Checking ssh  Script Ends here -----------------------------------
#-------------------------------- Checking DHCP  Script starts here --------------------------------
check_DHCP
#-------------------------------- Checking DHCP  Script End here -----------------------------------
#-------------------------------- Check Secondary volume migration requisite starts here ------
check_libguestfs-virtd
#-------------------------------- Check Secondary volume migration requisite End here --------
#-------------------------------- End of the Script ------------------------------------------------
summary_report
footer
#-------------------------------- End of the Script ------------------------------------------------