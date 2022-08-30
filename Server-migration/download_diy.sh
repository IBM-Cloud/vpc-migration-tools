#!/bin/bash
sudo apt-get update -y
sudo apt-get install nmap -y |
sudo apt-get install qemu-kvm -y |
curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
| ibmcloud plugin install vpc-infrastructure
| ibmcloud plugin install cloud-object-storage

mkdir -p /opt/diy-migration-appliance/scripts
cd /opt/diy-migration-appliance/scripts
if [[ $? -ne 0 ]]
then
 echo "Failed while creating directory /opt/diy-migration-appliance/scripts"
 exit 1
else
 echo "Directory /opt/diy-migration-appliance/scripts created"
fi
for f in Appliance-new.sh config config-with-values cronjobscheduler.sh ibmcloudloginstatus.sh linux_precheck.sh migration.sh windows_precheck.ps1 
 do
  response=$(curl -so ${f} -w "%{http_code}" https://raw.githubusercontent.com/sateesh2954/diy-migration-appliance/main/Scripts/${f})
   if [ "$response" -eq "200" ]; then
    echo "${f} download complete - /opt/diy-migration-appliance/Scripts, http response code is: $response" >>/var/log/diy_download_script.log
   else
    echo "Failed downloading  ${f} to /opt/diy-migration-appliance/Scripts, http response code is $response" >>/var/log/diy_download_script.log
    exit 1
   fi
 done
echo "Updating /opt/diy-migration-appliance/Scripts permission" >>/var/log/diy_download_script.log
chmod +x *
