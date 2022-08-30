#----------------------------------------------------------------------------------------------------------------------
# Script Name :  windows_precheck.ps1   
# This script will check all pre-requisites for 
# Virtio Driver, Cloud-Init, Administrator files backup
#----------------------------------------------------------------------------------------------------------------------

function isValidOs() {
	try {
		$boolIsValid = $False;
		$arrstrAllowedOSes = @( 'Microsoft Windows Server 2019 Standard', 'Microsoft Windows Server 2016 Standard','Microsoft Windows Server 2012 R2 Standard','Microsoft Windows Server 2012 Standard');
		$strOsName = ( Get-WmiObject -Class win32_operatingsystem ).caption;
		$arrstrAllowedOSes | ForEach-Object { if ( $strOsName.toLower().Contains( $_.toLower() ) ) { $boolIsValid = $True; } };		
	} catch {
		Write-Host "`nError occurred while checking operating system. $_" -ForegroundColor Red;
	}
	return $boolIsValid;
}
function isApplicationPresent( $strApplicationName ) {
	try {
		$boolIsPresent = $False;
		$strApplicationName = Get-CimInstance win32_product | Where-Object { $_.Name -like $strApplicationName } | Select-Object Name;
		if( $null -ne $strApplicationNamxe ) {
			$boolIsPresent = $True;
		}
	} catch {
		Write-Host "`nError occurred while checking application : $strApplicationName. $_" -ForegroundColor Red;
	}
	return $boolIsPresent;
}
function installSoftware( $strSourcePath, $strInstalledPath ) {
		Write-Host "`nInstalling application : $strSourcePath" -ForegroundColor Yellow;
		Write-Host "`nPlease wait for few moments..." -ForegroundColor Yellow;
     try {   
		Start-Process -Wait -FilePath $strSourcePath -ArgumentList "/qn";
        if (test-path $strInstalledPath){
            Write-Host "`nApplication $strSourcePath is installed!" -ForegroundColor Green;
            $installStatus = "Passed"
        }else{
            $installStatus = "Failed"
        }
	} catch {
		Write-Host "`nError occurred while installing application : $strSourcePath $_" -ForegroundColor Red;
	    $installStatus = "Failed" 
    }
    return $installStatus
}
function copyFile( $strOldFileName, $strNewFileName ) {
	try {
		Copy-Item -Path $strOldFileName -Destination $strNewFileName;
	} catch {
		Write-Host "`nError occurred while copying file : $strOldFileName $_" -ForegroundColor Red;
	}
}
function backupFile( $strPath, $strRenamedConfigFile ) {
	try {
        Write-Host "`nChecking whether backup exist for config file : $strPath" -ForegroundColor Yellow;
		if( -Not ( Test-Path -Path $strRenamedConfigFile ) ) {
			Write-Host "`nCreating backup of config file : $strPath" -ForegroundColor Yellow;
            Copy-Item -Path $strPath -Destination $strRenamedConfigFile;
		}
        else{
        Write-Host "`nAleady backup exist for config file : $strPath" -ForegroundColor Yellow;
        }		
	} catch {
		Write-Host "`nError occurred while creating backup copy : $strPath. $_" -ForegroundColor Red;
	}
}
function removeConfig( $strPath ) {
	try {
		Remove-Item $strPath ;
		Write-Host "`nRemoving config file : $strPath" -ForegroundColor Yellow;
	} catch {
		Write-Host "`nError occurred while removing configuration file : $strPath. $_" -ForegroundColor Red;
	}
}
function createConfig( $strPath, $strFileContent ) {
	try {
		Set-Content -Path $strPath -Value $strFileContent;
		Write-Host "`nCreated config file : $strPath" -ForegroundColor Yellow;
	} catch {
		Write-Host "`nError occurred while creating configuration file : $strPath. $_" -ForegroundColor Red;
	}
}
function installCertificate( $strCertifiateDir ) {
	try {
		$objCertStore = Get-Item "cert:\LocalMachine\TrustedPublisher";
		$objCertStore.Open( [ System.Security.Cryptography.X509Certificates.OpenFlags ]::ReadWrite );
	
		Get-ChildItem -Recurse -Path $strCertifiateDir -Filter "*.cat" | ForEach-Object {
			$objCertificate = ( Get-AuthenticodeSignature $_.FullName ).SignerCertificate;
			Write-Host ( "`nInstalled certificate - {0}, {1} from {2}" -f $objCertificate.Thumbprint, $objCertificate.Subject, $_.FullName ) -ForegroundColor Yellow;
			$objCertStore.Add( $objCertificate );
		}	
		$objCertStore.Close();
	} catch {
		Write-Host "`nError occurred while installing certificates. $_" -ForegroundColor Red;
	}
}
function isValidVersion( $strMinimumVersion, $strCurrentVersion ) {
	$boolIsValid = $False;
	$strMinimumVersion = [version] $strMinimumVersion;
	$strCurrentVersion = [version] $strCurrentVersion;

	if( $strCurrentVersion -ge $strMinimumVersion ) {
		$boolIsValid = $True;
    } 

	return $boolIsValid;
}
function getVersion( $strApplicationName ) {
	try	{
		$strVersion = Get-WmiObject -Class Win32_Product | Where-Object Caption -like $strApplicationName | Select-Object -Expand version;
	} catch {
		Write-Host "`nError occurred checking for version of $strApplicationName. $_" -ForegroundColor Red;
	}

	return $strVersion;
}
function setSecurityProtocol() {
	try {
		[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Ssl3;
		[Net.ServicePointManager]::SecurityProtocol = "Tls, Tls11, Tls12, Ssl3"; 	
	} catch {
		Write-Host "`nFailed to set security protocol. $_" -ForegroundColor Red;
	}
}
function getCertificatePath( $strDriveLetter ) {
	$strPath = "";
	$strOsName = ( Get-WmiObject -Class win32_operatingsystem ).caption;

	switch ( $strOsName ) {
		"Microsoft Windows Server 2019 Standard" { $strPath = "$strDriveLetter\amd64\2k19"; Break; }
		"Microsoft Windows Server 2016 Standard" { $strPath = "$strDriveLetter\amd64\2k16"; Break; }
		"Microsoft Windows Server 2012 R2 Standard" { $strPath = "$strDriveLetter\amd64\2k12R2"; Break; }
		"Microsoft Windows Server 2012 Standard" { $strPath = "$strDriveLetter\amd64\2k12"; Break; }
		"Microsoft Windows Server 2019 Standard Evaluation" { $strPath = "$strDriveLetter\amd64\2k19"; Break; }
		"Microsoft Windows Server 2016 Standard Evaluation" { $strPath = "$strDriveLetter\amd64\2k16"; Break; }
		"Microsoft Windows Server 2012 R2 Standard Evaluation" { $strPath = "$strDriveLetter\amd64\2k12R2"; Break; }
		"Microsoft Windows Server 2012 Standard Evaluation" { $strPath = "$strDriveLetter\amd64\2k12"; Break; }
		Default { $strPath = ""; }
	}
	return $strPath;
}
function checkAndCreateDir( $strPath ) {
	try {
		$isTempDirPresent = Test-Path -Path $strPath; 
		if( $False -eq $isTempDirPresent ) {
			New-Item -ItemType "directory" -Path $strPath | Out-Null;
		}		
	} catch {
		Write-Host "`nFailed to create $strPath directory. $_" -ForegroundColor Red;
	}
}
function copy_directory( $userpath, $backuppath ) {
	$takeown = $backuppath
	$backuppath = $backuppath + "Administrator\"
    Write-host "Backing up Administrator User Documents.. ( $userpath to $backuppath ) " -ForegroundColor yellow;
    try {
        if ( ! (test-path $backuppath)){
            New-Item -ItemType directory -Force -Path $backuppath;
        }
        #Directory copy
		get-childitem -Path $userpath | ForEach-Object{
		   	$content = $_.FullName;
		   	$backupdir = $backuppath + $content.Split("\")[-1];
		   	#exclude *ini file to show as music folder as normal folder else music will shown with music icon
		   	robocopy $content $backupdir /MIR /COPYALL /R:0 /W:0 /xf NTUSER.DAT ntuser* /xd 'C:\Users\Administrator\Application Data' 'C:\Users\Administrator\Local Settings' 'C:\Users\Administrator\AppData';
            }
        #files copy
        get-childitem -Path $userpath -Attributes !Directory | ForEach-Object{
            $content = $_.FullName;
            $srcpath = $content.Split("\")[-1];
            robocopy $userpath $backuppath $srcpath
        }
		takeown /a /r /d Y /f $takeown
        $adminbackupstatus = "$True";
        } 
    catch {
            Write-Host “Error occured in copy method.” -ForegroundColor Red;
            $adminbackupstatus = $False;
        }
    Start-Sleep -s 5
    return $adminbackupstatus;
}
function download_file($url, $targetFile)
{
    try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12
    $uri = New-Object "System.Uri" "$url"
    $request = [System.Net.HttpWebRequest]::Create($uri)
    $request.set_Timeout(15000) #15 second timeout
    $response = $request.GetResponse()
    $totalLength = [System.Math]::Floor($response.get_ContentLength()/1024)
    $responseStream = $response.GetResponseStream()
    $targetStream = New-Object -TypeName System.IO.FileStream -ArgumentList $targetFile, Create
    $buffer = new-object byte[] 1000KB
    $count = $responseStream.Read($buffer,0,$buffer.length)
    $downloadedBytes = $count
    while ($count -gt 0)
    {
       $targetStream.Write($buffer, 0, $count)
       $count = $responseStream.Read($buffer,0,$buffer.length)
       $downloadedBytes = $downloadedBytes + $count
       Write-Progress -activity "Downloading file '$($url.split('/') | Select -Last 1)'" -status "Downloaded ($([System.Math]::Floor($downloadedBytes/1024))K of $($totalLength)K): " -PercentComplete ((([System.Math]::Floor($downloadedBytes/1024)) / $totalLength)  * 100)
   }
   Write-Progress -activity "Finished downloading file '$($url.split('/') | Select -Last 1)'"
   $targetStream.Flush()
   $targetStream.Close()
   $targetStream.Dispose()
   $responseStream.Dispose()
   $downloadstatus = $True
   }
   catch {
    Write-Host "Download failed” -ForegroundColor Red;
    $downloadstatus = $False
   }
   return $downloadstatus
}
function summary() {
   
    Write-Host "`n`n ---------------------------------------------------------------------" -ForegroundColor Yellow;
    Write-Host "                                   Summary" -ForegroundColor Yellow;
    Write-Host " ---------------------------------------------------------------------" -ForegroundColor Yellow;
	
    Write-Host -ForegroundColor Cyan "Operating System:- " (Get-WmiObject -class Win32_OperatingSystem).Caption
    $tableTest = $queueTable | Format-Table | Out-String -Stream
	$tableTest[0..2] | Write-Host -ForegroundColor Yellow; Write-Host 
	for ($i=0; $i -lt $queueTable.Rows.Count; $i++) {
    	if ($queueTable.Rows[$i].Status -eq "Failed") { 
        	$tableTest[$i+3] | Write-Host -ForegroundColor Red -NoNewline; Write-Host 
		}
    	else { $tableTest[$i+3] | Write-Host -ForegroundColor Green -NoNewline; Write-Host 
		}
	}
     Write-Host -ForegroundColor Cyan "Pre-check script has Completed"
}
function manualsteps() {
	Write-Host "Please do Network reset and sysprep, Before running migration script" -ForegroundColor Yellow;
}

function main() {
	# Steps :
	# check cloudbase-init installation
	# check cloudbase-init version
	# download cloudbase-init if its not present
	# install cloudbase-init publisher certificates
	# install cloudbase-init
	# backup cloudbase-init config
	# modify cloudbase-init config
	# check virtio driver installation
	# check virtio driver version
	# download virtio driver iso
	# install virtio publisher certificates
	# install virtio drivers 
    
    
    
	Set-Variable -Name "MINIMUM_VERSION_CLOUDBASE_INIT" -Value "1.1.0" -Option Constant;
	Set-Variable -Name "MINIMUM_VERSION_VIRTIO_DRIVERS" -Value "0.1.185" -Option Constant;
	Set-Variable -Name "DOWNLOAD_URL_CLOUDBASE_INIT" -Value "https://cloudbase.it/downloads/CloudbaseInitSetup_Stable_x64.msi" -Option Constant;
	Set-Variable -Name "DOWNLOAD_URL_VIRTIO_DRIVERS" -Value "https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso" -Option Constant;
	Set-Variable -Name "DIR_TEMP" -Value 'C:\temp' -Option Constant;
	Set-Variable -Name "ADMIN_USER_PATH" -Value "C:\Users\Administrator\" -Option Constant;
    Set-Variable -Name "ADMIN_USER_BACKUP_PATH" -Value "C:\backup\" -Option Constant;
    
    # Creating the table for summary
    $queueTable = New-Object System.Data.DataTable
    $queueTable.Columns.Add("Check",[string]) | Out-Null
    $queueTable.Columns.Add("Status",[string]) | Out-Null

    checkAndCreateDir -strPath $DIR_TEMP;
	$strCloudbaseInitMsiFileName = 'CloudbaseInitSetup_Stable_x64.msi';
	$strVirtIoIsoFileName = 'virtio-win.iso';
	$strCloudbaseInitPath = "$DIR_TEMP\$strCloudbaseInitMsiFileName";
	$strVirtIoIsoPath = "$DIR_TEMP\$strVirtIoIsoFileName";
    $strVirtIoInstalledPath = "C:\Program Files\Virtio-Win";
    $strCloudbaseInitInstalledPath = "C:\Program Files\Cloudbase Solutions";
	$boolIsAllowedVersion = $False;

    ###############################################
    ################# Os Check ####################
    ###############################################
	$boolIsAllowedOs = isValidOs;
	$strOsName = ( Get-WmiObject -Class win32_operatingsystem ).caption;
	if ( $False -eq $boolIsAllowedOs ) {
		Write-Host "`n'$strOsName' operating system is not compatible with migration process. Exiting script..." -ForegroundColor Red;
		$queueTable.Rows.Add("OS Check","Failed") | Out-Null       
        Exit;
	} else {
		Write-Host "`n'$strOsName' operating system is compatible with migration process." -ForegroundColor Yellow;
	    $queueTable.Rows.Add("OS Check","Passed") | Out-Null        
    }
    ###############################################
    ######## Administrator files backup ###########
    ###############################################
    $adminbackupstatus = copy_directory -userpath $ADMIN_USER_PATH -backuppath $ADMIN_USER_BACKUP_PATH;
    if ( $True -eq $adminbackupstatus ) {
		Write-Host "`nAdministrator files backup successful" -ForegroundColor Yellow;
        $queueTable.Rows.Add("Administrator Files Backup","Passed") | Out-Null        
	} else {
		Write-Host "`nAdministrator files backup failed" -ForegroundColor Red;
        $queueTable.Rows.Add("Administrator Files Backup","Failed") | Out-Null        
	}
    ##############################################
    ######## Virtio Driver Installation ##########
    ##############################################
    $boolIsVirtIoPresent = isApplicationPresent -strApplicationName "Virtio-win*";
	$boolIsAllowedVersionForVirtIo = $False;
	if( $boolIsVirtIoPresent -eq $True ) {
		$strCurrentVersionVirtIo = getVersion -strApplicationName "Virtio-win*";
		Write-Host "`nFound VirtIO driver $strCurrentVersionVirtIo in system." -ForegroundColor Yellow;
		$boolIsAllowedVersionForVirtIo = isValidVersion -strMinimumVersion $MINIMUM_VERSION_VIRTIO_DRIVERS -strCurrentVersion $strCurrentVersionVirtIo;
		if ( $False -eq $boolIsAllowedVersionForVirtIo ) {
			Write-Host "`nVersion $strCurrentVersionVirtIo of VirtIO driver is incompatible with migration process. Please Uninstall Virtio Driver and Re-run the script ." -ForegroundColor Yellow;
			#Write-Host "`nVersion $strCurrentVersionVirtIo of VirtIO driver is incompatible with migration process. Need to install recent version of VirtIO driver." -ForegroundColor Yellow;
	        $queueTable.Rows.Add("Virtio Driver","Failed") | Out-Null            	
    } else {
			Write-Host "`nVersion $strCurrentVersionVirtIo of VirtIO driver is compatible with migration process." -ForegroundColor Yellow;
	        $queueTable.Rows.Add("Virtio Driver","Passed") | Out-Null            	
    }
	}
	#if( $boolIsAllowedVersionForVirtIo -eq $False -or $boolIsVirtIoPresent -eq $False ) {
	if( $boolIsVirtIoPresent -eq $False ) {
		setSecurityProtocol;       
		if( -not ( Test-Path $strVirtIoIsoPath ) ) {
            Write-Output "Downloading Virtio Driver"
            $downloadstatus = download_file -url $DOWNLOAD_URL_VIRTIO_DRIVERS -targetFile $strVirtIoIsoPath;
            $trycount = 0
            while (($downloadstatus -eq $False) -and ($trycount -ne 5 )) {
                Write-Output "Trying to download again..."
                $downloadstatus = download_file -url $DOWNLOAD_URL_VIRTIO_DRIVERS -targetFile $strVirtIoIsoPath;
                $trycount =    $trycount + 1
                Start-Sleep -s 10
            }
            if ($downloadstatus -eq $False) {
                    Write-Host "`nDownload failed, Please download virtio driver manually from $DOWNLOAD_URL_VIRTIO_DRIVERS or try running scirpt after sometime later" -ForegroundColor Red;
                    $queueTable.Rows.Add("Virtio Driver Download","Failed") | Out-Null                    
            }
        }        
		if( Test-Path $strVirtIoIsoPath ) {
            $strDriveLetter = (Get-DiskImage $strVirtIoIsoPath | Get-Volume).DriveLetter
            if ( -not ($null -eq $strDriveLetter)){                               
                $strVirtIoPath = "{0}:\virtio-win-gt-x64.msi" -f $strDriveLetter;                
            }else{
				$mountResult = Mount-DiskImage -ImagePath $strVirtIoIsoPath -PassThru | Get-DiskImage | Get-Volume;
                $strDriveLetter = $mountResult.DriveLetter
                $strVirtIoPath = "{0}:\virtio-win-gt-x64.msi" -f $strDriveLetter; 
			} 
            if (Test-Path $strVirtIoPath ){
			$strDriveLetter = "{0}:" -f $strDriveLetter; 
			$strCertificatePath = getCertificatePath -strDriveLetter $strDriveLetter;
			installCertificate -strCertifiateDir $strCertificatePath;
			$virtioInstallStatus = installSoftware -strSourcePath $strVirtIoPath -strInstalledPath $strVirtIoInstalledPath;
            }
            else{$virtioInstallStatus = "Failed"}
            if ($virtioInstallStatus -eq "Passed"){
                $queueTable.Rows.Add("Virtio Driver","Passed") | Out-Null                
            }else{
                $queueTable.Rows.Add("Virtio Driver","Failed") | Out-Null
            }
            Dismount-DiskImage -ImagePath $strVirtIoIsoPath;
            Start-Sleep -s 2
		}
	}
    ##############################################
    ####### CloudBase-Init Installation ##########
    ##############################################
	$boolIsCouldInitPresent = isApplicationPresent -strApplicationName "Cloudbase-Init*";
	if( $True -eq $boolIsCouldInitPresent ) {
		$strCurrentVersion = getVersion -strApplicationName "Cloudbase-Init*";
		Write-Host "`nFound Cloudbase-Init $strCurrentVersion in system." -ForegroundColor Yellow;
		$boolIsAllowedVersion = isValidVersion -strMinimumVersion $MINIMUM_VERSION_CLOUDBASE_INIT -strCurrentVersion $strCurrentVersion;
		if ( $False -eq $boolIsAllowedVersion ) {
			$cloudInitVersionCompatible = $False
            Write-Host "`nError : Version $strCurrentVersion of Cloudbase-Init is incompatible with migration process. Script will Uninstall Cloudbase-Init and Re-install compatible version." -ForegroundColor Red;
		    $removeCloudbase = Get-WmiObject -Class Win32_Product | Where-Object{$_.Name -Like "Cloudbase-Init*"}
            Write-Host "`nUnistallation of cloudbase init in progress..." -ForegroundColor Yellow;
            $removeCloudbase.Uninstall() 
            $boolIsCouldInitPresent = isApplicationPresent -strApplicationName "Cloudbase-Init*";  
			if( $boolIsCouldInitPresent -eq $True ) {
				Write-Host "`nError : Uninstall Cloudbase-Init failed, Please re-run the script after manual un-installation of cloudbase-init." -ForegroundColor Red;
				$queueTable.Rows.Add("CloudBase-Init Uninstallation","Failed") | Out-Null
			}
			else{
				Write-Host "`n Uninstall Cloudbase-Init Successful." -ForegroundColor Yellow;
				$queueTable.Rows.Add("CloudBase-Init Uninstallation","Passed") | Out-Null
			}
        } else {
			Write-Host "`nVersion $strCurrentVersion of Cloudbase-Init is compatible with migration process." -ForegroundColor Yellow;
			$queueTable.Rows.Add("CloudBase-Init compatibility","Passed") | Out-Null
			$cloudInitVersionCompatible = $True 
        }
	} else {
		Write-Host "`nCloudbase-Init application is not installed. Need to download and install recent version of Cloudbase-Init application." -ForegroundColor Yellow;
	}
    if( $boolIsCouldInitPresent -eq $False ) {
		if( -not ( Test-Path -Path $strCloudbaseInitPath ) ) {
            Write-Output "Downloading CloudBase-Init"
            $downloadstatus = download_file -url $DOWNLOAD_URL_CLOUDBASE_INIT -targetFile $strCloudbaseInitPath;
		    
            $trycount = 0
            while (($downloadstatus -eq $False) -and ($trycount -ne 5 )) {
                Write-Output "Trying to download again..."
                $downloadstatus = download_file -url $DOWNLOAD_URL_CLOUDBASE_INIT -targetFile $strCloudbaseInitPath;
                $trycount =    $trycount + 1
                Start-Sleep -s 10
            }
            if ($downloadstatus -eq $False) {
                    Write-Host "`nDownload failed, Please download cloudbase-init manually from $DOWNLOAD_URL_CLOUDBASE_INIT or try running scirpt after sometime later" -ForegroundColor Red;
                    $queueTable.Rows.Add("CloudBase-Init Download","Failed") | Out-Null
            }
        }
		if( Test-Path -Path $strCloudbaseInitPath ) {
			$CloudInitInstallStatus = installSoftware -strSourcePath $strCloudbaseInitPath -strInstalledPath $strCloudbaseInitInstalledPath;
            if ($CloudInitInstallStatus -eq "Passed"){
                $queueTable.Rows.Add("CloudBase-Init Install","Passed") | Out-Null
				$cloudInitVersionCompatible = $True 
            }else{
                $queueTable.Rows.Add("CloudBase-Init Install","Failed") | Out-Null
				$cloudInitVersionCompatible = $False
            }	
    }		
	}
    #MODIFY/CREATE CONFIGS
	$strConfigPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf";
	$strConfigUnattendPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf";
	$strUnattendConfigXml = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml";
	$strRenamedConfigFile = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-backup.conf";
	$strRenamedConfigUnattendFile = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend-backup.conf";
	$strRenamedConfigUnattendXmlFile = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend-backup.xml";
    
    $strOriginalConfigContent = '[DEFAULT]
#  "cloudbase-init.conf" is used for every boot
config_drive_types=vfat
config_drive_locations=hdd
activate_windows=true
kms_host=kms.adn.networklayer.com:1688
mtu_use_dhcp_config=false
real_time_clock_utc=false
bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\
debug=true
log_dir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
log_file=cloudbase-init.log
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService,
# enabled plugins - executed in order
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,
        cloudbaseinit.plugins.windows.ntpclient.NTPClientPlugin,
        cloudbaseinit.plugins.windows.licensing.WindowsLicensingPlugin,
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,
        cloudbaseinit.plugins.common.userdata.UserDataPlugin,
        cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin';
	$strOriginalConfigUnattendContent = '[DEFAULT]
#  "cloudbase-init-unattend.conf" is used during the Sysprep phase
username=Administrator
inject_user_password=true
first_logon_behaviour=no
config_drive_types=vfat
config_drive_locations=hdd
allow_reboot=false
stop_service_on_exit=false
mtu_use_dhcp_config=false
bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe
mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\
debug=true
log_dir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
log_file=cloudbase-init-unattend.log
default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
metadata_services=cloudbaseinit.metadata.services.configdrive.ConfigDriveService,
# enabled plugins - executed in order
plugins=cloudbaseinit.plugins.common.mtu.MTUPlugin,
        cloudbaseinit.plugins.common.sethostname.SetHostNamePlugin,
        cloudbaseinit.plugins.windows.createuser.CreateUserPlugin,
        cloudbaseinit.plugins.windows.extendvolumes.ExtendVolumesPlugin,
        cloudbaseinit.plugins.common.setuserpassword.SetUserPasswordPlugin,
        cloudbaseinit.plugins.common.localscripts.LocalScriptsPlugin';
		
	$strOriginalConfigUnattendXmlContent =	'<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
  <settings pass="generalize">
    <component name="Microsoft-Windows-PnpSysprep" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <PersistAllDeviceInstalls>false</PersistAllDeviceInstalls>
    </component>
  </settings>
  <settings pass="oobeSystem">
    <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
      <OOBE>
        <HideEULAPage>true</HideEULAPage>
        <NetworkLocation>Work</NetworkLocation>
        <ProtectYourPC>1</ProtectYourPC>
        <SkipMachineOOBE>true</SkipMachineOOBE>
        <SkipUserOOBE>true</SkipUserOOBE>
      </OOBE>
    </component>
  </settings>
  <settings pass="specialize">
    <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
      <RunSynchronous>
        <RunSynchronousCommand wcm:action="add">
          <Order>1</Order>
          <Path>cmd.exe /c ""C:\Program Files\Cloudbase Solutions\Cloudbase-Init\Python\Scripts\cloudbase-init.exe" --config-file "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf" &amp;&amp; exit 1 || exit 2"</Path>
          <Description>Run Cloudbase-Init to set the hostname</Description>
          <WillReboot>OnRequest</WillReboot>
        </RunSynchronousCommand>
      </RunSynchronous>
    </component>
  </settings>
</unattend>';
	if ( $True -eq $cloudInitVersionCompatible ) { 
    	if (Test-Path -Path $strCloudbaseInitInstalledPath){
        	try {
            	if( Test-Path -Path $strConfigPath ) {
		        	backupFile -strPath $strConfigPath -strRenamedConfigFile $strRenamedConfigFile;
		        	removeConfig -strPath $strConfigPath;
                	createConfig -strPath $strConfigPath -strFileContent $strOriginalConfigContent;
	        	} else {
		        	createConfig -strPath $strConfigPath -strFileContent $strOriginalConfigContent;
	        	}
	        	if( Test-Path -Path $strConfigUnattendPath ) {
		        	backupFile -strPath $strConfigUnattendPath -strRenamedConfigFile $strRenamedConfigUnattendFile;
		        	removeConfig -strPath $strConfigUnattendPath;
                	createConfig -strPath $strConfigUnattendPath -strFileContent $strOriginalConfigUnattendContent;
	        	} else {
		        	createConfig -strPath $strConfigUnattendPath -strFileContent $strOriginalConfigUnattendContent;
	        	}
	        	if( Test-Path -Path $strUnattendConfigXml ) {
		        	backupFile -strPath $strUnattendConfigXml -strRenamedConfigFile $strRenamedConfigUnattendXmlFile;
		        	removeConfig -strPath $strUnattendConfigXml;
                	createConfig -strPath $strUnattendConfigXml -strFileContent $strOriginalConfigUnattendXmlContent;
	        	} else {
		        	createConfig -strPath $strUnattendConfigXml -strFileContent $strOriginalConfigUnattendXmlContent;
	        	}
            	$queueTable.Rows.Add("CloudBase-Init Config","Passed") | Out-Null
         	}catch{
            	$queueTable.Rows.Add("CloudBase-Init Config","Failed") | Out-Null 
         	}
    	}
	}
 summary      
}
# Script execution will start from here.
# Clear-host;
$ErrorActionPreference = 'Stop'; 
main;     