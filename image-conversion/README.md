# Overview
You can convert your virtual machine (VM) to IBM Cloud® virtual server instances to import your image to IBM Cloud VPC, and then use a custom image to create new virtual server instances, using `migration.sh` script.
This script performs following activities:
- Converts images from VMDK/VHD format to qcow2 format
- An option to upload the converted qcow2 image to COS
- Check for presence of qcow2 image in COS (Cloud Object Storage)
- Create custom image

## Prerequisite
- Run [OS pre-check scripts](https://github.com/IBM-Cloud/vpc-migration-tools/tree/main/os-precheck-scripts)

# Usage
## Configuration
`migration.cfg` contains the require parameters that is needed by `migration.sh` for the image conversion.

All parameters in `migration.cfg` are mandatory. It must have correct values. Any incorrect value might result in an error or unexpected behavior.
- `REGION`- A region name of a resource. e.g. `tokyo`
- `BUCKET`- An IBM's client Object Storage bucket name.
- `IMAGE_FILENAME` - Absolute path of image with VMDK/VHD format.
- `RESOURCE_GROUP` - A resource group name of custom image and virtual server instance.
- `OS_NAME` - Operating system's name (for example, if it's Ubuntu 18.04, then the name is `OS_NAME=ubuntu`)
- `OS_VERSION` - Major and minor version of operating system (for example,  if it's Ubuntu 18.04, then the value is `OS_VERSION=18.04`)
- `PARTFILESIZE` - Defining size for spliting image file into specified PARTFILESIZE can be ranges from 10m to 1000m(best internet connection), based on internet speed and stability
- Supported operating systems:
    - Centos 7, 8
    - Redhat 7, 8
    - Ubuntu 16.04, 18.04, 20.04
    - Windows 2012, 2012-r2, 2016
    - Debian 9, 10
- No space before and after `=` sign. Syntax : `PARAMETER_NAME=value`

## Windows-pecific guidelines
- Perform the following steps only if your instance is _**Windows**_, after you have successfully executed OS pre-check scripts:
    - Network reset
        - This disables network access to machine
        - Windows 2012, 2012 R2
            - Run these commands in `Command Prompt`
                `netsh winsock reset`
                `netsh int ip reset c:\resetlog.txt`
        - Windows 2016
            - `Windows–Network Settings -> Network & Internet -> Status -> Reset Network`
    - System prep
        - Execute following command:
            - `C:\Windows\System32\Sysprep\Sysprep.exe /oobe/generalize /shutdown "/unattend:C:\ProgramFiles\CloudbaseSolutions\Cloudbase-Init\conf\Unattend.xml"`
            - This will remove all system/hardware dependent files to make it work in any environment (cloud). This will also remove administrator user files.
- Configure `migration.cfg`. Refer to the Configuration section.
- Run `bash migration.sh`

## Tips
- Region mentioned in the migration configuration file should match with the region selected in the IBM Cloud CLI.
- `migration.sh`, a migration script currently supports macOS and Linux only.

# FAQ
1. How do I resolve image upload failure? <br>
Make sure that you have permission for COS (Cloud Object Storage), and upload image file with [IBM Aspera Connect](https://www.ibm.com/aspera/connect/?_ga=2.134595447.766023478.1613905997-390697858.1610435302&cm_mc_uid=45064290964216104353014&cm_mc_sid_50200000=13124331614254049945  "IBM Aspera Connect")
2. How do I resolve custom image failure? <br>
Create custom image from IBM Cloud Console (IBM CLI) with uploaded converted image.
3. How do I resolve configure check failure? <br>
Make sure to have the correct value for all parameters in the `migration.cfg` file.

# Additional resources
How-to guide for [Migrating VMDK or VHD images to VPC](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-migrating-images-vpc)

# What's in progress?
The following are not currently supported but will be supported in future releases:
- Auto provisioning of IBM Cloud VSI creation 

