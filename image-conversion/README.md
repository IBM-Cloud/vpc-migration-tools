# Overview
# Configuration
- `migration.cfg` contains required configuration for image conversion.
- 
# Usage
- `bash migration_prep.sh` for classic source Linux instance.
- `ps migration_prep.ps1` for classic source Windows instance.
- Manual steps in between
    - Network reset
        - Windows–Network Settings -> Network & Internet -> Status -> Reset Network
        - This disables network access to machine
    - System prep
        - Execute following command
            - `C:\Windows\System32\Sysprep\Sysprep.exe /oobe/generalize /shutdown "/unattend:C:\ProgramFiles\CloudbaseSolutions\Cloudbase-Init\conf\Unattend.xml"`
            - This will remove all system/hardware dependent files to make it work in any environment (cloud), This will also remove Administrator user files.
- Configure `migration.cfg`
- `bash migration.sh`
# Tips
- Execute pre check scripts ( hyperlink script files here )  as Admin user ( for windows ) or root user ( for linux ), to behave perfectly.
- Region mentioned in migration configuration file should match with region selected in IBM Cloud CLI.
- For windows, once QEMU tool is installed, append its installation path to windows environment variable.
- `migration.sh`, a migration script currently supports macOS and Linux only. 
# FAQ
## Windows
- How to resolve cloudbase-init download failure?
    - Download cloudbase-init and place in `C:\temp\`  directory and re-run the script or install cloudbase-init by yourself. 
    - [Download Cloudbase-init X64](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi "Cloudbase-init X64")
    - [Download Cloudbase-init X86](https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x86.msi "Cloudbase init X86")
- How to resolve cloudbase-init installation check failed?
    - Run msi file in `C:\temp\Cloudbase.msi` and install it by yourself. 
- How to resolve cloudbase-init configuration failure?
    - Refer step number 4 from IBM cloud documentation https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image
- How to resolve virtio download failure?
    - Refer step number 3 from https://cloud.ibm.com/docs/vpc?topic=vpc-create-windows-custom-image 
- How to resolve virtio installation failure?
    - Mount and install VirtIO ISO file in `C:\temp\virtio-win.iso` and install `virtio-win-gt-x64.msi` from ISO file by yourself.
- How to resolve backup failure?
    - Backup `C:\Users\Administrator\` directory to safe place for future need.
- How to resolve configure check failure?
    - Make sure to have correct value for each parameter.
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

- How to resolve image upload to cos failed or not able to upload?
    - Make sure to have permission for COS ( Cloud Object Storage ), upload image file with [IBM Aspera Connect](https://www.ibm.com/aspera/connect/?_ga=2.134595447.766023478.1613905997-390697858.1610435302&cm_mc_uid=45064290964216104353014&cm_mc_sid_50200000=13124331614254049945  "IBM Aspera Connect").
- How to resolve custom image failure?
    - Create custom image from IBM Cloud Console ( IBM CLI ) with uploaded converted image.
- How to resolve VSI creation failure?
    - Create Gen 2 VSI from IBM Cloud Console with uploaded converted image.

------------

- ## Linux
- How to resolve SSH failure?
    - Make sure that default repo is enabled.
    - Make sure to have good internet connection
    - Make sure to public keys are correctly placed to respective host.
    - Make sure filewall is not blocking SSH connection.
- How to resolve FSTAB check failure?
    - Add nofail to all entries in fstab file but for `/` and `/boot`.
    - OR remove all entries but `/` and `/boot`.
- How to resolve Network check failure?
    - Set at-least one network adapter to get IP address automatically ( DHCP enabled ). 
- How to resolve grub configuration failure?
    - Add following four parameters to `/etc/default/grub` file as it is.
        - `(nomodeset, nofb, vga=normal, console=ttyS0)`
- How to resolve virtio driver failure?
    - Install virtio drivers and its dependancies by yourself.
- How to resolve cloud-init failure?
    - Refer step number 5 from IBM cloud documentation https://cloud.ibm.com/docs/vpc?topic=vpc-create-linux-custom-image, install and configure accordingly.
- How to resolve configure check failure?
    - Make sure to have correct value for all parameters in `migration.cfg` file.
- How to resolve image conversion failure?
    - Run following command
    - `qemu-img convert -f vmdk -O qcow2 image.vmdk image.qcow2`
    - Change input format with flag `-f` as shown in following table :

| Image format | Argument for QEMU img |
| ------------ | ------------ |
| QCOW2 (KVM, Xen) | qcow2 |
| QED (KVM) | qed |
| raw | raw |
| VDI (VirtualBox) | vdi |
| VHD (Hyper-V) | vpc |
| VMDK (VMware) | vmdk |

- How to resolve image upload failure?
    - Make to have permission for COS ( Cloud Object Storage ), try uploading with [IBM Aspera Connect](https://www.ibm.com/aspera/connect/?_ga=2.134595447.766023478.1613905997-390697858.1610435302&cm_mc_uid=45064290964216104353014&cm_mc_sid_50200000=13124331614254049945 "IBM Aspera Connect") 
- How to resolve custom image failure?
    - create custom image from IBM Cloud Console ( IBM CLI ) with uploaded converted image.
- How to resolve VSI creation failure?
    - Create Gen 2 VSI from IBM Cloud Console with uploaded converted image.
# Additional Resources
- How-to guide for [Image Conversion - Add link here for IBM documentation](https://cloud.ibm.com/docs/cloud-infrastructure?topic=#)
