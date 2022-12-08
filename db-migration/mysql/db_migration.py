#!/usr/bin/env python

###############################################################################################
#               The Main Script performs tasks on the source and the target server            #
###############################################################################################

##############################################################################################################################################################
## The below modules are used for the following purposes,                                                                                                   ##
## os                           - The os module used to interact with the underlying operating system where the script is being executed.                   ##
## sys                          - The sys module provides functions and variables used to manipulate different parts of the Python runtime environment.     ##
## Fabric                       - The fabric and its submodules are used to execute execute tasks and commands on a remote system through ssh               ##
## termcolor                    - To highlight the actions and headings on runtime                                                                          ##
## infra                        - To execute function defined on the source and target function files.                                                      ##
##############################################################################################################################################################

import sys
import os
from fabric import tasks
from termcolor import colored
from infra import source_server_function, target_server_function

def main():

#####################################################
#      Executing the tasks on the Source server     #
#####################################################

#Installing dependencies and mounting the bucket
    src_server_env = tasks.execute(source_server_function.server_setup)

# Backup the database dump and storing on the mounted volume
    backup = tasks.execute(source_server_function.database_backup)

#####################################################
#      Executing the tasks on the Target server    #
#####################################################

#Installing dependencies and mounting the bucket
    trgt_server_env = tasks.execute(target_server_function.server_setup)

#Restoring the database from the mounted volume
    restore = tasks.execute(target_server_function.restore_database)

    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow'))
    print(colored('               Database Migration Completed Successfully!!!  ', 'yellow'))
    print(colored('=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=', 'yellow')) 

if __name__ == '__main__':
    main()