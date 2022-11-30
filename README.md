# VPC Migration Tools

This repository provides access to different tools and solutions that you can use when migrating your infrastructure to IBM Cloud VPC.  The tools include  individual custom scripts and open source utilities.  You can use the tools as is or you can modify them to fit your needs. As a recommended
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

Script to assist with mysql db migration between 2 servers.

[MySQL db migration](db-migration/mysql/)

## Image Conversion ##

If you are migrating from another hypervisor, the image needs to be in `qcow2`. Use this script to convert guest images from Vmware in vdmk format to qcow2. 

[image conversion](image-conversion)

## Discovering the VMware guest virtual machines ##

If you are RackWare RMM tool for migration, and if your environment is VMWare based then use this tool for automated discovery and wave setup.

[VMWare discovery tool](v2v-discovery-tool-rmm/VMware/)

## Discovering the Hyper-V guest virtual machines ##

If you are RackWare RMM tool for migration, and if your environment is Hyper-V based then use this tool for automated discovery and wave setup.

[Hyper-V discovery tool](v2v-discovery-tool-rmm/HyperV/)

## Suggestion/Issues ##

While there are no warranties of any kind, and there is no service or technical support
available for these scripts from IBM support, your comments are welcomed by the maintainers
and developers, who reserve the right to revise or remove the tools at any time. We,
maintainers and developers, will support the scripts posted in this repository. To report 
problems, provide suggestions or comments, please open a GitHub issue. If the scripts are
modified and have issues, we will do our best to assist.

<!-- A more detailed Usage or detailed explaination of the repository here -->
