###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     Template.ps1
# Date:     ??/??/????
# Version:  0.1
#
# Purpose:  PowerShell script to add a new user.
#
# Usage:    Template.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
# 
# 
#
# Revisions:
# ----------
# 0.1.0   ??/??/????   Created script.
#    
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
#    [parameter(mandatory=$true)]
#    [string]$UserName
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

#region Load module ???
      
#endregion Load module ????



#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log
