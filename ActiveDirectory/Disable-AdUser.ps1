#region Comments
<###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################

#******************************************************************************
# File:     Disable-AdUser-v1.1.ps1
# Date:     07/17/2015
# Version:  1.1
#
# Purpose:  PowerShell script to clean Temp folders.
#
# Usage:    Disable-AdUser-v1.1.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
#
# Revisions:
# ----------
# 1.0.0   07/16/2015   Created script.
# 1.1.0   07/17/2015   Error logging aangepast By PvdW
# 1.2.0   
#>#******************************************************************************
#endregion Comments

[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$false)]
    [string]$KworkingDir,
	
	# Procedure vars
    [Parameter(Mandatory=$false)]
    [String] $UserName,

    [Parameter(Mandatory=$false)]
    [String] $Domain = $env:USERDOMAIN
)

#region StandardFramework
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
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title: `'$Kworking`' Script"
#endregion StandardFramework
    
#region Load module Server manager
    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Checking to see if the servermanager PowerShell module is installed"
    if ((get-module -name servermanager -ErrorAction SilentlyContinue | foreach { $_.Name }) -ne "servermanager") {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Adding servermanager PowerShell module" 
        import-module servermanager
        }
    else {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "servermanager PowerShell module is Already loaded" 
        }
#endregion Load module Server manager

#region Install RSAT-AD-PowerShell
    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Check if RSAT-AD-PowerShell is installed"
    $RSAT = (Get-WindowsFeature -name RSAT-AD-PowerShell).Installed 

    If ($RSAT -eq $false) {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "RSAT-AD-PowerShell not found: `'$($RSAT)`'"

        Add-WindowsFeature RSAT-AD-PowerShell
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Add Windows Feature RSAT-AD-PowerShell"

        Import-module ActiveDirectory
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Import module ActiveDirectory"
        }
    Else {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Windows Feature RSAT-AD-PowerShell installed"
        }
#endregion Install RSAT-AD-PowerShell

#region Import Module Active Directory
    if ((get-module -name ActiveDirectory -ErrorAction SilentlyContinue | foreach { $_.Name }) -ne "ActiveDirectory") {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Adding ActiveDirectory PowerShell module" 
        import-module ActiveDirectory
        }
    else {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "ActiveDirectory PowerShell module is Already loaded"
        }
#endregion Import Module Active Directory


#region Disable Account
    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Disable user account: `'$($UserName)`'"
    Disable-ADAccount -Identity $UserName
#endregion Disable Account

f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Title: END `'$Kworking`' Script"
