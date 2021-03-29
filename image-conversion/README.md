# Overview
You can convert your VMware virtual machine (VM) to IBM Cloud® virtual server instances to import your image to IBM Cloud VPC, and then use a custom image to create new virtual server instances, using `migration.sh` script.
This script performs following activities
- Converts images from vmdk format to qcow2 format
- Upload to COS bucket
- Create custom image

# Prerequisite
- Execute [OS Precheck scripts](https://github.com/IBM-Cloud/vpc-migration-tools/tree/main/os-precheck-scripts)

# Configuration
- `migration.cfg` contains required configuration for image conversion.
- All parameters in `migration.cfg` are mandatory. It must have correct value. Any incorrect value might result in error or unexpected behavior.
- `REGION`- A region name of a resource. e.g. `tokyo`
- `BUCKET`- A IBM's Client Object Storage bucket name.
- `IMAGE_FILENAME` - Absolute path of image with VMDK format.
- `RESOURCE_GROUP` - A resource group name of custom image and VSI.
- `OS_NAME` - Operating system's name. e.g. If its ubuntu 18.04 then `OS_NAME=ubuntu`
- `OS_VERSION` - Major and minor version of operating system e.g. If its ubuntu 18.04 then `OS_VERSION=18.04`
- Supported operating systems are
    - Centos 7, 8
    - Redhat 7, 8
    - Ubuntu 16.04, 18.04
    - Windows 2012, 2012-r2, 2016
- No space before and after `=` sign. syntax : `PARAMETER_NAME=value`

# Usage
- Perform following steps only if your instance is windows, once you have successfully executed OS Precheck Scripts :-
    - Network reset
        - Windows–Network Settings -> Network & Internet -> Status -> Reset Network
        - This disables network access to machine
    - System prep
        - Execute following command
            - `C:\Windows\System32\Sysprep\Sysprep.exe /oobe/generalize /shutdown "/unattend:C:\ProgramFiles\CloudbaseSolutions\Cloudbase-Init\conf\Unattend.xml"`
            - This will remove all system/hardware dependent files to make it work in any environment (cloud), This will also remove Administrator user files.
- Configure `migration.cfg`. Refer configuration section.
- Finally run `bash migration.sh`

# Tips
- Region mentioned in migration configuration file should match with region selected in IBM Cloud CLI.
- For windows, once QEMU tool is installed, append its installation path to windows environment variable.
- `migration.sh`, a migration script currently supports macOS and Linux only.

# FAQ
- How to resolve image conversion failure?
    - Run command manually `qemu-img convert -f vmdk -O qcow2 image.vmdk image.qcow2`
    - Change input format with flag `-f` as shown below in a table

| Image format | Argument for QEMU img |
| ------------ | ------------ |
| QCOW2 (KVM, Xen) | qcow2 |
| QED (KVM) | qed |
| raw | raw |
| VDI (VirtualBox) | vdi |
| VHD (Hyper-V) | vpc |
| VMDK (VMware) | vmdk |

- How to resolve image upload failure?
    - Make sure to have permission for COS ( Cloud Object Storage ), upload image file with [IBM Aspera Connect](https://www.ibm.com/aspera/connect/?_ga=2.134595447.766023478.1613905997-390697858.1610435302&cm_mc_uid=45064290964216104353014&cm_mc_sid_50200000=13124331614254049945  "IBM Aspera Connect").
- How to resolve custom image failure?
    - Create custom image from IBM Cloud Console ( IBM CLI ) with uploaded converted image.
- How to resolve configure check failure?
    - Make sure to have correct value for all parameters in `migration.cfg` file.

# Additional Resources
- How-to guide for [Migrating VMware (VMDK) images to VPC](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-migrating-vmware-vmdk-images)

# Known issues
- At the moment, for RHEL 8, CentOS 8 operating systems, secondary volume migration is not supported aforementioned scripts.
- At the moment, for all version of Debian operating system, no migration is supported at all.
- At the moment for Ubuntu 20.04, no migration is supported at all.
