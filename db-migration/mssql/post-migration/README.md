# Post migration activities script
1. Download scripts from https://github.com/IBM-Cloud/vpc-migration-tools/tree/main/data-migration/db-migration/mssql/ 
   1. host-execute-powershell
   2. rejoin_domain.ps1 
2. Copy both files to RMM server under following directory.
```/opt/rackware/utils/pre-post-scripts/```
3. Assing execute permission to file as follows :
```chmod +x /opt/rackware/utils/pre-post-scripts/host-execute-powershell```
4. Perform following actions in RMM Web UI :
   1. Enter correct DNS IP address to be replicated in target server in ‘Replicate DNS Setting’ e.g., 52.117.162.120 
   2. Enter path of host-execute-powershell script in field ‘Event Script’ e.g., /opt/rackware/utils/pre-post-scripts/host-execute-powershell 
   3. Enter correct comma separated list of parameters in ‘Event Script Args’ in following sequence 
   ```<user_account>,<target_ip>,<domain_name>,<domain_user_id>,<password>, <pre or post>```
      1. user_account – username for target machine to login. E.g SYSTEM
      2. Target_ip – IP address of target machine where script is supposed to be executed. 
      3. Domain_name – Name of domain for target clusters. E.g., contoso.com 
      4. Domain_user_id – User account id for domain. E.g., Administrator
      5. Password – Password for <domain_name/domain_user_id> in plain text. E.g., Password for contoso.com\Administrator 
      6. Pre or post – When script is supposed to be executed. Before or after migration. In this case, script is supposed to be executed after migration so its value should be ‘Post’ 
      ```Note: avoid spaces before or after comma```
e.g., ```SYSTEM,169.61.196.118,contoso.com,Administrator,<DOMAIN_ACCOUNT_PASSWORD>, Post```
5. In case if you encounter issue ```Post-event script reported failure (exit status = 0)``` then execute ```rejoin_domain.ps1``` directly on target node machine. Such error may be cause because of ```ssh: connect to host 192.168.xxx.xxx port 22: Connection refused``` or any other error.
6. Finally you can modify script to do any more post migration activities which are possible using powershell scripting.
7. Log for powershell script actions will be created on target windows node machine with path ```C:\rejoin_domain.log```
8. Log for shell script actions will be created on RMM server with path ```/var/log/rackware/pre-post-script.log```

## Suggestions / issues / support
While there are no warranties of any kind, and there is no service or technical support available for these scripts from IBM support, your comments are welcomed by the maintainers and developers, who reserve the right to revise or remove the tools at any time. We, maintainers and developers, will support the scripts posted in this repository. To report problems, provide suggestions or comments, please open a GitHub issue. If the scripts are modified and have issues, we will do our best to assist.

For RMM documentation [click here](https://www.rackwareinc.com/rackware-rmm-users-guide-for-ibm-cloud)
