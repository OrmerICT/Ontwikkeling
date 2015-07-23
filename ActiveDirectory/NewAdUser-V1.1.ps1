###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     NewAdUser-v1.1.ps1
# Date:     07/20/2015
# Version:  1.1
#
# Purpose:  PowerShell script to add a new user.
#
# Usage:    NewAdUser-v1.1.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
# 
# 
#
# Revisions:
# ----------
# 1.0.0   07/16/2015   Created script.
# 1.1.0   07/20/2015   Error logging aangepast By PvdW
# 1.2.0   
#>#******************************************************************************


#EndRegion Comments
#
[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [string]$KworkingDir,

#Procedure Vars
    [parameter(mandatory=$true)]
    [string]$UserName,

    [parameter(mandatory=$true)]
    [string]$Givenname,

    [parameter(mandatory=$true)]
    [string]$Surname,

    [parameter(mandatory=$true)]
    [string]$Initials,

    [parameter(mandatory=$true)]
    [string]$Mail,

    [parameter(mandatory=$true)]
    [string]$password,

    [parameter(mandatory=$true)]
    [string]$Copyuser

)

#region start StandardFramework
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$GetProcName = Get-PSCallStack
$procname = $GetProcname.Command
$Customer = $MachineGroep.Split(“.”)[2]

$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

remove-item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
#endregion StandardFramework
    
#region Start log
    f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title:`'$($Procname)`'Script"
#endregion Start log

#region Load module Server manager
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Checking to see if the servermanager PowerShell module is installed"
    if ((get-module -name servermanager -ErrorAction SilentlyContinue | foreach { $_.Name }) -ne "servermanager")
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Adding servermanager PowerShell module" 
        import-module servermanager
        }
    else
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "servermanager PowerShell module is Already loaded" 
        }
#endregion Load module Server manager


#region Install RSAT-AD-PowerShell
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Check if RSAT-AD-PowerShell is installed"
         $RSAT = (Get-WindowsFeature -name RSAT-AD-PowerShell).Installed 

    If ($RSAT -eq $false) 
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "RSAT-AD-PowerShell not found: `'$($RSAT)`'"

        Add-WindowsFeature RSAT-AD-PowerShell
        f_New-Log -logvar $logvar -status 'start' -LogDir $KworkingDir -Message "Add Windows Feature RSAT-AD-PowerShell"
        }
        
#endregion Install RSAT-AD-PowerShell

#region start Import Module Active Directory
    if ((get-module -name ActiveDirectory -ErrorAction SilentlyContinue | foreach { $_.Name }) -ne "ActiveDirectory")
         {
         f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Adding ActiveDirectory PowerShell module" 
         import-module ActiveDirectory
         }
    else
         {
         f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "ActiveDirectory PowerShell module is Already loaded" 
         }
#endregion start Import Module Active Directory

#region start Check if user is disabled
    $UserEnabled = (Get-ADUser -Identity $UserName).Enabled
    If ($UserEnabled -eq $false)
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "User is disabled. Please contact the manager: `'$($UserEnabled)`'"
    exit
        }
    else
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "User is enabled: `'$($UserName)`'"
        }
#endregion Check if user is disabled


#region Create user account
     f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Create New ActiveDirectory User account"
         $User = Get-AdUser -Identity $CopyUser
         $DN = $User.distinguishedName
         $OldUser = [ADSI]"LDAP://$DN"
         $Parent = $OldUser.Parent
         $OU = [ADSI]$Parent
         $OUDN = $OU.distinguishedName
         $NewName = "$SurName, $Initials"
        New-ADUser -SamAccountName $UserName -UserPrincipalName $UserName -Name "$NewName" -GivenName "$GivenName" -Initials "$Initials" -Surname "$SurName" -DisplayName "$NewName" -EmailAddress "$Mail" -Instance $DN -Path "$OUDN" -AccountPassword (ConvertTo-SecureString -AsPlainText "$PassWord" -Force) -enabled $true -ErrorAction SilentlyContinue

        Start-Sleep -s 20
#endregion Create user account

#region start Determine If Users Is In Active Directory 
        $TestUser = Get-ADUser -LDAPFilter "(sAMAccountName=$UserName)"
    If ($TestUser  -eq $Null) 
        {

        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Create New ActiveDirectory User account `'$($UserName)`'Failed"
    exit
        }
    Else 
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Create New ActiveDirectory User account `'$($UserName)`'done"
        }
#endregion start Determine If Users Is In Active Directory


#region start Test user login
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Test account authentication:`'$($UserName)`'done"

        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
        $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct,$Domain
    If ($pc.ValidateCredentials($UserName,$Password) -eq $true)
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Authentication successfully:`'$($UserName)`'"
        }
    else
        {
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Authentication not successful:`'$($UserName)`'"
        }
#endregion start Test user login

#region start Add the new User to the Same Groups as the old user
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Add the new User to the Same Groups as the old user"
        Get-ADUser -Identity $CopyUser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $UserName
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "User added to Group"
#endregion start Add the new User to the Same Groups as the old user

#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log
