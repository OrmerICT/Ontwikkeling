<#

.SYNOPSIS
Modifies the password of an Active Directory account.

.DESCRIPTION
The Set-ADAccountPassword cmdlet sets the password for a user, computer or service account.

The Identity parameter specifies the Active Directory account to modify.
You can identify an account by its distinguished name (DN), GUID, security identifier (SID) or security accounts manager (SAM) account name.
You can also set the Identity parameter to an object variable such as $<localADAccountObject>, or you can pass an object through the pipeline to the Identity parameter.
For example, you can use the Search-ADAccount cmdlet to retrieve an account object and then pass the object through the pipeline to the Set-ADAccountPassword cmdlet.
Similarly, you can use Get-ADUser, Get-ADComputer or Get-ADServiceAccount cmdlets to retrieve account objects that you can pass through the pipeline to this cmdlet.

You must set the OldPassword and the NewPassword parameters to set the password unless you specify the Reset parameter.
When you specify the Reset parameter, the password is set to the NewPassword value that you provide and the OldPassword parameter is not required.

For AD LDS environments, the Partition parameter must be specified except in the following two conditions:
-The cmdlet is run from an Active Directory provider drive.
-A default naming context or partition is defined for the AD LDS environment.
 To specify a default naming context for an AD LDS environment, set the msDS-defaultNamingContext property of the Active Directory directory service agent (DSA) object (nTDSDSA) for the AD LDS instance.

.EXAMPLE
AD-Generic-UsrResetPassword.ps1

.NOTES
Copyright (C) 2015 Ormer ICT

Date (DD/MM/YYYY)   Name             Description
21/08/2015          Jeff Wouters     Made authentication work by moving 'Change pwd at logon' after authentication

.LINK
https://technet.microsoft.com/en-us/library/ee617261.aspx

#>

[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroup,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [string]$KworkingDir
)

#region StandardFramework
Import-Module -Name OrmLogging -Prefix 'Orm' -ErrorAction SilentlyContinue -ErrorVariable ImportModuleOrmLoggingError
if($ImportModuleOrmLoggingError)
{
    Write-Error "Unable to import the Ormer Logging Powershell Module"
    Write-Error "$($ImportModuleOrmLoggingError.Exception.Message)"
    Break
}
Import-Module -Name OrmToolkit -Prefix 'Orm' -ErrorAction SilentlyContinue -ErrorVariable ImportModuleOrmToolkitError
if($ImportModuleOrmToolkitError)
{
    Write-Error "Unable to import the Ormer Toolkit Powershell Module"
    Write-Error "$($ImportModuleOrmToolkitError.Exception.Message)"
    Break
}

Set-Location $KworkingDir -ErrorAction SilentlyContinue -ErrorVariable SetLocationError
if($SetLocationError)
{
    Write-Error "Unable to set the working directory of the script"
    Write-Error "$($SetLocationError.Exception.Message)"
    Break
}
    
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
$Customer = $MachineGroup.Split('.')[2]


$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

Remove-Item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Starting procedure: $($procname)"
#endregion StandardFramework
    
#region Execution

New-OrmLog -logvar $logvar -Status 'Success' -LogDir $KworkingDir -ErrorAction Stop -Message "END title: $procname Script"

exit 1

#endregion Execution