# Overview

Server Migration for IBM Cloud is a one-click solution where you can migrate from VMware VM or IBM Cloud® classic virtual server instances to IBM Cloud VPC, so that you can adopt the native capabilities of IBM Cloud.
This script performs the following activities:
- Checks pre-requisites for migration script 
- Checks and validates the configuration file and IBM Cloud resources
- Converts images from VMDK/VHD format to qcow2 format
- Contains an option to upload the converted qcow2 image to COS
- Checks for the presence of qcow2 image in COS (Cloud Object Storage)
- Creates a custom image
- Creates a VSI with custom image

## Packages/Scripts for Migration Pre-requisites

- Download the required scripts for migration from below github public repository :–
 [Server-Migration](server-migration)

## Migration considerations

 Review the following migration considerations for the scriptsmigration:
 - Virtual machines must be exported in VMDK or VHD format.
 - Virtual machines with Network Attached Storage (NAS) such as iSCSI or NFS are not automatically copied over. Data migration must be done as a separate process.
 - IP addresses are not preserved.
 - Hypervisor specifics are not preserved, such as port groups and teaming.

## Migration process

 - Log in to any server which need to be migrated.
 - Go to the directory which has the downloaded scripts
 - Run appliance.sh script
 - Provide the IP address of the source machine that you want to migrate.
 - Select whether you are migrating from VMware or classic. The directory file and config file will be created and the script stops running.
 - Update the details for the config file and then re-run theappliance.shscript.
 - Provide the IP address that is required to migrate.
 - Select “y” for the following question:Doyouwanttocontinuealreadystartedmigration[Defaulty].
 - The scriptchecks for all the required permissions and validates the config file. If config file is valid and all the required permissions are present, then the scripts creates an SSH key.
 - Copy the SSH key and paste it in the authorized file in the user's home directory inssh. Then answer “y” for the following question:HaveyoucopiedtheSSHpublickeycontentandinsertedinssh/authorizedfile,pleaseconfirm.

 
## Migration with Scripts 

After you confirm that the SSH key is in the correct place, the server completes the following for you:
- Scripts runs the pre-check on the source machineusing SSH Connection.
- When the pre-checks pass, then the VMDK image is uploaded into the path.
- Script converts the image to supported format(qcow2).
- Script uploads the converted image into an IBM Cloud Object Storage bucket and then creates a custom image with the uploaded image in the bucket.
- Then the automated scripts create a target migrated virtual server in IBM Cloud VPC.

## Additional VMware steps 

If you have migrated from VMware and the migration is successful, you need to complete a few extra steps:
- Go to VMware datastore. 
- Download and copy the VMDK file of the OS disk. For example, VMware ESXicreates a compressed file that containsdisk.vmdkanddisk-flat.vmdk. Copy both the files into the pathshown after prechecks completed.
- Run theappliance.shcommand again, and the remaining migration process will be done by the script itself.

## Validate your migration
 After migration, validate or update the following:
 - Application
 - Data 
 - Reachability (host level configuration changes)
 
### Note :- 
- Region mentioned in the migration configuration file should match with the region selected in the IBM Cloud CLI.
- `appliance.sh`- migration script currently runs on macOS and Linux only.

### Usage
- Configuration `config` file contains the required parameters that are needed by `migration.sh` for the image conversion.

- No space before and after `=` sign. 
Syntax : 
    `PARAMETER_NAME=value`

All parameters in `migration.cfg` are mandatory. You must supply the correct values. Any incorrect value might result in an error or unexpected behavior.
- `REGION`: A region name of a resource. e.g. `tokyo`
- `BUCKET`: An IBM's Cloud Object Storage bucket name.
- `IMAGE_FILENAME`: Absolute path of image with VMDK/VHD format.
- `RESOURCE_GROUP`: A resource group name of a custom image and virtual server instance.
- `OS_NAME`: Operating system's name (for example, if it's Ubuntu 18.04, then the name is `OS_NAME=ubuntu`)
- `OS_VERSION`: Major and minor version of the operating system (for example, if it's Ubuntu 18.04, then the value is `OS_VERSION=18.04`)
- `PARTFILESIZE`: Defining size for splitting image file into a specified PARTFILESIZE; can be ranges from 10m to 1000m(stable internet connection), based on internet speed and stability
- `CUSTOM_IMAGE_NAME`: Name of the custom image
- `VSI_NAME`: Name of the VSI
- `VPC_NAME`: Name of the VPC 
- `SUBNET_NAME`: Name of the Subnet
- `INSTANCE_PROFILE_NAME`: Hardware profile name
- `VSI_SSH_KEYNAME_NAME`: Name of the SSH Key

- Supported operating systems:
    - Centos 7, 8
    - Redhat 7, 8
    - Ubuntu 18.04, 20.04
    - Windows 2012, 2012-r2, 2016, 2019
    - Debian 9, 10

### Windows-specific guidelines
- Perform the following steps only if your instance is _**Windows**_, after you have successfully executed the OS pre-check scripts:
    - Network reset
        - Network reset not required for classic vsi migration
        - This disables network access to machine
        ### Windows 2012 and 2012 R2
            - Run these commands in `Command Prompt`:
                `netsh winsock reset`
                `netsh int ip reset c:\resetlog.txt`
        ### Windows 2016 and 2019
            - `Windows–Network Settings -> Network & Internet -> Status -> Reset Network`
    - System prep
        - Execute the following command:
             `C:\Windows\System32\Sysprep\Sysprep.exe /oobe /generalize /shutdown "/unattend:C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml"`
        <br>_**Note**_: This will remove all system/hardware dependent files to make it work in any environment (cloud). This will also remove administrator user files.
- Configure config file. Refer to the Configuration section above.
- Run `bash appliance.sh`

### FAQ
1. How do I resolve image upload failure during migration script execution?
<br>Make sure that you have permission for COS (Cloud Object Storage), and upload image file with [IBM Aspera Connect](https://www.ibm.com/aspera/connect/?_ga=2.134595447.766023478.1613905997-390697858.1610435302&cm_mc_uid=45064290964216104353014&cm_mc_sid_50200000=13124331614254049945  "IBM Aspera Connect")
2. How do I resolve custom image creation failure during migration script execution?
<br>Manually create custom image from IBM Cloud Console (IBM CLI) with the uploaded converted image.
3. How do I resolve configuration error in migration.cfg reported by migration script?
<br>Make sure to have the correct value for all parameters in the `migration.cfg` file.

### Additional resources
How-to guide for [Migrating VMDK or VHD images to VPC](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-migrating-images-vpc)
