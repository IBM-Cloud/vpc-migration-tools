#!/bin/sh
# USAGE			: ./<filename> [--help]
# DESCRIPTION	: This an automation and wrapper script to execute rsync command.
# OPTIONS		: --help : if it is used, it will display list of all options supported by rsync.
# AUTHOR		: Rahul Ippar, Rahul.Ippar@ibm.com
# COMPANY		: IBM

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

# Function to check empty string for host name or ip address
function validateIpAddressOrHostName() {
	local intIsValid=0
	validateIpAddress $strRemoteHost
	local intIsValidIp=$?

	if [[ -z "$strRemoteHost" ]];
	then
		intIsValid=1
		echo "IP address or hostname cannot be empty.";
	elif [[ 1 -eq "$intIsValidIp" ]] || [[ -z "$strRemoteHost" ]];
	then
		intIsValid=1
		echo "Invalid IP address.";
	fi

	return $intIsValid
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
	# Uncomment following statement for debugging or to display rsync command being executed.
	# echo "rsync $strOptions $strSourcePath $strUsername@$strRemoteHost:$strDestinationPath"
	echo "Executing rsync command..."
	eval "rsync $strOptions $strSourcePath $strUsername@$strRemoteHost:$strDestinationPath"
}

# Function to display all help options of rsync command
function showHelp() {
	strOption=$1

	if [[ '--help' == ${strOption,,} ]];
	then
		execute '--help'
		exit
	elif [[ -n $strOption ]];
	then
		echo "Type '${0##*/} --help' to display all rsync options."
		exit
	fi
}

# Main function to kickstart execution.
function main() {
	showHelp $1
	getInput
	execute "$strCustomOptions" "$strSourcePath" "$strDestinationPath" "$strRemoteHost" "$strUsername"
}

# Execution will start from here.
main $1
# End of the script.