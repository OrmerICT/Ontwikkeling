###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     GEN_CleanupProfiles.ps1
# Date:     07/27/2015
# Version:  0.2
#
# Purpose:  PowerShell script to add a new user.
#
# Usage:    GEN_CleanupProfiles.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
#
# Revisions:
# ----------
# 0.1.0   07/17/2015   Created script.
# 0.2.0   07/27/2015   Logging aangepast (By PvdW)   
#>#******************************************************************************

#region start StandardFramework
[cmdletbinding()]
param(
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$false)]
    [string]$Username,

    [parameter(mandatory=$true)]
    [string]$KworkingDir,
  
#Procedure Vars
    [parameter(mandatory=$true)]
    [ValidateRange(1,31)] 
    [int]$ProfileAgeLimit,

    [System.IO.FileSystemInfo]$UserProfileFolder
)

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


#region Functions
Function Get-LogonStatus($userName){    
    $users = Get-WmiObject Win32_Process -Filter "Name = 'explorer.exe'"
    $loggedOnUsers = ,@()   
    foreach ($user in $users){        
        $loggedOnUsers+= ,@($user.GetOwner().Domain.ToString(),$user.GetOwner().User.ToString())
    }
    foreach ($loggedOnUser in $loggedOnUsers){
        if($loggedOnUser){
            if(($loggedOnUser[1].ToString()) -eq $userName){
                Return $true
                Break
            }
        }
    }
    Return $false  
}

#endregion Comments

#region FicremovableProfileFolders
Function Fix-UnremovableProfileFolders{
#[cmdletbinding()]
Write-host  $KworkingDir  
s
 
    $unremovableFolders = @()
    $unremovableFolders+= @("NTUSER.DAT")
    $unremovableFolders+= @("Application Data")
    $unremovableFolders+= @("Cookies")
    $unremovableFolders+= @("Local Settings")
    $unremovableFolders+= @("My Documents")
    $unremovableFolders+= @("NetHood")
    $unremovableFolders+= @("PrintHood")
    $unremovableFolders+= @("SendTo")
    $unremovableFolders+= @("Start Menu")
    $unremovableFolders+= @("Templates")
    $unremovableFolders+= @("AppData\Local\Application Data")
    $unremovableFolders+= @("AppData\Local\Temporary Internet Files")
    $unremovableFolders+= @("AppData\Local\History")
    foreach ($unremovableFolder in $unremovableFolders){
        $folder = "$($userProfileFolder)\$($unremovableFolder)"
        Set-ItemProperty -Path $folder -Name Attributes -Value "Normal" -ErrorAction SilentlyContinue | Out-Null
        if((Test-Path $folder) -eq $true){
            $folder = (Get-Item $folder)
            $acl = Get-Acl $folder
            $acl.Access | where-object {$_.AccessControlType -eq “Deny”} | Foreach-object { $acl.RemoveAccessRule($_) }
            Try{
                $folder.SetAccessControl($acl) | Out-Null
            }
            Catch{
                f_New-Log -logvar $logvar -status 'Failure' -LogDir $KworkingDir -Message "Error setting ACL on $($folder.FullName)"
            }
        }
    }
}
#endregion
   
#region Start log
    f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title:`'$($Procname)`'Script"
#endregion Start log

#region start CleanupProfiles
#specify age limit for user profiles
$profileAgeLimit = $ProfileAgeLimit
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Maximum age for existing user profiles: $([math]::abs($ProfileAgeLimit)) days"

