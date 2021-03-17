### Link for detailed IBM documentation
- [IBM Cloud documentation for 'Migrating data from IBM Cloud classic infrastructure to VPC' ](https://cloud.ibm.com/docs/cloud-infrastructure?topic=cloud-infrastructure-data-migration-classic-to-vpc)

### How to execute script?
- Bash *<auto_rsync_file_name>* 
- Bash *<auto_rsync_file_name> --help* :- This will display all options for rsync command.

### How to debug?
- Uncomment following line before eval statement to print rsync command being executed.
- *'# echo "rsync $strOptions $strSourcePath $strUsername@$strRemoteHost:$strDestinationPath"'*

### Few things to know
- If connection is broken, if script is frozen or stopped for any reason then it will not be resumed automatically. User needs to rerun script.	 Next time it will pick from where it left.
- Windows File Attributes - Because Rsync works on top of the Cygwin Unix emulation layer, it does not recognize Windows file attributes (e.g. readonly, hidden, system, etc) or NTFS security attributes (i.e. access control lists). NTFS alternate data streams are also not supported, and as Unix does not have a concept of file creation time, this is also not preserved
- "C:\<directory_name>\<sub_driectory_name>\<file_name>" Path in windows/cygwin will be written/presented as "/cygdrive/c/<directory_name>/<sub_driectory_name>/<file_name>"
- A trailing slash on a source path means "copy the contents of this directory". Without a trailing slash it means "copy the directory".
- For windows shell script, use unix style end of line format to avoid error.
- Whenever user name is left blank, if source instance is windows then script will consider 'Administrator' as default user name, if source instance is linux then script will consider 'root' as default user name.

### Default options
- -- archive mode  -  equals -rlptgoD (no -H,-A,-X)
- -r, --recursive - This tells rsync to copy directories recursively.        -
- -l, --links - When symlinks are encountered, recreate the symlink on the destination.
- -p, --perms - This option causes the receiving rsync to set the destination permissions to be the  same  as  the source  permissions.
- -t, --times - This tells rsync to transfer modification times along with the files and update them on the remote system. 
- -g, --group - This option causes rsync to set the group of the destination file to be the  same  as  the  source file.
- -o, --owner - This option causes rsync to set the owner of the destination file to be the  same  as  the  source file,  but  only  if  the receiving rsync is being run as the super-user.
- -D     The -D option is equivalent to --devices --specials.
- -- update  -u, skip files that are newer on the receiver
- -- partial - keep partially transferred files
- --log-file=FILE - log what we're doing to the specified FILE
- -e 'ssh' -  specify the remote shell to use
- -- info=progress2 - grannular information based based on flag number.
- --recursive - recurse into directories
- --human-readable - output numbers in a human-readable format
- --compress -With this option, rsync compresses the file data as it is sent to the destination machine, which reduces the amount of data being transmitted -- something that is useful over a slow connection.
- --log-file=FILE - This option causes rsync to log what it is doing to a file
- --rsync-path=PROGRAM    specify the rsync to run on remote machine

### Custom options
- These are optional. Simply type *'--OptionName'* or leave blank. Some useful options are
- --bwlimit=KBPS :- limit I/O bandwidth; KBytes per second
- --exclude=PATTERN :- This option is a simplified form of the --filter option that defaults to an exclude rule and does not allow the full rule-parsing syntax of normal filter rules.
- [More option...](https://linux.die.net/man/1/rsync) 

### Make sure to have
- Source and destination should be reachable to each other through network.
- Destination machine as enough free space to accommodate all data to be transferred.
- High speed / good internet connection
- ssh working, public is placed at destination machine.
- rsync installed
