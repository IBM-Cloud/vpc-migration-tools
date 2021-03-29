# Precheck Scripts #
There are a set of minimum requirements that the image must meet when you migrate a virtual/guest
machine to IBM Cloud as a custom image. More information can be found at the following links:
- [Importing and managing custom images](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-images)
- [Migrating VMware (VMDK) images to VPC](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-migrating-vmware-vmdk-images)

It is highly recommended to test the pre-check scripts on a clone of the virtual/guest machine
first before using it on a production system.

## Linux ##
Resource: [Creating a Linux custom image](https://cloud.ibm.com/docs/vpc?topic=vpc-create-linux-custom-image)

A script written in BASH that automates some of the tasks are described in the link above.  This
script can be used if you are planning to do the migration yourself or use in conjunction with VPC+ 
Cloud Migration tool.

The script checks the following:
- Check for minimum supported operating systems which are as follows:
     - CentOS 7, RHEL 7, Ubuntu 16.04
- Check for virtio drivers
     - If missing then user will need to install the Virtio driver.
- Check for cloud-init, minimum supported version (0.7.9), and correct data source.
     - If missing cloud-init, then install from the default repository and add the correct data sources.
     - If data sources are missing, then make a backup copy of `cloud.cfg` to `cloud.cfg.bak` and correct 
the data source parameters.
     - If the virtual server instance is from IBM Cloud classic infrastructure and has secondary attached
volumes (or devices), script will take a backup of ```/etc/fstab``` and remove entries other than ```/```, ```/boot``` and ```swap```.

**NOTE:** The script does depend on `yum` in order to install cloud-init.  Make sure your repository is
active and current.

To execute the script, run the following command: </br>
```./rhel_precheck.sh```

- Execute pre-check scripts (hyperlink script files here)  as `root` user (for Linux), to behave perfectly.

### FAQ ###
#### 1. How do I resolve SSH failure? ####
* Make sure that default repo is enabled.
* Make sure that you have good internet connection.
* Make sure to public keys are correctly placed to respective host.
* Make sure that firewall is not blocking SSH connection.
    
#### 2. How do I resolve FSTAB check failure? ####
* Add `nofail` to all entries in fstab file but for `/` and `/boot`.
* OR remove all entries but `/` and `/boot`.

#### 3. How do I resolve network check failure? ####
* Set at least one network adapter to get the IP address automatically (DHCP enabled). 
    
#### 4. How do I resolve grub configuration failure? ####
* Add following four parameters to `/etc/default/grub` file as it is.
  - `(nomodeset, nofb, vga=normal, console=ttyS0)`

#### 5. How do I resolve Virtio driver failure? ####
Install Virtio drivers and its dependancies by yourself.

#### 6. How do I resolve cloud-init failure? ####
Refer to step 5 from IBM Cloud documentation https://cloud.ibm.com/docs/vpc?topic=vpc-create-linux-custom-image, install, and configure accordingly.

## Windows ##
Resource: [Creating a Window custom image](https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image)

If you are looking to build a new Windows system image to be imported to IBM Cloud VPC, this
PowerShell script will check and install some of the required pieces that is needed by IBM Cloud
VPC.

**Note:** DO NOT use this PowerShell script with VPC+ Cloud Migration tool. VPC+ Cloud Migration
tool can migrate Windows VSI without the need of this script.

The script checks the following:
- If the system meets the minimum supported Windows version
     - If fails, then exit. You will need to update to the minimum supported version.
- Check for cloud-init, version (minimum 1.1.0) and correct parameters
     - If cloudbase-init is missing, then download from https://cloudbase.it/cloudbase-init/ and
install it.
     - If files and parameters do not meet the requirements as described in the above Windows resource,
then create a backup file and make the necessary modification.
- Check for Virtio driver or version (minimum 0.1.185)
     - If missing Virtio driver, then download it from https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/
and install it.

To run the script, ensure the following:

- The assumption is that the system has internet access.  If the system does not have internet
access, then another box download (CloudbaseInitSetup_Stable_x64.msi and virtio-win.iso) and copy
the files to the C:\temp folder.
- Windows has a PowerShell script policy that you might need to change -- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.1
     - If you change the policy, it’s a good practice to change the settings back.
- Usage ```PS C:\ .\windows_precheck.ps1```
- The system still needs to go through Windows sysprep, device driver update, image conversion.
For more information, reference the above link. 
- In windows, `migration_prep.ps1` creates duplicate directories of 'Music', 'Pictures', 'Videos' under `c:\backup\Administartor\document\`.
- Execute pre check scripts ( hyperlink script files here ) as `Administrator` user, to behave perfectly.

### FAQ ###
#### 1. How do I resolve cloudbase-init download failure? ####
- Download cloudbase-init and save it in `C:\temp\` directory and re-run the script or install cloudbase-init by yourself. 
     - [64 bit](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi "Cloudbase-init X64")
     - [32 bit](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x86.msi "Cloudbase init X86")
   
#### 2. How do I resolve cloudbase-init installation check failed? ####
Run msi file in `C:\temp\Cloudbase.msi` and install it by yourself. 

#### 3. How do I resolve cloudbase-init configuration failure? ####
Refer to step 4 from IBM Cloud documentation https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image

#### 4. How do I resolve Virtio download failure? ####
Refer to step 3 from https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image 

#### 5. How do I resolve Virtio installation failure? ####
Mount and install VirtIO ISO file in `C:\temp\virtio-win.iso` and install `virtio-win-gt-x64.msi` from ISO file by yourself.

#### 6. How do I resolve backup failure? ####
Backup `C:\Users\Administrator\` directory to safe place for future need.

#### 7. How do I resolve configure check failure? ####
Make sure to have correct value for each parameter.