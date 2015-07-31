
###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     Add_WindowsFeature.ps1
# Date:     07/30/2015
# Version:  0.3
#
# Purpose:  PowerShell script to add a new Feature to a Windows server(s).
#
# Usage:    Add_WindowsFeature.ps1
# Needed: Remote administration tools to add a new Feature to a Windows server(s)
#
# Copyright (C) 2015 Ormer ICT 
# https://social.technet.microsoft.com/forums/windowsserver/en-US/26cc0a4e-306c-4a95-8313-ad6c09120e59/powershell-eindows-form-drop-down-selection
# Revisions:
# ----------
# 0.1.0   07/28/2015   Created script. (By PvdW)
# 0.2.0   07/30/2015   Updated script. (By PvdW)
# 0.3.0   07/31/2015   Updated script. Remove inputbox. Input nu via Kaseya (By PvdW)
#    
#>#******************************************************************************
#region Start Parameters
[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [string]$FeatureChoice,
    
    #[parameter(mandatory=$false)]
    #[string]$Procname,

    [parameter(mandatory=$true)]
    [string]$KworkingDir

#Procedure Vars
#    [parameter(mandatory=$true)]
#    [string]$UserName
)
#endregion Start Parameters

start-transcript -path c:\windows\temp\transcriptlog.txt 

#region Function Show-Usage
function Show-Usage()
{
$usage = @'
Add-Font.ps1
This script is used to Add Windows Features.

Usage:

Help:
Add_WindowsFeature.ps1 -help 

Install/Add:
Add_WindowsFeature.ps1 -kworking -TDnumber -FeatureChoice

Parameters:

    -help
     Displays usage information.

Examples:
    
'@

$usage
}
#endregion Function Show-Usage

#region Function Process-Arguments
function Process-Arguments()
{
    ## Write-host 'Processing Arguments'

    if ($unnamedArgs.Length -gt 0)
    {
        #write-host "The following arguments are not defined:"
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message 'The following arguments are not defined:'
        $unnamedArgs
    }

    if ($help -eq $true) 
    { 
        Show-Usage
        break
    }
}
#endregion Function Process-Arguments
	

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
#endregion StandardFramework
    
#region Start log
    f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title:`'$($Procname)`'Script"
#endregion Start log

#region start Feature install
 Import-Module ServerManager -Force; 
 f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Install Feature:`'$($FeatureChoice)`'"
 Add-WindowsFeature $FeatureChoice -ErrorAction Continue -ErrorVariable ProcessError
 Write-host "$ProcessError" 
 If ($ProcessError) {
     f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Failure Install Feature:`'$($FeatureChoice)`'"
}  Else{
     f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Add Feature:`'$($FeatureChoice)`'Ready"
}
    Get-WindowsFeature $FeatureChoice
#endregion start Feature install
 
#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log
Stop-transcript #-path c:\windows\temp\transcriptlog.txt