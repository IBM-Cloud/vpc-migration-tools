# Hyper-V Single Cluster Discovery Tool with SCVMM

## Discovering the Hyper-V guest virtual machine(s) using the Discovery Tool

#### Overview

The Discovery tool automates the discovery of Hyper-V virtual machine(s) settings for the RackWware RMM migration tool. By using the System Center Virtual Machine Manager (SCVMM) PowerShell cmdlets, the following attributes are captured and saved to a **csv** file:

 - Virtual machine name
 - Operating system
 - Virtual machine hostname
 - Virtual machine Hyper-V nodes
 - Virtual machine Hyper-V cluster name
 - vCPU count
 - vMemory size
 - IP address
 
#### Usage

The discovery tool is available on the RackWare RMM server under the `/opt/IBM/HyperV/` directory. The directory contains the following information:

 - config.ini
 - discoveryTool
 - checksum.txt

```Shell
$ cd /opt/IBM/HyperV/
```

Before running the Discovery Tool command, you need to configure parameters in the `config.ini` file. 
In the config.ini file you have two types of parameters:
- Default parameters
- Configurable parameters
   
For example:

```Shell
$ cat config.ini
```

```
[log]

# Log file where the discovery tool will keep the logs (INFO level) files.
log_file = /var/log/discoverytool_info.log < Configurable >

# Log file where the discovery tool will keep the logs (ERROR level) files.
error_log_file = discoverytool_error.log < Configurable >

#This folder contains the file where the discovered guest VMs Rackware RMM  wave csv files are created, based on Hyper-V Cluster name address.
rmm_csv_template = rmm_wave_csv < Configurable >

[rmm_server_config]

# Replace <rmm_ip_address> with ip address of Rackware RMM server.
rackware_rmm_url = https://<rmm_ip_address>/rackware/api/v2/

#This is the default user, don’t change this.
rackware_admin = admin < Default >
```

Running the Discovery Tool?

```Shell
discoveryTool [-h] [--version] -s SCVMM -u USERNAME -c CLUSTERNAME -d DOMAIN
```

For example :
```Shell
discoveryTool -s 10.10.10.1 -u administrator -c vCLUSTER -d DISCOVERY.LOCAL
```

Arguments used for Hyper-V Discovery Tool

| Arguments | Description | Mandatory/Opional |
| --- | --- | --- |
| -h, --help | Shows help message and exit | Optional |
| --version | Shows program's version number and exit | Optional |
| -s SCVMM, --scvmm SCVMM | SCVMM host IP | Mandatory |
| -u USERNAME, --username USERNAME | UserName to connect SCVMM host | Mandatory |
| -c CLUSTERNAME, --clustername CLUSTERNAME | Single ClusterName to fetch from SCVMM | Mandatory |
| -d DOMAIN, --domain DOMAIN |  Hyper-V cluster domain name | Mandatory |

If the Discovery Tool is executed without any arguments, it displays the usage information.

```Shell
$ ./discoveryTool
```

```Shell
usage: discoveryTool [-h] [--version] -s SCVMM -u USERNAME -c CLUSTERNAME -d DOMAIN
discoveryTool: error: the following arguments are required: -s/--scvmm, -u/--username, -c/--clustername, -d/--domain
```

To see syntax, required and optional parameters, and usage of the Discovery Tool, run command with `-h` or `--help` option:

```Shell
$  ./discoveryTool -h
```
		
To check the Discovery Tool version, use the following command:

```Shell
$ ./discoveryTool --version
```
#### SCVMM PowerShell Cmdlets
Following are some important and generic SCVMM powershell cmdlets used in Discovery Tool :

`Get-SCVMHostCluster`

`Get-SCVMHost -VMHostCluster`

`fetch VirtualNetworkAdapters using Get-SCVirtualMachine`

#### SCVMM password

- Discovery Tool prompts you for the administrator password of the SCVMM server.
- Discovery Tool communicate to SCVMM server and to the VM over SSH (port 22) and thus only IP address(es) that are open on SSH port 22 will be saved to the csv file.
- If in guest virtual machine(s) and, multiple interfaces or IP addresses are open on SSH port 22, then the priority will be given to the primary or first network interface or IP Address of guest virtual machine(s). 

#### RMM GUI wave planning

- Waves ares created on the RMM GUI will be named after the Hyper-V cluster name (FQDN), and any discovered VMs on the Hyper-V cluster host will be added to this wave.
- The inventory file is in csv format under the `/opt/IBM/HyperV/` directory and contains the details of guest virtaual machine(s) as discovered from the respective Hyper-V cluster.
- If a wave exists for a given Hyper-V cluster, and if no unique IP addresses are found, then no waves are created, and an appropriate message is displayed on  the console, and the same is logged in the `discoverytool_info.log` file. 
- If the Rackware RMM wave is created, an appropriate message is displayed on the console and the same is logged to the `discoverytool_info.log` file.
- All the non reachable guest virtual machine(s) on SSH port 22 will be displayed on console, and logged in `discoverytool_error.log` file.
	 
###### Note: It is recommended that there are no more guest virtual machine(s) moved or added to Hyper-V cluster, for seamless experience during the migration preparation and execution phase.

## Additional resources
- How-to guide for [Microsoft Hyper-V VM to IBM Cloud VPC migration with RackWare RMM](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-migrating-images-vmware-vsi)
