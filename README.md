# VPC Migration Tools

This repository provides access to different tools and solutions that you can use when migrating your infastructure to IBM Cloud VPC.  The tools include  individual custom scripts and open source utilities.  You can use the tools as is or you can modify them to fit your needs. As a recommended
practice, carefully review any materials from this repository before you use them on any live systems.

## Pre Validation Check Scripts ##

There are minimum requirements for migrating an existing guest machine image to IBM Cloud VPC as a custom image.  The image must:

* Contain a single file or volume.
* Be in `qcow2` format and have .qcow2 file extension.
* Be cloud-init enabled.
* Use an operating system that is supported as a stock image operating system.

For more information about managing images, see [link](https://cloud.ibm.com/docs/vpc?topic=vpc-managing-images).

Use these custom scripts to validate the candidate guest machine.

- [Redhat Precheck Script](Linux-Precheck-Srcripts/)
- [New custom Windows Prep Script for Importing](Create-Windows-Import/)

## Data Migration ##

There are many tools available to migrate data from the source to the target machine. This
script uses an open source utility `rsync` with the some default commands. 

[rysnc script](data-migration/)

## Suggestion/Issues ##

While there are no warranties of any kind, and there is no service or technical support
available for these scripts from IBM support, your comments are welcomed by the maintainers
and developers, who reserve the right to revise or remove the tools at any time. We,
maintainers and developers, will support the scripts posted in this repository. To report 
problems, provide suggestions or comments, please open a GitHub issue or email us at
[email_distribution_list](mailto:blah@ibm.com?subject=[GitHub]%20VPC%20Migration%20Scripts). If the
scripts are modified and have issues, we will do our best to assist.

<!-- A more detailed Usage or detailed explaination of the repository here -->
