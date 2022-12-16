#----------------------------------------------------------------------------------------------------------------------
# Description : This an automation script to unjoin and rejoin domain.
# Location for file on RMM server : /opt/rackware/utils/pre-post-scripts/ OR any directory on target node machine.
#----------------------------------------------------------------------------------------------------------------------

param($domainName, $userAccount, $password);

#Import-Module ActiveDirectory

function unjoinDomain( $credentials ) {
    try {
        Write-host "Unjoining domain.";
        Remove-Computer -UnjoinDomaincredential $credentials -PassThru -Verbose -Force;
    } catch {
        Write-Host "Failed to unjoin domain:";
        Write-Host $_;
	}
}

function joinDomain( $domainName, $credentials ) {
    try {
        Write-host "Joining domain.";
        Add-Computer -DomainName $domainName -Credential $credentials -Restart -Verbose -Force;    
    } catch {
		Write-Host "Failed to join domain:";
        Write-Host $_;
    }
}

function main( $domainName, $userAccount, $password ) {

    try {
        Write-host "Parameters : -domainName $domainName -userAccount $userAccount -password *******";

        $localComputerName = ( Get-WmiObject -Class Win32_ComputerSystem ).Name;
    
        $password = ConvertTo-SecureString $password -AsPlainText -Force;
        $fullUserAccount = $domainName + '\' + $userAccount;
        $credentials = New-Object System.Management.Automation.PSCredential( $fullUserAccount, $password );
    
        if( $False -eq ( Get-WmiObject -Class Win32_ComputerSystem ).PartOfDomain ) {
            Write-host "Node computer '$localComputerName' is not part of '$domainName'.";
            Exit;
        }
    
        if( $True -eq ( Test-ComputerSecureChannel -Credential $credentials ) ) {
            Write-host "Secure channel between primary domain '$domainName' and node computer '$localComputerName' is not broken.";
            Exit;
        }
    } catch {
        Write-Host "Rejoin domain script failed:";
        Write-Host $_;
    }

    unjoinDomain -credentials $credentials;
    joinDomain -domainName $domainName -credentials $credentials;
}

Start-Transcript -Append -Path "C:\rejoin_domain.log";
main -domainName $domainName -userAccount $userAccount -password $password;
Stop-Transcript;