# VPC Migration Tools

This repository provides access to different tools and solutions that can be used to migrate from classic or on-prem resources to IBM Cloud VPC.  The tools include individual custom scripts and open source utilities.  You can use the tools as is or modify them to fit your needs. As a recommended
practice, carefully review any materials from this repository before you use them on any live systems.

## Pre Validation Check Scripts ##

There are minimum requirements for migrating an existing guest machine image to IBM Cloud VPC as a custom image.  The image must:

* Contain a single file or volume.
* Be in `qcow2` format and have .qcow2 file extension.
* Be cloud-init enabled.
* Use an operating system that is supported as a stock image operating system.

For more information about managing images, see [link](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-images).

Use these custom scripts to validate the candidate guest machine.

[OS Precheck Scripts](os-precheck-scripts/)

## Data Migration ##

There are many tools available to migrate data from the source to the target machine. This
script uses an open source utility `rsync` with the some default commands. 

[rysnc script](data-migration/)

## DB Migration ##

- [MySQL](db-migration/mysql/)

   Script based tool to assist with mysql db migration between 2 servers. The script logs into the
source and initiate mysqldump utility and copies it to a COS. Target server copies it from the
COS and restores the backup db. [Click here](db-migration/mysql/) for script.

- [MSSQL](db-migration/mssql/post-migration/)

   In case of MSSQL clustred database migration using [Rackware Management Module (RMM)](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-mssql-db-overview#rackware-management-module) there is known issue. When MSSQL migration is performed for machines with clustered node. User will not be able to login with domain credentials because of error "the trust relationship between this workstation and the primary domain failed". So even if you enter the correct domain credentials post migration, it does not allow to user to login. So as a simple solution to this problem is to login to the node machine using local admin account and explicitly unjoin node machine from domain and rejoin domain. Once this is done, user can login to the target machine using domain credentials. This process is automated in the form of script. [Click here](db-migration/msssql/post-migration) for script.

## Image Conversion ##

When migrating from an ESXi hypervisor, the image needs to be in `qcow2`. This script
converts guest images from Vmware in vdmk format to qcow2. 

[image conversion](image-conversion)

## Server Migration ##

If you are migrating from vmware vmdk or IBM Cloud Classic, these script will helpful for migration automation of pre-checks, image conversion, custom image creation and auto-provision target server into IBM Cloud VPC . 

[Server Migration](server-migration)

## Discovering the VMware guest virtual machines ##

This script is a complementary tool to RackWare RMM migration tool. The script discovers virtual machines on ESXi hypervisor and creates
wave on the Rackware RMM server.

[VMWare discovery tool](v2v-discovery-tool-rmm/VMware/)

## Discovering the Hyper-V guest virtual machines ##

This script is a complementary tool to RackWare RMM migration tool. The script discovers guest machines on Windows hypervisor and creates
wave on the Rackware RMM server.

[Hyper-V discovery tool](v2v-discovery-tool-rmm/HyperV/)

## Suggestion/Issues ##

While there are no warranties of any kind, and there is no service or technical support
available for these scripts from IBM support, your comments are welcomed by the maintainers
and developers, who reserve the right to revise or remove the tools at any time. We,
maintainers and developers, will support the scripts posted in this repository. To report 
problems, provide suggestions or comments, please open a GitHub issue. If the scripts are
modified and have issues, we will do our best to assist.

<!-- A more detailed Usage or detailed explaination of the repository here -->
