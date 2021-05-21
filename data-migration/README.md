# Overview

This is a wrapper script for rsync. Rsync is an open source utility to transfer and synchronize files between compute resources. Rsync has many options to choose from.

The wrapper script uses a handful of options (see below) such as compression-enabled or SSH. The script is flexible enough to allow other rsync options. The script can be used in either Linux or Windows operating systems. For Windows, you need to download [cywgin](https://www.cygwin.com/).

While rysnc is very useful for data migration, do your research to make sure it is suitable for your requirements and test it prior to using it in production.

## Usage
How do I run scripts?
```bash
bash <auto_rsync_file_name> [--help]
```
 OR
```bash
bash <auto_rsync_file_name> [--debug] [--skip_disk_check]
```
## Optional parameters to script
- --help :- This displays all of the options for the rsync command.
- --debug :- This displays rsync command being run for testing and debugging purposes, along with actual execution of script.
- --skip_disk_usage :- This will skip execution of free disk space check at destination.
- All aforementioned parameters are optional. If *--help* option is used along with others then it will get precedence.

## Default options
Options | Description
--------|------------
-a, --archive | Archive mode; equals -rlptgoD (no -H,-A,-X)
-r, --recursive | This tells rsync to copy directories recursively.
-l, --links | When symlinks are encountered, recreate the symlink on the destination.
-p, --perms | This option causes the receiving rsync to set the destination permissions to be the same as the source  permissions.
-t, --times | This tells rsync to transfer modification times along with the files and update them on the remote system. 
-g, --group | This option causes rsync to set the group of the destination file to be the same as the source file.
-o, --owner | This option causes rsync to set the owner of the destination file to be the same as the source file, but only if the receiving rsync is being run as the super-user.
-D | The -D option is equivalent to --devices --specials.
-u, -- update | Skip files that are newer on the receiver.
-- partial | Keep partially transferred files.
--log-file=FILE | Log what you are doing to the specified FILE.
-e 'ssh' | Specify the remote shell to use.
-- info=progress2 | Granular information based on flag number.
--recursive | Recurse into directories.
--human-readable | Output numbers in a human-readable format.
--compress | With this option, rsync compresses the file data as it is sent to the destination machine, which reduces the amount of data being transmitted, which is useful over a slow connection.
--log-file=FILE | This option causes rsync to log what it is doing to a file.
--rsync-path=PROGRAM | Specify the rsync to run on the remote machine.

## Custom options
These are optional. Simply type *'--OptionName'* or leave blank.

Options | Description
--------|-----------
--bwlimit=KBPS | Limit I/O bandwidth; KBytes per second
--exclude=PATTERN | This option is a simplified form of the --filter option that defaults to an exclude rule and does not allow the full rule-parsing syntax of normal filter rules.

For more options, see the [rsync manual](https://linux.die.net/man/1/rsync).

## How do I debug?
Uncomment the following line before eval statement to print rsync command being executed. <br>
`# echo "rsync $strOptions $strSourcePath $strUsername@$strRemoteHost:$strDestinationPath"`

## Tips
Here is some guidance when using this script:
- Source and destination should be reachable to each other through a network.
- Destination machine has enough free space to accommodate all transferred data.
- High speed / good internet connection. It's recommended to have high NIC speed and use transit gateway to utilize IBM backbone.
- Make sure to have SSH working and have the public key placed at the destination machine.
- Make sure that rsync is installed.

## Few things to know
- If connection is broken or if script is frozen or stopped for any reason, then it does not resume automatically. You need to rerun the script.	Next time it picks up from where it left off.
- Windows File Attributes - Because rsync works on top of the Cygwin Unix emulation layer, it does not recognize Windows file attributes (e.g. readonly, hidden, system, etc) or NTFS security attributes (i.e. access control lists). NTFS alternate data streams are also not supported, and as Unix does not have a concept of file creation time, this is also not preserved
- "C:\<directory_name>\<sub_driectory_name>\<file_name>" Path in windows/cygwin will be written/presented as "/cygdrive/c/<directory_name>/<sub_driectory_name>/<file_name>"
- A trailing slash on a source path means "copy the contents of this directory". Without a trailing slash, it means "copy the directory".
- For the Windows shell script, use Unix style end-of-line format to avoid errors.
- If the source instance is Windows and the user name is left blank, then the script considers 'Administrator' as the default user name. If the source instance is Linux, then the script considers 'root' as the default user name.

# Additional resources
- How-to guide for [Migrating data from IBM Cloud classic infrastructure to VPC](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-data-migration-classic-to-vpc)
- [Rsync manual](https://linux.die.net/man/1/rsync)