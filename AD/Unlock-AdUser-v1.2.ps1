###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
<###############################################################################

#******************************************************************************
# File:     Unlock-AdUser-v1.1.ps1
# Date:     07/16/2015
# Version:  1.0
#
# Purpose:  PowerShell script to clean Temp folders.
#
# Usage:    Unlock-AdUser-v1.1.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
# http://www.informit.com/articles/article.aspx?p=729101&seqNum=5
# http://bobausmus.blogspot.nl/2013/10/powershell-module-and-snapin-checks.html
#
# Revisions:
# ----------
# 1.0.0   07/16/2015   Created script.
# 1.1.0   07/17/2015   Error logging aangepast By PvdW
# 1.2.0   07/17/2015   Error logging aangepast By PvdW
#>#******************************************************************************

#*******************************************************************
# Declare Parameters
#*******************************************************************

#*******************************************************************
# Declare Global Variables and Constants
#*******************************************************************

# Define constants

# Initialize variables

#   Test Settings   ###
$KworkingDir = "c:\kworking\"
#$LogDir = "c:\kworking\"
$MachineGroep = "MG_01.mg"
#$Operator = "Operator-Ducje"
#$procname  = "ProcesName-DelTmp"
#$TDNumber  = "TD12345"
$Customer  = "CU-TestDucje"
#$Domain0 = "DO-Ducje"
#$UserName = "Test-Ducje"
#$Title = "Unlock AD User"

#*******************************************************************
#  Load C# code
#*******************************************************************

#*******************************************************************
# Declare Functions
#*******************************************************************
function f_Logging-Module {
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
                [String] $PassWord,

                [Parameter(Mandatory=$false)]
                [String] $Domain = $env:USERDOMAIN
)
}
#write-host $KworkingDir
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $Domain0
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$procname = $MyInvocation.Scriptname.Split(“\”)[2]
$Customer = $MachineGroep.Split(“.”)[2]

#region Object
$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}
#endregion Object

#*******************************************************************
# Function Clean1 Temp Folder -1
#
#*******************************************************************

   #End of Function f_Clean1-Module
##########################################################################################################

#*******************************************************************
# Function Clean2012 Clean User Profile Temp folders
#
#*******************************************************************
   #End of Function f_Clean_Users-Module
##########################################################################################################

#*******************************************************************
# Function Clean2003 Clean User Profile Temp folders
#
#*******************************************************************
   #End of Function f_Clean_Users-Module
##########################################################################################################

#*******************************************************************
# Main Script
#*******************************************************************
Set-ExecutionPolicy unrestricted

# Write $LogDir, $Customer, $KworkingDir
remove-item "C:\kworking\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
    
#region Execution
f_Logging-Module
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Unlock AS User Account Script"
# f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Title: `'$($KworkingDir)`' Script"

# Load module Server manager
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
 
# Install RSAT-AD-PowerShell
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Check if RSAT-AD-PowerShell is installed"
$RSAT = (Get-WindowsFeature -name RSAT-AD-PowerShell).Installed 

If ($RSAT -eq $false)
{
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "RSAT-AD-PowerShell not found: `'$($RSAT)`'"

Add-WindowsFeature RSAT-AD-PowerShell
f_New-Log -logvar $logvar -status 'start' -LogDir $KworkingDir -Message "Add Windows Feature RSAT-AD-PowerShell"

Import-module ActiveDirectory
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Import module ActiveDirectory"
}
Else
{
f_New-Log -logvar $logvar -status 'start' -LogDir $KworkingDir -Message "Windows Feature RSAT-AD-PowerShell installed"
}

#Import Module Active Directory
if ((get-module -name ActiveDirectory -ErrorAction SilentlyContinue | foreach { $_.Name }) -ne "ActiveDirectory")
{
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Adding ActiveDirectory PowerShell module" 
import-module ActiveDirectory
}
else
{
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "ActiveDirectory PowerShell module is Already loaded" 
}

#Check if user is disabled
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

#Unlock Account
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Unlock user account: `'$($UserName)`'"
Unlock-ADAccount -Identity $UserName


 
#endregion Execution




