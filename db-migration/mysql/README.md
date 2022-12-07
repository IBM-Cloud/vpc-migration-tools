# MySQL database migration using Python

The MySQL database migration script allows you to migrate MySQL databases from one server to another. This is applicable to any platform:

* IBM classic infrastructure to IBM Cloud VPC
* On-premises to IBM Cloud VPC
* Other cloud service providers to IBM Cloud VPC

## Prerequisites

Review the following prerequisites before you begin your migration:

1. Set up an IBM Cloud Object Storage bucket.
2. Make sure that you have access to write to IBM Cloud Object Storage bucket.
3. Make sure that you have connection to the source and target server from your system.
4. Ensure that Python3 (version 3.0) and Pip3 are installed on your system.

## Cloning and running the database migration script

Complete the following steps to clone and run the database migration script:

1. Run the following commands to clone the public GitHub repository:

    ```
    git clone https://github.com/IBM-Cloud/vpc-migration-tools.git
    ```

    ```
    cd vpc-migration-tools/mysql-db-migration
    ```

2. Install the prerequisites modules for Python using pip or pip3 by running the following commands:

    ```
    pip3 install -U pip setuptools
    ```

    ```
    pip3 install -r requirements.txt
    ```

    `setuptools` facilitate packaging Python projects by enhancing the Python standard library distutils. The `requirements.txt` files install the Python libraries that are required in the script.
    
3. Run the following database migration script:

    ```
    python3 db_migration.py
    ```

    or

    ```
    python db_migration.py
    ```

After running the database migration script `python3 db_migration.py`, you need to provide the details for the following parameters:
* Mount Object Storage bucket
* Source Server Details
* Source server database details
* Target server details
* Target server database details

## Mount Object Storage bucket

The IBM Cloud Object Storage bucket acts as centralized storage for the source and the target server. By using the `s3fs` utility, the bucket is mounted as a file system on both the source and target server. 
The source uses the bucket to store the database backup, and the target uses the bucket to retrieve the database backup, which minimizes the migration duration.

Complete the following steps to mount the IBM Cloud Object Storage bucket:

* COS Bucket name - Name of the bucket which has been already provisioned.

  ```
  Enter the Cloud Object Storage bucket name: `my-db-bucket`
  ```

* COS Endpoint - The COS endpoint helps to identify the location of the bucket.

  ```
  Enter the Cloud Object Storage endpoint.
  For Example: https://s3.dal.us.cloud-object-storage.appdomain.cloud
  COS Endpoint: https://s3.dal.us.cloud-object-storage.appdomain.cloud
  ```

In this example, the bucket is located in the US-South Dallas region. To know more about endpoints refer the below link:
[Endpoints and storage locations](/docs/cloud-object-storage?topic=cloud-object-storage-endpoints).

* IBM Cloud API Key - It authenticates the user to perform actions on the provided bucket. The user should be able to write privileges on the COS bucket.

    ```
    Enter the IBM Cloud API Key:YOU_API_KEY
    ```

For more details on creating an API key, see [Creating an IBM Cloud API key](https://www.ibm.com/docs/en/app-connect/containers_cd?topic=servers-creating-cloud-api-key).

## Source Server Details

* Source server IP or hostname - It is the source in which the MySQL database has to be migrated.

    ```
    Enter the DB server IP or hostname: 58.25.x.x or my.db-src.server
    ```

This would be the IP address or Hostname of the source db server.

* Source server credentials - The script needs to be authenticated with the username and password. The user privileges should be equivalent to the `root`.

    * Source server username
    * Source server password

    ```
    Enter the username for the server: root
    Enter the password for the root user: PWD
    ```

## Source server database details

* Source server MySQL connection details - Username for the mysql application, root by default.

    ```
    Enter the username for mysql: root
    ```

* Password for the mysql user - To authenticate the mysql user to preform actions on the selected database for migration.

    ```
    Enter the password for mysql user: PWD
    ```

* Database name - This is the database name which is marked for migration.

    ```
    Enter the database that has to be migrated[Backup]: test_db
    ```

## Target server details

* Target server IP or hostname - It is the target server where the mysql database will be migrated.

    ```
    Enter the DB server IP or hostname: 52.96.x.x or my.db-trgt.server
    ```

* Target server credentials - The script needs to be authenticated with the username and password. The user privilege should be equivalent to root.

    * Target server username
    * Target server password

    ```
    Enter the username for the server: root
    Enter the password for the root user: PWD
    ```

## Target server database details

* Target server MySQL connection details - Username for the mysql application, root by default.

    ```
    Enter the username for mysql: root
    ```

* Password for the MySQL user - To authenticate the mysql user to perform the actions to restore the database.

    ```
    Enter the password for mysql user: PWD
    ```

* Database name - It is the database name which is marked for migration from the source server.

    ```
    Enter the database that has to be migrated[Backup]: test_db
    ```

* Target database name - By default, this will fetch the database name from the source database name. If the user wants to have a different database name for migration, then they can provide the input as per their requirement.

    ```
    Enter the new name for the database, leave null if you continue with the previous database name: test_db_dev
    ```

After successful database migration, you will be prompted with a complete message.
