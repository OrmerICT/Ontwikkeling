###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     Remove_Sharp_Keys.ps1
# Date:     07/21/2015
# Version:  0.1
#
# Purpose:  PowerShell script remove Specific Reg Key's.
#
# Usage:    Remove_Sharp_Keys.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
# 
# Revisions:
# ----------
# 0.1.0   07/21/2015  Created script.
#    
#>#*****************************************************************************

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

    [parameter(mandatory=$False)]
    [string]$KworkingDir

#Procedure Vars
#    [parameter(mandatory=$true)]
#    [string]$UserName
)

#region start StandardFramework
$KworkingDir = "c:\kworking"
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
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

#region Delete HKLM Sharp Registry path
    $RegistryPath1 = "hklm:\Software\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\RefHive\Sharp"
   
    f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Delete:`'$($RegistryPath1)`'Key"
       
    $RegTest = Test-Path $RegistryPath1
    # (Get-item -Path $RegistryPath1).Enabled 
    if ($RegTest -eq $False)
        {
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Key:`'$($RegistryPath1)`'Not Exist"
        }
    else
        {
        remove-item -Path $RegistryPath1 -Force -ErrorAction SilentlyContinue
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Key:`'$($RegistryPath1)`'Deleted"
        }
     
#endregion Delete HKLM Sharp Registry path

#region Delete HKU Sharp Registry path
     New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
        $users = Get-ChildItem "HKU:"
        $SubPath = "\Software\Sharp"

    foreach ($RegHKU in $users){
        $folder = "HKU:" + $RegHKU + $SubPath
        Write-Host $folder
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Remove `'$($folder)`' HKU Sharp key"
        remove-item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue #-Whatif
        }
#endregion Delete HKU Sharp Registry path


#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log
