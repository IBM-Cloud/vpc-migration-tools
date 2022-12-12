#----------------------------------------------------------------------------------------------------------------------
# Description : This an automation script to unjoin and rejoin domain.
# Location for file on RMM server : /opt/rackware/utils/pre-post-scripts/ OR any directory on target node machine.
#----------------------------------------------------------------------------------------------------------------------

param($domainName, $userAccount, $password);

#Import-Module ActiveDirectory

function unjoinDomain( $credentials ) {
    Write-host "Unjoin domain.";
    Remove-Computer -UnjoinDomaincredential $credentials -PassThru -Verbose -Force;
}

function joinDomain( $domainName, $credentials ) {
    Write-host "Join domain.";
    Add-Computer -DomainName $domainName -Credential $credentials -Restart -Verbose -Force;
}

function main( $domainName, $userAccount, $password ) {

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

    unjoinDomain -credentials $credentials;
    joinDomain -domainName $domainName -credentials $credentials;
}

Start-Transcript -Path "C:\rejoin_domain.log";
main -domainName $domainName -userAccount $userAccount -password $password;
Stop-Transcript;