#cleanup registry
#Set-Location $KworkingDir
$profileAgeLimitDate = (Get-Date).AddDays($profileAgeLimit)
$profileList = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
foreach ($profile in $profileList){
    $profileName = $profile.Name      
    $profileImagePath = $profile.GetValue("ProfileImagePath")
    $profileGuid = $profile.GetValue("Guid")
    $removeLocalProfile = $false
    $profileImagePathExists = $true    

    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry key:$($profileName)"
    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "User profile:$($profileImagePath)"

    if ($profileName -match "S-1-5-21" -and $profileName.EndsWith("-500") -eq $false){    
        if ($profileName.Substring($profileName.Length - 3, 3).ToUpper() -eq "BAK"){
            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Profile name ends with .BAK, local profile AND registry keys will be removed"
            $removeLocalProfile = $true
        }
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "`$removeLocalProfile:$($removeLocalProfile)"
       
        if ($profileImagePath){
            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "profileImagePath:$($profileImagePath)"  
              
            if (!(Test-Path $profileImagePath)){                
                f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileImagePath) doesn't exist, registry key:$($profile.Name) will be removed"
                $profileImagePathExists = $false
                f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "`$profileImagePathExists:$($profileImagePathExists)"
            }
            else{
                Fix-UnremovableProfileFolders -UserProfileFolder (Get-item $profileImagePath)
                if((Test-Path $profileImagePath\NTUSER.DAT) -eq $true){
                    if((Get-Item $profileImagePath\NTUSER.DAT).LastWriteTime -lt $profileAgeLimitDate){
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Last write time of NTUSER.DAT: $((Get-Item $profileImagePath\NTUSER.DAT).LastWriteTime)"
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileImagePath)\NTUSER.DAT is older then $([math]::abs($ProfileAgeLimit)) days, profile:$($profileImagePath) will be removed"
                        $removeLocalProfile = $true
                    }
                }
                else{
                    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileImagePath) exists, but $($profileImagePath)\NTUSER.DAT doesn't exist, profile:$($profileImagePath) will be removed"
                    $removeLocalProfile = $true
                }
                if($removeLocalProfile -eq $true){
                    #check if the user belonging to the profile is not logged in
                    $profileUser = (Get-Item $profileImagePath).Name
                    $logonStatus = Get-LogonStatus -userName $profileUser
                    if($logonStatus -eq $false){
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileUser) is not logged in"
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileImagePath) exists and `$removeLocalProfile = `$true, registry key:$($profile.Name) AND $($profileImagePath) will be removed"
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileImagePath) wordt verwijderd"
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Executing: CMD.exe /C RMDIR /S /Q `"$($profileImagePath)`""                     
                        Start-Process -FilePath "CMD.exe" -ArgumentList "/C RMDIR /S /Q `"$($profileImagePath)`"" -Wait -NoNewWindow
                        if((Test-Path $profileImagePath) -eq $true){
                            f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "An error occured during the removal of the local profile. Resetting profile removal action"                            
                            $removeLocalProfile = $false
                            f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "`$removeLocalProfile:$($removeLocalProfile)"
                        }
                        else{
                            f_New-Log -logvar $logvar -status 'Success' -LogDir $KworkingDir -Message "$($profileImagePath) removed succesfully"
                        }
                        #Remove-Item -Path $profileImagePath -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable removeLocalProfileError
                        #if($removeLocalProfileError){
                        #    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Lokaal profiel kon niet worden verwijderd:$($removeLocalProfileError[0].Exception)"
                        #}
                    }
                    else{
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileUser) is currently logged in, no actions will be performed"
                        $removeLocalProfile = $false
                    }
                }            
            }
            if ($profileImagePathExists -eq $false -or $removeLocalProfile -eq $true){
                f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry key:$($profile.Name) will be removed"
                Remove-Item "Registry::$($profile.Name)" -ErrorAction SilentlyContinue -ErrorVariable removeProfileKeyError -Recurse
                if(!($removeProfileKeyError)){
                    f_New-Log -logvar $logvar -status 'Success' -LogDir $KworkingDir -Message "Registry key:$($profile.Name) removed succesfully"
                    if($profileGuid){
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "profileGuid:$($profileGuid)"
                        $profileGuidPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGuid\$($profileGuid)"                                   
                        if (Test-Path -Path "Registry::$($profileGuidPath)"){
                            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry key: $($profileGuidPath) exists, registry key will be removed"
                            Remove-Item "Registry::$($profileGuidPath)" -ErrorAction SilentlyContinue -ErrorVariable removeProfileGuidKeyError -Recurse
                            if(!($removeProfileGuidKeyError)){
                                f_New-Log -logvar $logvar -status 'Success' -LogDir $KworkingDir -Message "Registry key:$($profileGuidPath) removed succesfully"
                            }
                            else{
                                f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error while removing registry key:$($removeProfileGuidKeyError[0].Exception)"
                            }
                        }
                    }    
                    else{
                        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "profileGuid value doesn't exist or can't be read"
                    }
                }
                else{
                    f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error while removing registry key:$($removeProfileKeyError[0].Exception)"
                }
            }
            else{
                f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Local profile exists and doesn't need to be removed"
                f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No actions required"
            }
        }
        else{
            f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "ProfileImagePath value doesn't exist or can't be read"
        }
    } 
    else{
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileName) is not a Domain User"
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No actions required"
    }
}

#endregion start CleanupProfiles

#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log
