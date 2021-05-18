#!/bin/bash
# USAGE			: bash ./<filename> [--help] OR bash ./<filename> [--debug] [--skip_disk_check]
# DESCRIPTION	: This an automation and wrapper script to execute rsync command.
# OPTIONS		: --help : Script will display list of all options supported by rsync.
#				: --debug : Script will display rsync command being executed.
#				: --skip_disk_check : Script will not perfom disk check of destination.			
# AUTHOR		: Rahul Ippar, Rahul.Ippar@ibm.com
# COMPANY		: IBM

# Function to display usage of script
function displayUsage() {
	echo "USAGE : bash ./${0##*/} [--help] OR ./${0##*/} [--debug] [--skip_disk_check]"
}

# Function to ask for multiple inputs
function getInput() {
	while true;
	do
		read -e -p "Enter source path:" strSourcePath

		if validateSourcePath "$strSourcePath";
		then
			break;
		fi
	done

	while true;
	do
		read -e -p "Enter destination path:" strDestinationPath

		if validateDestinationPath "$strDestinationPath";
		then
			break;
		fi
	done

	while true;
	do
		read -e -p "Enter target details (ip address or hostname):" strRemoteHost

		if validateIpAddressOrHostName "$strRemoteHost";
		then
			break;
		fi
	done

	read -e -p "Enter target machine's username ( Leave blank for default):" strUsername
	read -e -p "Enter custom options (Leave blank for default):" strCustomOptions
}

# Function to validate source path
function validateSourcePath() {
	local strExamplePath=""
	local intIsValid=0

	if [[ -z "$strSourcePath" ]];
	then
		intIsValid=1
		echo "Source path cannot be empty."
	elif [[ ! -e "$strSourcePath" ]];
	then
		intIsValid=1

		if [[ "Cygwin" == $(getOs) ]];
		then
			strExamplePath="/cygdrive/<drive>/<folder_path>"
		elif [[ "Linux" == $(getOs) ]];
		then
			strExamplePath="/<directory_path>"
		fi

		echo "Directory or file does not exist. e.g. $strExamplePath"
	fi

	return $intIsValid
}

# Function to validate destination path
function validateDestinationPath() {
	local intIsValid=0

	if [[ -z "$strDestinationPath" ]];
	then
		intIsValid=1
		echo "Destination path cannot be empty."
	fi

	return $intIsValid
}

# Function to validate ip address
function validateIpAddress() {
	local strIpAddress=$1
	local intIsValidIp=0

	if [[ $strIpAddress =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]];
	then
		OIFS=$IFS
		IFS='.'
		strIpAddress=($strIpAddress)
		IFS=$OIFS
		[[ ${strIpAddress[0]} -le 255 && ${strIpAddress[1]} -le 255 \
			&& ${strIpAddress[2]} -le 255 && ${strIpAddress[3]} -le 255 ]]
		intIsValidIp=$?
	fi

	return $intIsValidIp
}

function validateHostname() {
	local strHostname=$1
    local intIsValidHostname=1

    if [[ $strHostname =~ ^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$ ]];
    then
        intIsValidHostname=0
    fi

    return $intIsValidHostname
}

# Function to check empty string for host name or ip address
function validateIpAddressOrHostName() {

	local intIsValid=0

	validateIpAddress $strRemoteHost
	local intIsValidIp=$?

	validateHostname $strRemoteHost;
	local intIsValidHostname=$?

	if [[ -z "$strRemoteHost" ]];
	then
		intIsValid=1
		echo "IP address or hostname cannot be empty.";
	elif [[ 1 -eq "$intIsValidIp" ]] || [[ 1 -eq $intIsValidHostname ]];
	then
		intIsValid=1
		echo "Invalid IP address or hostname.";
	fi

	return $intIsValid
}

# Function to validate memory space at destination machine
function validateDiskSpace() {
	local strFileSystem=""

	intSourceDataSize=$( du -s "$strSourcePath" | awk '{ print $1 }' )

	if ssh root@$strRemoteHost "[ -d $strDestinationPath ]"; then
		# If file/directory exist then get its file system
		strFileSystem=$( ssh "$strRemoteHost" df -T "$strDestinationPath" | awk 'END {print $1}' )
	else
		# If file/directory does not exist then get its parent's file system
		strParentDir=$( ssh "$strRemoteHost" dirname "$strDestinationPath" )
		strFileSystem=$( ssh "$strRemoteHost" df -T "$strParentDir" | awk 'END {print $1}' )
	fi

	intDestinationFreeSpace=$( ssh "$strRemoteHost" df "$strFileSystem" | awk 'END { print $4 }' )

	if [ $intDestinationFreeSpace -lt $intSourceDataSize ];
	then
		echo "Not enough disk space at $strDestinationPath@$strRemoteHost to copy data."
		exit 0;
	fi
}

