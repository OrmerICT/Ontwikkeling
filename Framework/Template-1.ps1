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
# Revisions:
# ----------
# 0.1.0   ??/??/????   Created script.
#    
#>#******************************************************************************

#*******************************************************************
# Function Show-Usage()
#
# Purpose:   Shows the correct usage to the user.
#
# Input:     None
#
# Output:    Help messages are displayed on screen.
#
#*******************************************************************
function Show-Usage()
{
$usage = @'
Add-Font.ps1
This script is used to install Windows fonts.

Usage:

Help:
Add-Font.ps1 -help -path "<Font file or folder path>"

Install:
Add-Font.ps1 -path "<Font file or folder path>"

Parameters:

    -help
     Displays usage information.

    -path
     May be either the path to a font file to install or the path to a folder 
     containing font files to install.  Valid file types are .fon, .fnt,
     .ttf,.ttc, .otf, .mmm, .pbf, and .pfm

Examples:
    Add-Font.ps1
    Add-Font.ps1 -path "C:\Custom Fonts\MyFont.ttf"
    Add-Font.ps1 -path "C:\Custom Fonts"
'@

$usage
}


#*******************************************************************
# Function Process-Arguments()
#
# Purpose: To validate parameters and their values
#
# Input:   All parameters
#
# Output:  Exit script if parameters are invalid
#
#*******************************************************************
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

    
#*******************************************************************

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
