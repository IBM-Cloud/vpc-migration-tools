#!/usr/bin/env python

###############################################################################################
#               The Script executes database restoration operation on the Target Server       #
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
from infra.source_server_function import COS_ENDPOINT
from infra.source_server_function import COS_BUCKET
from infra.source_server_function import COS_API_KEY_ID

#Supressing the stdout logs since it contains sensitive informations

output['everything'] = False

#####################################################
#      Executing the tasks on the Target server:    #
#####################################################

def server_setup():

    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Restoring Database on the Target              ', 'yellow'))
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow')) 

    # Target Server
    env.host_string = input("Enter the target DB server IP or hostname:")

    # Set the username
    env.user   = input("Enter the username for the server:")

    # Password for the server:
    env.abort_on_prompts = True
    try:
        with settings(warn_only=False):
            env.password = pwinput.pwinput(prompt="Enter the password for the " + env.user + ":")
            t_date = run("date")
            print(colored("The Database Restoration on the target initiated on:" + t_date, 'red'))

    except SystemExit:
        print(colored('===============================================', 'red'))
        print(colored('HOST: ' + env.host_string + ' aborted on prompt', 'red'))
        print(colored('===============================================', 'red'))
        run("echo DB Migration closed :")

    print(colored("Setting up the target server to mount the bucket","magenta"))

    #Installing dependencies and mounting the bucket

    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Server Dependencies - Target                  ', 'yellow'))
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
    run('touch ~/.mysql.cnf && chmod 600 ~/.mysql.cnf')

def restore_database():

    #Restoring the database from the mounted volume
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Restoring DataBase Backup                     ', 'yellow'))
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow')) 

    # Create target db resource
    DB_USER = input("Enter the username for mysql:")
    DB_USER_PASSWORD = pwinput.pwinput(prompt="Enter the password for mysql user:")
    SOURCE_DB_NAME = input("Enter the Source Database Name:")
    TARGET_DB_NAME = input("Enter the new name for the database, Leave null if you continue with the previous database name:")
    DB_BACKUP_PATH = "/mysqlbucket/"+SOURCE_DB_NAME+"/"+SOURCE_DB_NAME+".sql"

    run("echo [mysql] > ~/.mysql.cnf")
    run("echo password=" + DB_USER_PASSWORD + ">> ~/.mysql.cnf")

    # Mapping the Database backup path for restoration
    
    if TARGET_DB_NAME == '':
        # Restoration command on the target server
        for i in tqdm(range(1), desc="Restore progress", position=0, leave=True):
            res = run("mysql --defaults-file=~/.mysql.cnf -u" + DB_USER + " -e  \"create database " + SOURCE_DB_NAME + "; use " + SOURCE_DB_NAME + "; \. " + DB_BACKUP_PATH + "\"")
            sleep(0.01)
    else:
        # Restoration command on the target server
        for i in tqdm(range(1), desc="Restore progress", position=0, leave=True):
            res = run("mysql --defaults-file=~/.mysql.cnf -u" + DB_USER + " -e  \"create database " + TARGET_DB_NAME + "; use " + TARGET_DB_NAME + "; \. " + DB_BACKUP_PATH + "\"")
            sleep(0.01)
            
            
    #Cleaning up the creds
    run("umount /mysqlbucket")
    run("rm -rf ~/.passwd_s3fs ~/.mysql.cnf")
         
disconnect_all() # To disconnect from the server
