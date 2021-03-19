function isValidOs() {
	try {
		$boolIsValid = $False;
		$arrstrAllowedOSes = @( 'Microsoft Windows Server 2016 Standard','Microsoft Windows Server 2012 R2 Standard','Microsoft Windows Server 2012 Standard');
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

		if( $null -ne $strApplicationName ) {
			$boolIsPresent = $True;
		}
	} catch {
		Write-Host "`nError occurred while checking application : $strApplicationName. $_" -ForegroundColor Red;
	}

	return $boolIsPresent;
}

function installSoftware( $strSourcePath ) {
	try {
		Write-Host "`nInstalling application : $strSourcePath" -ForegroundColor Yellow;
		Write-Host "`nPlease wait for few moments..." -ForegroundColor Yellow;
		Start-Process -Wait -FilePath $strSourcePath -ArgumentList "/qn";
		Write-Host "`nApplication $strSourcePath is installed!" -ForegroundColor Green;
	} catch {
		Write-Host "`nError occurred while installing application : $strSourcePath $_" -ForegroundColor Red;
	}
}

function copyFile( $strOldFileName, $strNewFileName ) {
	try {
		Copy-Item -Path $strOldFileName -Destination $strNewFileName;
	} catch {
		Write-Host "`nError occurred while copying file : $strSourcePath $_" -ForegroundColor Red;
	}
}

