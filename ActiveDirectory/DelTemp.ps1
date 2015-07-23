###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################

#******************************************************************************
# File:     Deltemp.ps1
# Date:     07/14/2015
# Version:  1.0
#
# Purpose:  PowerShell script to clean Temp folders.
#
# Usage:    Deltemp -help | -path "<Font file or folder path>"
#
# Copyright (C) 2015 Ormer ICT  By PvdW
#
# https://social.technet.microsoft.com/Forums/en-US/159e6c66-a8e4-40a5-80b0-c43f4837bcd6/deleting-a-folder-in-all-users-profiles?forum=ITCG
# 
#
# Revisions:
# ----------
# 1.0.0   07/15/2015   Created script.
# 
#******************************************************************************


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

Set-Location $KworkingDir
    
. .\WriteLog.ps1
 $Domain = $Domain0
#t $Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$procname = $MyInvocation.Scriptname.Split(“\”)[2]
#t $Customer = $MachineGroep.Split(“.”)[2]

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
function f_Clean1-Module{
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Loop"
   Get-ChildItem -Path $SearchRoot | ForEach-Object {
        if ($_.PSIsContainer -eq ,$true) {
           if ((Get-ChildItem -Path $_.FullName) -eq $null) {
            Write-Host "$($_.FullName) is empty."
            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Check: `'$($_.FullName)`' Is empty"
                       
        } else {
            Write-Host "$($_.FullName) is not empty."
            Remove-Item $($_.FullName) -recurse -ErrorAction SilentlyContinue
            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Remove`'$($_.FullName)`' folder"
            }
    }
  } 
}

   #End of Function f_Clean1-Module
##########################################################################################################

#*******************************************************************
# Function Clean2012 Clean User Profile Temp folders
#
#*******************************************************************
function f_Clean_Users-2012-Module{

foreach ($user in $users){
$folder = "C:\Users\" + $user + $SubPath
#Write-Host $folder, $user, $users
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Remove `'$($folder)`' temp files"
Remove-Item $folder\* -Recurse -Force -ErrorAction silentlycontinue #-WhatIf
}
}                 
   #End of Function f_Clean_Users-Module
##########################################################################################################

#*******************************************************************
# Function Clean2003 Clean User Profile Temp folders
#
#*******************************************************************
function f_Clean_Users-2003-Module{

foreach ($user in $users){
$folder = "C:\Documents and Settings\Users\" + $user + $SubPath
Write-Host $folder, $user
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Remove `'$($folder)`' temp files"
Remove-Item $folder\* -Recurse -Force -ErrorAction silentlycontinue -WhatIf
}
}                 
   #End of Function f_Clean_Users-Module
##########################################################################################################

#*******************************************************************
# Main Script
#*******************************************************************
Set-ExecutionPolicy unrestricted

# Write $LogDir, $Customer, $KworkingDir
remove-item "C:\kworking\ProcedureLog.log" -Force
    
#region Execution
f_Logging-Module
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message $procname
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Clean Temp folders Script"
# f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Check: `'$($KworkingDir)`' Working Folder"

# Clean local Temp folder 
$SearchRoot = "C:\temp"
f_Clean1-Module
#$users = Get-ChildItem "C:\"
#$SubPath = "temp"
#f_Clean_Users-2012-Module

# Clean User Profile Temp folders
$users = Get-ChildItem "C:\Users"
$SubPath = "\AppData\Local\temp"
f_Clean_Users-2012-Module

# Clean User (2008) Internet Temp folders
$users = Get-ChildItem "C:\Users"
$SubPath = "\local settings\Temporary Internet Files"
f_Clean_Users-2012-Module

# Clean User (2008) Temp folders
$users = Get-ChildItem "C:\Users"
$SubPath = "\local settings\Temp"
f_Clean_Users-2012-Module

# Clean User (2012) Internet Temp folders
$SubPath = "\AppData\Local\Microsoft\Windows\INetCache"
f_Clean_Users-2012-Module 

# Clean User (2012) Internet Temp folders
$users = Get-ChildItem "C:\Users"
$SubPath = "\local settings\Microsoft\Windows\Temporary Internet Files"
f_Clean_Users-2012-Module

# Clean User Dropbox Temp folders
$SubPath = "\Dropbox\.Dropbox.Cache"
f_Clean_Users-2012-Module 

# Clean (2003) User Internet Temp folders
$users = Get-ChildItem "C:\Documents and Settings\Users"
$SubPath = "\Local Settings\Temporary Internet Files"
f_Clean_Users-2003-Module

# Clean (2003) User Temp folders
$users = Get-ChildItem "C:\Documents and Settings\Users"
$SubPath = "\Local Settings\Temp"
f_Clean_Users-2003-Module

 
#endregion Execution




