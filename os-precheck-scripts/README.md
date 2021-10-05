# Precheck Scripts
There are a set of minimum requirements that the image must meet when you migrate a virtual/guest machine to IBM Cloud as a custom image. 
More information can be found at the following links:
- [Importing and managing custom images](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-images)
- [Migrating VMware (VMDK) images to VPC](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-migrating-images-vpc)

It is highly recommended to test the pre-check scripts on a clone of the virtual/guest machine before using it on a production system.

# Linux
Resource: [Creating a Linux custom image](https://cloud.ibm.com/docs/vpc?topic=vpc-create-linux-custom-image)

A script written in BASH that automates some of the tasks is described in the link above.  This script can be used if you are planning to do the migration yourself or to use it in conjunction with the VPC+ Cloud Migration tool.
**Note:** Ignore DHCP failure when executing the pre-check script for IBM Cloud classic VSI.

The script checks the following:
- Checks for the minimum supported operating systems which are as follows:
     - CentOS 7, RHEL 7, Ubuntu 18.04, and Debian 9
- Checks for virtio drivers
     - If missing, the script will attempt to load with the dracut package and configure the Virtio driver.
- Checks for cloud-init, minimum supported version (0.7.9), and correct data source.
     - Removes all custom cloud-init config files, removes and cleans cloud-init if already existing, and re-install.
     - If missing cloud-init, then install from the default repository and add the correct data sources.
     - If data sources are missing, then make a backup copy of `cloud.cfg` to `cloud.cfg.bak`, and correct the data source parameters.
     - If the virtual server instance is from IBM Cloud classic infrastructure and has secondary attached volumes (or devices), the script will take a backup of ```/etc/fstab``` and remove entries other than ```/``` and ```/boot```. 
- Guestfs library is an optional Installation for secondary volume migration. The user will be prompted (y/n); User can opt 'y' for following Linux **Centos/Redhat 8, Ubuntu 18.04 and 20.04 and Debian 9 and 10**.

**NOTE:** The script does depend on `yum` and `apt-get` in order to install cloud-init.  Make sure your repository is current.

To execute the script, run the following command as root user:
</br>```bash linux_precheck.sh```

## FAQ
1. How do I resolve SSH failure?
<br>a. Make sure that default repo is enabled.
<br>b. Make sure that you have a good internet connection.
<br>c. Make sure that public keys are correctly placed to their respective host.
<br>d. Make sure that a firewall is not blocking the SSH connection.
    
2. How do I resolve FSTAB check failure? 
<br>a. Add `nofail` to all entries in fstab file but for `/` and `/boot`.
<br>b. OR remove all entries but `/` and `/boot`.

3. How do I resolve network check failure?
<br>Make sure at-least one network adapter is configured to get the ip address using DHCP. 
    
4. How do I resolve grub configuration failure?
<br>Add the following values `(nomodeset, nofb, vga=normal, console=tty1, console=ttyS0)` to `GRUB_CMDLINE_LINUX` parameter in `/etc/default/grub` file.

5. How do I resolve Virtio driver failure?
<br>Make sure virtio drivers and its dependencies are installed.

6. How do I resolve cloud-init failure?
<br>Refer to step 5 from the IBM Cloud documentation https://cloud.ibm.com/docs/vpc?topic=vpc-create-linux-custom-image, install, and configure accordingly.

7. Post migration, How do I resolve Guestfs (libguestfs-tools) installation failure in centos 8 ?
<br>Run the following command to resolve repo-related errors in centos 8 after migration.
<br>`sed -i 's/mirrors.service.networklayer.com/mirrors.adn.networklayer.com/g' /etc/yum.repos.d/CentOS*`
# Windows
Resource: [Creating a Window custom image](https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image)

If you are looking to build a new Windows system image to be imported to IBM Cloud VPC, this PowerShell script will check and install some of the required pieces that are needed by IBM CloudVPC.
**Note:** DO NOT use this PowerShell script with the VPC+ Cloud Migration tool. The VPC+ Cloud Migration tool can migrate Windows VSI without the need of this script. The script checks the following:
- If the system meets the minimum supported Windows 2012 version 
     - If it fails, then exit. You will need to update to the minimum supported version.
- Checks for cloud-init, version (minimum 1.1.0) and correct parameters
     - If cloudbase-init is missing, then download from https://cloudbase.it/cloudbase-init/ and install it.
     - If files and parameters do not meet the requirements as described in the above Windows resource, then create a backup file and make the necessary modifications.
- Checks for Virtio driver or version (minimum 0.1.185)
     - If missing Virtio driver, then download it from https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/ and install it.

To run the script, ensure the following:

- Windows has a PowerShell script policy that you might need to change -- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.1
     - If you change the policy, it’s a good practice to change the settings back.
- Usage ```PS C:\ .\windows_precheck.ps1```
- The system still needs to go through the Windows sysprep, device driver update, and image conversion.
For more information, reference the above link. 
- In Windows, `windows_precheck.ps1` creates duplicate directories of 'Music', 'Pictures', 'Videos' under `c:\backup\Administrator\document\`.
- Execute powershell precheck script as `Administrator` user


## FAQ
1. How do I resolve cloudbase-init download failure?
- Download cloudbase-init and save it in `C:\temp\` directory and re-run the script or install cloudbase-init. 
     - [64 bit](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi "Cloudbase-init X64")
     - [32 bit](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x86.msi "Cloudbase init X86")
   
2. How do I resolve when the cloudbase-init installation check failed?
<br>Run msi file in `C:\temp\Cloudbase.msi` and install it. 

3. How do I resolve a cloudbase-init configuration failure?
<br>Refer to step 4 from the IBM Cloud documentation https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image

4. How do I resolve Virtio download failure?
<br>Refer to step 3 from https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image 

5. How do I resolve Virtio installation failure?
<br>Mount and install VirtIO ISO file in `C:\temp\virtio-win.iso` and install `virtio-win-gt-x64.msi` from ISO file.

6. How do I resolve backup failure? 
<br>Backup `C:\Users\Administrator\` directory to safe place for future need.