function modifyConfig( $strPath, $strFileContent ) {
	try {
		Add-Content -Path $strPath -Value $strFileContent;
		Write-Host "`nModified config file : $strPath" -ForegroundColor Yellow;
	} catch {
		Write-Host "`nError occurred while modifying configuration file : $strPath. $_" -ForegroundColor Red;
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

function modfiyConfigXml( $strPath, $strRenamedConfigFile ) {
	try {
		if( -Not ( Test-Path -Path $strRenamedConfigFile ) ) {
			Write-Host "`nCreating backup of config file : $strPath" -ForegroundColor Yellow;
			copyFile -strOldFileName $strPath -strNewFileName $strRenamedConfigFile;
		}
		[ xml ] $fileContents = Get-Content -Path $strUnattendConfigXml;
		$component = $fileContents.unattend.settings.component | Where-Object { $null -ne $_.PersistAllDeviceInstalls };
		$component.PersistAllDeviceInstalls = 'false';
		$fileContents.Save( $strUnattendConfigXml );
		Write-Host "`nModified config file : $strPath" -ForegroundColor Yellow;
	} catch {
		Write-Host "`nError occurred while configuring : $strPath. $_" -ForegroundColor Red;
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

function download( $strDownloadUrl, $strDownloadFilePath ) {
 	try	{
		Write-Host "`nDownloading from $strDownloadUrl" -ForegroundColor Yellow;
		Write-Host "`nPlease wait few moments..." -ForegroundColor Yellow;
		Invoke-WebRequest $strDownloadUrl -OutFile $strDownloadFilePath -ErrorAction Stop;
	} catch {
		Write-Host "`nError occurred during download. $_" -ForegroundColor Red;
	} 
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
		"Microsoft Windows Server 2016 Standard" { $strPath = "$strDriveLetter\amd64\2k16"; Break; }
		"Microsoft Windows Server 2012 R2 Standard" { $strPath = "$strDriveLetter\amd64\2k12R2"; Break; }
		"Microsoft Windows Server 2012 Standard" { $strPath = "$strDriveLetter\amd64\2k12"; Break; }
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

function setDriveLetter( $strDriveLetter ) {
	try {
		Get-WmiObject -Class Win32_volume -Filter 'DriveType=5' | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter=$strDriveLetter} | Out-Null;
	} catch {
		Write-Host "`nFailed to set drive letter. $_" -ForegroundColor Red;
	}
}

 function removeLinesFromFile ( $strPath, $arrstrLines ) {
    $objContents = Get-Content $strPath;

    foreach ( $strLine in $arrstrLines ) {
        $objContents = $objContents | Where-Object { $_ -inotlike $strLine }
    }

    Set-Content -path $strPath -value $objContents -Force;
}

function backupFile( $strPath, $strRenamedConfigFile ) {
	try {
		if( -Not ( Test-Path -Path $strRenamedConfigFile ) ) {
			Write-Host "`nCreating backup of config file : $strPath" -ForegroundColor Yellow;
			copyFile -strOldFileName $strPath -strNewFileName $strRenamedConfigFile;
		}		
	} catch {
		Write-Host "`nError occurred while creating backup copy : $strPath. $_" -ForegroundColor Red;
	}
}

function isConfigurationPresent( $strPath, $strConfigContent ) {

	$boolIsValid = $False;
	try {
		if( -Not ( Test-Path $strPath ) -or $null -eq $strConfigContent ) {
			return boolIsValid;
		}

		$strFileContent = Get-Content $strPath ;
		$strFileContent = [string] $strFileContent;
		$strFileContent = $strFileContent -replace "\s+|`t|`n|`r","";
		$strConfigContent = $strConfigContent -replace "\s+|`t|`n|`r","";

		if ( $strFileContent.Contains( $strConfigContent ) ) {
			$boolIsValid = $True;
		}
	} catch {
		$boolIsValid = $False;
 		write-host 'Error occurred while checking configuration. $_ ' -ForegroundColor red;
	}

	return $boolIsValid;
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
	
	$strCloudbaseInitMsiFileName = 'CloudbaseInitSetup_Stable_x64.msi';
	$strVirtIoIsoFileName = 'virtio-win.iso';

	$strCloudbaseInitPath = "$DIR_TEMP\$strCloudbaseInitMsiFileName";
	$strVirtIoIsoPath = "$DIR_TEMP\$strVirtIoIsoFileName";

	$boolIsAllowedVersion = $False;

	$boolIsAllowedOs = isValidOs;

	$strOsName = ( Get-WmiObject -Class win32_operatingsystem ).caption;

	if ( $False -eq $boolIsAllowedOs ) {
		Write-Host "`n'$strOsName' operating system is not compatible with migration process. Exiting script..." -ForegroundColor Red;
		Exit;
	} else {
		Write-Host "`n'$strOsName' operating system is compatible with migration process." -ForegroundColor Yellow;
	}

	$boolIsCouldInitPresent = isApplicationPresent -strApplicationName "Cloudbase-Init*";

	if( $True -eq $boolIsCouldInitPresent ) {
		$strCurrentVersion = getVersion -strApplicationName "Cloudbase-Init*";
		Write-Host "`nFound Cloudbase-Init $strCurrentVersion in system." -ForegroundColor Yellow;
		$boolIsAllowedVersion = isValidVersion -strMinimumVersion $CLOUDBASE_INIT_MINIMUM_VERSION -strCurrentVersion $strCurrentVersion;

		if ( $False -eq $boolIsAllowedVersion ) {
			Write-Host "`nVersion $strCurrentVersion of Cloudbase-Init is incompatible with migration process. Need to install recent version of Cloudbase-Init." -ForegroundColor Yellow;
		} else {
			Write-Host "`nVersion $strCurrentVersion of Cloudbase-Init is compatible with migration process." -ForegroundColor Yellow;
		}
	} else {
		Write-Host "`nCloudbase-Init application is not installed. Need to download and install recent version of Cloudbase-Init application." -ForegroundColor Yellow;
	}

	checkAndCreateDir -strPath $DIR_TEMP;

	# Download Cloutbase init
	if( $boolIsAllowedVersion -eq $False -or $boolIsCouldInitPresent -eq $False ) {

		if( -not ( Test-Path -Path $strCloudbaseInitPath ) ) {
			download -strDownloadUrl $DOWNLOAD_URL_CLOUDBASE_INIT -strDownloadFilePath $strCloudbaseInitPath;
		}

		if( Test-Path -Path $strCloudbaseInitPath ) {
			installSoftware -strSourcePath $strCloudbaseInitPath;
		}		
	}

	#MODIFY/CREATE CONFIGS
	$strConfigPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init.conf";
	$strConfigUnattendPath = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend.conf";
	$strUnattendConfigXml = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend.xml";

	$strRenamedConfigFile = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-backup.conf";
	$strRenamedConfigUnattendFile = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\cloudbase-init-unattend-backup.conf";
	$strRenamedConfigUnattendXmlFile = "C:\Program Files\Cloudbase Solutions\Cloudbase-Init\conf\Unattend-backup.xml";

	$strConfigContent = '#  "cloudbase-init.conf" is used for every boot
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

	$strConfigUnattendContent = '#  "cloudbase-init-unattend.conf" is used during the Sysprep phase
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

	$strOriginalConfigContent = '[DEFAULT]
username=Admin
groups=Administrators
inject_user_password=true
config_drive_raw_hhd=true
config_drive_cdrom=true
config_drive_vfat=true
verbose=true
logdir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
logfile=cloudbase-init.log
logging_serial_port_settings=
mtu_use_dhcp_config=true
ntp_use_dhcp_config=true
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
check_latest_version=true
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
groups=Administrators
config_drive_raw_hhd=true
config_drive_cdrom=true
config_drive_vfat=true
verbose=true
debug=true
logdir=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\log\
logfile=cloudbase-init-unattend.log
logging_serial_port_settings=
mtu_use_dhcp_config=true
ntp_use_dhcp_config=true
local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\
check_latest_version=false
allow_reboot=false
stop_service_on_exit=false
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
	
	$arrstrCloudbaseInitConfigDupLines = @( 
		'bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe', 
		'mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\', 
		'debug=true',
		'default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN',
		'local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\'
	);

	$arrstrUnattendDupLines =@(
		'username=Admin',
		'inject_user_password=true',
		'bsdtar_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\bsdtar.exe',
		'mtools_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\bin\',
		'debug=true',
		'default_log_levels=comtypes=INFO,suds=INFO,iso8601=WARN,requests=WARN',
		'local_scripts_path=C:\Program Files\Cloudbase Solutions\Cloudbase-Init\LocalScripts\'
	);

	if( Test-Path -Path $strConfigPath ) {
		if( -Not ( isConfigurationPresent -strPath $strConfigPath -strConfigContent $strConfigContent ) ) {
			backupFile -strPath $strConfigPath -strRenamedConfigFile $strRenamedConfigFile;
			removeLinesFromFile -strPath $strConfigPath -arrstrLines $arrstrCloudbaseInitConfigDupLines;
			modifyConfig -strPath $strConfigPath -strFileContent $strConfigContent;
		}
	} else {
		createConfig -strPath $strConfigPath -strFileContent $strOriginalConfigContent;
	}
	
	if( Test-Path -Path $strConfigUnattendPath ) {
		if( -Not ( isConfigurationPresent -strPath $strConfigUnattendPath -strConfigContent $strConfigUnattendContent ) ) {
			backupFile -strPath $strConfigUnattendPath -strRenamedConfigFile $strRenamedConfigUnattendFile;
			removeLinesFromFile -strPath $strConfigUnattendPath -arrstrLines $arrstrUnattendDupLines;
			modifyConfig -strPath $strConfigUnattendPath -strFileContent $strConfigUnattendContent;
		}
	} else {
		createConfig -strPath $strConfigUnattendPath -strFileContent $strOriginalConfigUnattendContent;
	}

	if( Test-Path -Path $strUnattendConfigXml ) {
		backupFile -strPath $strUnattendConfigXml -strRenamedConfigFile $strRenamedConfigUnattendXmlFile;
		modfiyConfigXml -strPath $strUnattendConfigXml -strRenamedConfigFile $strRenamedConfigUnattendXmlFile;
	} else {
		createConfig -strPath $strUnattendConfigXml -strFileContent $strOriginalConfigUnattendXmlContent;
	}

	$boolIsVirtIoPresent = isApplicationPresent -strApplicationName "Virtio-win*";
	$boolIsAllowedVersionForVirtIo = $False;

	if( $boolIsVirtIoPresent -eq $True ) {
		$strCurrentVersionVirtIo = getVersion -strApplicationName "Virtio-win*";
		Write-Host "`nFound VirtIO driver $strCurrentVersionVirtIo in system." -ForegroundColor Yellow;
		$boolIsAllowedVersionForVirtIo = isValidVersion -strMinimumVersion $MINIMUM_VERSION_VIRTIO_DRIVERS -strCurrentVersion $strCurrentVersionVirtIo;

		if ( $False -eq $boolIsAllowedVersionForVirtIo ) {
			Write-Host "`nVersion $strCurrentVersionVirtIo of VirtIO driver is incompatible with migration process. Need to install recent version of VirtIO driver." -ForegroundColor Yellow;
		} else {
			Write-Host "`nVersion $strCurrentVersionVirtIo of VirtIO driver is compatible with migration process." -ForegroundColor Yellow;
		}
	}

	if( $boolIsAllowedVersionForVirtIo -eq $False -or $boolIsVirtIoPresent -eq $False ) {
		setSecurityProtocol;
		$strDriveLetter = 'Z:';
		$strVirtIoPath = "$strDriveLetter\virtio-win-gt-x64.msi"; 

		if( -not ( Test-Path $strVirtIoIsoPath ) ) {
			download -strDownloadUrl $DOWNLOAD_URL_VIRTIO_DRIVERS -strDownloadFilePath $strVirtIoIsoPath;
		}

		if( Test-Path $strVirtIoIsoPath ) {
			$strVolume = Get-WmiObject -Class Win32_Volume -Filter "DriveLetter = '$strDriveLetter'";

			if ( $null -eq $strVolume ) {
				Mount-DiskImage -ImagePath $strVirtIoIsoPath -NoDriveLetter;
			} 
		
			setDriveLetter -strDriveLetter $strDriveLetter;
			$strCertificatePath = getCertificatePath -strDriveLetter $strDriveLetter;
			installCertificate -strCertifiateDir $strCertificatePath;
			installSoftware -strSourcePath $strVirtIoPath;
		}
	}

	#Systprep- hold on to this
}

# Script execution will start from here.
# Clear-host;
$ErrorActionPreference = 'Stop'; 
main;
