## Discovering the VMware guest VMs using the discovery Tool

#### Overview

The discovery script that automates the discovery and inventory of  VMware virtual machine (VM) settings for Rackware RMM migration tool. By using the VMware SDK tool, the following attributes are capture and save to a csv file:

 - vCPU count
 - vMemory size
 - IP address
 
The csv file can be uploaded to the Rackware RMM migration tool to create waves for bulk migration manually.
The discovery script is available on the Rackware Appliance server under the /opt/IBM/ directory. The directory contains the following:

 - config.ini
 - discoveryTool
 - checksum.txt
 
#### Usage
```Shell
$ cd /opt/IBM/
```

Before running the discovery tool,  we need to configure parameters / key-values in config.ini file. 
In the config.ini file the user has two types of parameters 
 - Configurable parameter
 - Non-Configurable parameter  
       
For example:

```Shell
$ cat config.ini
```
		[log]
		# Log file where the discovery tool will keep the logs files.
		log_file = /var/log/discoverytool.log < non-Configurable >
		#Log level, this can be DEBUG, INFO, WARNING, ERROR, CRITICAL, the  recommended is INFO. Use DEBUG in case of troubleshooting.
		log_level = DEBUG  < non-Configurable >
		#This folder contains the file where the discovered guest VMs Rackware RMM  wave csv files are created, based on different ESXi host IP address.
		rmm_csv_template = rmm_wave_csv < non-Configurable >
		[rmm_server_config]
		#The values to be updated here is the IP address of Rackware RMM, only the IP address part needs to be updated/changed.
		rackware_rmm_url = https://<rmm.ip.add.ress>/rackware/api/v2/
		#This is the default user, don’t change this.
		rackware_admin = admin. < non-Configurable >
		
If the discovery Tool is executed without any arguments, it will display the usage info.

```Shell
$ ./discoveryTool
```
	usage: Discovery Tool [-h] [--version] -s VSPHERE -u USERNAME [-o PORT]   [-nossl]
	Discovery Tool: error: the following arguments are required: -s/--vsphere,  -u/--username
	
Discovery script logs are stored in /var/log/discoverytool.log

Run the discovery script with -h or --help option. 
```Shell
$  ./discoveryTool -h
```
	
	usage Discovery Tool [-h] [--version] -s VSPHERE -u USERNAME [-o PORT] [- nossl]
		optional arguments:
		-h | --help 
			show this help message and exit
			
 		 --version     
			show the program's version number and exit
			
		Required command line arguments based on user environment:
		
			-s VSPHERE | --vsphere VSPHERE
			--vsphere host ip
			
			-u USERNAME | --username USERNAME  
				Username to connect vSphere
			
		Optional command line arguments based on user environment:
		
  			-o PORT | --port PORT 
				If the user has defined custom port for vSphere API server, i.e., not 443
			
			-nossl | --disable-ssl-verification
				This option disables ssl host certificate verification
			
To check the discovery tool version, use this command:
```Shell
$ ./discoveryTool --version
```
Example output: Discovery Tool 1.0

To discover the guest VMs from ESXi host the required arguments are 

	-s	– 	IP address of vSphere host. 
	-u	– 	Username of vSphere host to connect. 
	-nossl	– 	This option is used to connect vSphere host using ssl disabled, between discovery Tool and vSphere host. 

#### Vsphere Password

The -u argument of the script will prompt the user for the administrator password of the  vsphere server.
Example:
```Shell
$ ./discoveryTool -s  <vsphere server>-u administrator@vsphere.local -nossl
```
###### Note: Currently the tool is required to run with -nossl option even if there is a  valid SSL certificate installed on vsphere.

- Rackware RMM tools communicate to the VM over SSH (port 22) and thus only IP address(es) that is open SSH will saved to the csv file.
- If multiple ip addresses allows SSH, then the priority will be given to the 1st  IP of the VM. 

#### Encryption/Decryption Key

The script is enabled with encryption so when the user runs the above command   then it will prompt for encryption key 

###### Note: It can be any random key/word with combination of alphanumeric and special characters. This key will be again asked for decryption as well for the discovery of the VMs.

#### RMM GUI wave planning

- The waves created on the RMM GUI will be named after the ESXI host ip address, and any discovered VMs on the ESXI host will be added to this wave.
- The inventory file itself is in csv format under the /opt/IBM/ directory and contains the details of Guest VMs as discovered for all the respective ESXi Hosts.
- If a wave exists for a given ESXi host, and if no unique IP addresses are identified, then no waves are created, and an appropriate message is displayed on  console, and the same is logged in the discoverytool.log.
- In case there are non-unique ip addresses found, then delete the existing wave, and re-run the discovery script.
- If the Rackware RMM wave is created, an appropriate message is displayed on the console and the same is logged to the discovertool.log.
	 
###### Note: It is recommended that there are no more Guest VMs moved or added to ESXi machines in VMware infrastructure, for seamless experience during the migration preparation and execution phase.


