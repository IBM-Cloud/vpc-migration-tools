#!/usr/bin/env python

###############################################################################################
#               The Script executes database backup operation on the Source Server            #
###############################################################################################

##############################################################################################################################################################
## The below modules are used for the following purposes,                                                                                                   ##
## os                           - The os module used to interact with the underlying operating system where the script is being executed.                   ##
## pwinput                      - To mask the secret credentials.                                                                                           ##
## sys                          - The sys module provides functions and variables used to manipulate different parts of the Python runtime environment.     ##
## Fabric                       - The fabric and its submodules are used to execute commands on a remote system through ssh                                 ##
## termcolor                    - To highlight the actions and headings on runtime                                                                          ##
## time & datetime              - To show system date and time.                                                                                             ##
## tqdm                         - For setting up the progress bar                                                                                           ##
## infra.source_server_function - For mapping the variables defined on the source server function                                                           ##
##############################################################################################################################################################

import os
import pwinput
from fabric import tasks
from fabric.api import run,env,sudo,put
from fabric.api import settings
from fabric.network import disconnect_all
from fabric.context_managers import prefix
from termcolor import colored
from time import sleep
from datetime import date
from tqdm import tqdm
from fabric.state import output

#Supressing the stdout logs since it contains sensitive informations

output['everything'] = False

#####################################################
#      Executing the tasks on the Source server:    #
#####################################################

# Constants for IBM COS values

print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
print(colored('               Centralized Backup                            ', 'yellow'))
print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow')) 

#####################################################
#      Collecting the bucket details for Migration #
#####################################################

COS_BUCKET = input("Enter the Cloud Object Storage bucket name:")
print("Enter the Cloud Object Storage endpoint")
print(colored("For Example: https://s3.dal.us.cloud-object-storage.appdomain.cloud","yellow"))
COS_ENDPOINT = input("COS Endpoint:") # Current list avaiable at https://control.cloud-object-storage.cloud.ibm.com/v2/endpoints
COS_API_KEY_ID = pwinput.pwinput(prompt="Enter the IBM Cloud API Key:")

def server_setup():

    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Initiating Database Backup from Source        ', 'yellow'))
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow')) 

    # Source Server
    env.host_string = input("Enter the DB server IP or hostname:")

    # Set the username
    env.user   = input("Enter the username for the server:")

    # Password for the server:
    env.abort_on_prompts = True
    try:
        with settings(warn_only=False):
            env.password = pwinput.pwinput(prompt="Enter the password for the " + env.user + ":")
            m_date = run("date")
            print(colored("The Database Migration has been initiated on:" + m_date, 'red'))

    except SystemExit:
        print(colored('===============================================', 'red'))
        print(colored('HOST: ' + env.host_string + ' aborted on prompt', 'red'))
        print(colored('===============================================', 'red'))
        run("echo DB Migration closed :")

    print(colored("Setting up the source server to mount the bucket","magenta"))

    #Installing dependencies and mounting the bucket

    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Server Dependencies - Source                  ', 'yellow'))
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))

    with settings(warn_only=True):
        dis_result = run('which rpm')
        if dis_result.return_code == 0:
            os_result = run('hostnamectl | grep "Red Hat" ')
            if os_result.return_code == 0:
                redhat_version = run("os_version=$(grep '^VERSION_ID' /etc/os-release | awk -F'=' '{ print $2}' | cut -d. -f1); rhel=${os_version:1}; echo $rhel")
                print("********INSTALLING s3fs ON RPM BASED MACHINES***************")
                epel_install = run('rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-'+redhat_version+'.noarch.rpm')
                s3fs_install = run('yum install s3fs-fuse -y ')
                if s3fs_install.return_code == 0:
                    run("param=user_allow_other; sed -i '/^#$param/ c$param' /etc/fuse.conf")
                    print("Dependencies are Installed Successfully!!!")
                else:
                    print("Dependencies are not installed exiting!")
                    raise SystemExit()
            else:
                print("********INSTALLING s3fs ON RPM BASED MACHINES***************")
                s3fs_install = run('yum install epel-release -y && yum install s3fs-fuse -y ')
                if s3fs_install.return_code == 0:
                    run("param=user_allow_other; sed -i '/^#$param/ c$param' /etc/fuse.conf")
                    print("Dependencies are Installed Successfully!!!")
                else:
                    print("Dependencies are not installed exiting!")
                    raise SystemExit()

        else:
            print("********INSTALLING s3fs ON DEBIAN BASED MACHINES***************")
            s3fs_install = run('add-apt-repository main && apt-get install s3fs -y')
            if s3fs_install.return_code == 0:
                run("param=user_allow_other; sed -i '/^#$param/ c$param' /etc/fuse.conf")
                print("Dependencies are Installed Successfully!!!")
            else:
                print("Dependencies are not installed exiting!")
                raise SystemExit()

    #Mounting the Bucket using S3FS
    
    run('touch ~/.passwd_s3fs && chmod 600 ~/.passwd_s3fs')
    run("echo :" + COS_API_KEY_ID + "> ~/.passwd_s3fs")

    run("mkdir -p /mysqlbucket")
    run("echo sudo s3fs " + COS_BUCKET + " /mysqlbucket -o passwd_file=~/.passwd_s3fs  -o ibm_iam_auth -o url="+COS_ENDPOINT +" > /tmp/mount.sh")
    run("chmod +x /tmp/mount.sh && sh /tmp/mount.sh")
    
    #Creating the cred file
    run('touch ~/.mysqldump.cnf && chmod 600 ~/.mysqldump.cnf')


 

def database_backup():

    # Backup the database dump and storing on the mounted volume
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Initiating DataBase Backup - Source           ', 'yellow'))
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow')) 

    # Database Server Credentials for migration
    DB_USER = input("Enter the username for mysql:")
    DB_USER_PASSWORD = pwinput.pwinput(prompt="Enter the password for mysql user:")
    SOURCE_DB_NAME = input("Enter the database that has to be migrated[Backup]:")
    run("mkdir -p /mysqlbucket/"+SOURCE_DB_NAME)
    BACKUP_PATH = "/mysqlbucket/"+ SOURCE_DB_NAME

    run("echo [mysqldump] > ~/.mysqldump.cnf")
    run("echo password=" + DB_USER_PASSWORD + ">> ~/.mysqldump.cnf")
        
    for i in tqdm(range(1), desc="Backup progress", position=0, leave=True):
        run("mysqldump --defaults-file=~/.mysqldump.cnf -u " + DB_USER + " " + SOURCE_DB_NAME + " > " + BACKUP_PATH + "/" + SOURCE_DB_NAME + ".sql")
        sleep(0.01)
        
    #Cleaning up the creds
    run("umount /mysqlbucket")
    run("rm -rf ~/.passwd_s3fs ~/.mysqldump.cnf")

disconnect_all() # To disconnect from the server    
