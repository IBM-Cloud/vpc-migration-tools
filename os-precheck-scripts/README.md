# Precheck Scripts #
There are a set of minimum requirements that image must meet when you migrate a virtual/guest
machine to IBM Cloud as a custom image. More information can be found [here](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-images).

It is highly recommended to test the precheck scripts on a clone of the virtual/guest machine
first before using it on a production system.

## Red Hat ##
Resource: [Creating a Linux custom image](https://cloud.ibm.com/docs/vpc?topic=vpc-create-linux-custom-image)

A script written in BASH that automates some of the tasks are described in the link above.  This
script can be used if you are planning to do the migration yourself or use in conjunction with VPC+ 
Cloud Migration tool.

The script checks the following:
- If the system meets the minimum supported major version (7.x)
     - If missing, then exit.  User will need to upgrade the OS.
- Check for virtio drivers
     - If missing, then exit.  User will need to install the virtio driver.
- Check for cloud-init, minimum supported version (0.7.9) and correct data source.
     - If missing cloud-init, then install from yum repository and add the correct data sources.
     - If data sources are missing, then make a backup copy of cloud.cfg to cloud.cfg.bak and correct 
the data source parameters.
     - If the virtual server instance is from IBM classic infrastructure and has secondary attached
volumes, then check for NOFAIL flag.  If not present, then add NOFAIL.

**NOTE:** The script does depend on yum in order to install cloud-init.  Make sure your repository is
active and current.

To execute the script, run the following command: </br>
```./rhel_precheck.sh```

## Windows ##
Resource: [Creating a Window custom image](https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image)

If you are looking to build a new Windows system image to be imported to IBM Cloud VPC, this
PowerShell script will check and install some of the required pieces that is needed by IBM Cloud
VPC.

**Note:** DO NOT use this PowerShell script with VPC+ Cloud Migration tool.  VPC+ Cloud Migration
tool can migrate Windows VSI without the need of this script.

The script checks the following:
- If the system meets the minimum supported Windows version
     - If fails, then exit.  User will need to update to the minimum supported version.
- Check for cloud-init, version (minimum 1.1.0) and correct parameters
     - If cloudbase-init is missing, then download from https://cloudbase.it/cloudbase-init/ and
install it.
     - If files and parameters do not meet the requirements as described in the above Windows resource,
then create a backup file and make the necessary modification.
- Check for virtio driver or version (minimum 0.1.185)
     - If missing virtio driver, then download it from https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/
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