# Function to check remote host is reachable or not
function validateRemoteHost() {
	local intIsValid=0

	if [ "Linux" == $(getOs) ];
	then
		strPingResponse=$( ping -c 1 $strRemoteHost | grep -i 'received' | awk -F',' '{ print $2}' | awk '{ print $1}' ) #Linux
	elif [ "Cygwin" == $(getOs) ];
	then
		strPingResponse=$( ping  $strRemoteHost | grep -i 'received' | awk -F',' '{ print $2}' | awk '{ print $3}' ) #Windows
	else
		echo "OS is not supported."
		exit 0;
	fi

	strPingError1='Name or service not known'
	strPingError2='Ping request could not find host'
	
	if [[ "$strPingResponse" == *"$strPingError1"* ]]; then
		intIsValid=1
		echo "$strRemoteHost : Name or service not known."
	elif [[ "$strPingResponse" == *"$strPingError2"* ]]; then
		intIsValid=1
		echo "Could not find host $strRemoteHost"
	elif [[ "$strPingResponse" == "0" || -z "$strPingResponse" ]]; then
		intIsValid=1
		echo "Host $strRemoteHost not reachable."
	fi
	
	if [[ 1 -eq $intIsValid ]]; then
		exit 0;
	fi
}

# Function to get default options for rsync command
function getDefaultOptions() {
	local strWindowsOptions=""

	if [ "Cygwin" == $(getOs) ];
	then
		strWindowsOptions=" --rsync-path=c:/cygwin64/bin/rsync.exe "
	fi

	echo "-e 'ssh' --archive --info=progress2 --info=name0 --update --compress --stats --human-readable --partial --log-file=./rsync.log $strWindowsOptions"
}

# Function to get operating system name
function getOs() {
	unameOut="$(uname -s)"

	case "${unameOut}" in
		Linux*)		strOs=Linux;;
		Darwin*)	strOs=Mac;;
		CYGWIN*)	strOs=Cygwin;;
		MINGW*)		strOs=MinGw;;
		*)			strOs="UNKNOWN:${unameOut}"
	esac

	echo ${strOs}
}

# Function to get default user account name based on source operating system. For linux its 'root' and for windows its 'Administrator'
function getDefaultUsername() {
	strOsName=$(getOs)
	strDefaultUsername=""

	if [ "Linux" == $strOsName ] 
	then
		strDefaultUsername="root"
	elif [ "Cygwin" == $strOsName ]
	then
		strDefaultUsername="Administrator"
	fi

	echo ${strDefaultUsername}
}

# Function to build and execute rsync final command
function execute() {
	strCustomOptions=$1
	strSourcePath=$2
	strDestinationPath=$3
	strRemoteHost=$4
	strUsername=$5

	if [[ -z $strUsername ]];
	then
		strUsername=$(getDefaultUsername)
	fi

	strOptions="$(getDefaultOptions)$strCustomOptions"

	if [ 0 -eq $intIsDebug ];
	then
		echo "rsync $strOptions \"$strSourcePath\" \"$strUsername@$strRemoteHost:$strDestinationPath\""
	fi

	eval "rsync $strOptions \"$strSourcePath\" \"$strUsername@$strRemoteHost:$strDestinationPath\""
}

# Function to display all help options of rsync command
function applyOptions() {

	if [[ "$#" -gt 2 ]]; then
		echo "Error: excess number of parameters."
		displayUsage
		exit 0;
	fi

	intIsDebug=1 # 0 = display debug info, 1= do not display debug info
	intIsSkipDiskCheck=1 # 0 = skip 1,  = Do not skip
	intIsHelp=1 # 0 = Yes, 1 = No

	local count=1;
	for strOption in "$@" 
	do
		case ${strOption,,} in
			--help) intIsHelp=0
				;;
			--debug) intIsDebug=0
				;;
			--skip_disk_check) intIsSkipDiskCheck=0
				;;
			*) echo "Type '${0##*/} --help' to display all rsync options."
				displayUsage
  			   ;;
		esac
		count=$((count + 1));
	done

	if [[ 0 -eq $intIsHelp ]]; then
		execute '--help'
		exit 0;
	fi
}

# Main function to kickstart execution.
function main() {
	applyOptions $@
	getInput
	validateRemoteHost

 	# Validate memory space only if its Linux OS and skip_disk_check flag is not passed
	if [[ 1 -eq $intIsSkipDiskCheck && "Linux" == $(getOs) ]];
	then
		validateDiskSpace
	fi

	execute "$strCustomOptions" "$strSourcePath" "$strDestinationPath" "$strRemoteHost" "$strUsername"
}

# Execution will start from here.
main $@
# End of the script.