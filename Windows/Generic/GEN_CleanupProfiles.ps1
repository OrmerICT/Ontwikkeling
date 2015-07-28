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

    [parameter(mandatory=$true)]
    [ValidateRange(1,31)] 
    [int]$ProfileAgeLimit
)

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

Function Fix-UnremovableProfileFolders{
  param (
    [System.IO.FileSystemInfo]$UserProfileFolder
  )
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

Function Close-FileHandles{
    param (
        [ValidateScript({if((Test-Path $_ -PathType 'Leaf') -eq $true -and ((Get-Item $_).Name.ToLower()) -eq "handle.exe"){Return $true}else{Return $false}})] 
        [parameter(mandatory=$true)]
        [string]$PathToHandleEXE,

        [ValidateScript({(Test-Path $_ -PathType 'Container') -or (Test-Path $_ -PathType 'Leaf')})] 
        [parameter(mandatory=$true)]
        [string]$PathToProcess
    )

    #write the registry value to suppress the display of the license agreement, so handle can run attended
    if((Test-Path "HKCU:\Software\Sysinternals\Handle") -eq $false){
        New-Item -Path "HKCU:\Software\Sysinternals\Handle" -Force    
    }
    Set-ItemProperty -Path "HKCU:\Software\Sysinternals\Handle" -Name "EulaAccepted" -Value 1

    #get the open handles for the file/folder
    $handles = (& $PathToHandleEXE $PathToProcess)  

    # Get the count of lines in the output 
    $count=($handles.Count)-1

    #handle output starts at line 5
    for ($i = 5; $i -le $count -and $count -gt 5; $i++){
        # Get the Process Id for each file        
        $MYPID=($handles[$i].Substring(24,7)).Trim()

        # Get the Hexadecimal ID for each open file              
        $HEX=($handles[$i].Substring(41,14)).Trim()

        # Close the open handle and check the results   
        $closeresult = (& $PathToHandleEXE -c $HEX -p $MYPID -y)        
        if($closeresult[7].Trim() -eq "Handle closed."){
            $result = $true
        }
    }
    if($result -eq $true){
        Return $true
    }
    else{
        Return $false
    }
}
#endregion

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

Remove-Item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Executing: $($KworkingDir)\$($procname) Script"
#endregion StandardFramework
    
#region Execution

#specify age limit for user profiles
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Maximum age for existing user profiles: $($ProfileAgeLimit) days"

#cleanup registry
$profileAgeLimitDate = (Get-Date).AddDays(($profileAgeLimit * -1))
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Maximum date for existing user profiles: $($profileAgeLimitDate)"
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
                f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Fixing unremovable profile folders in profile $($profileImagePath)"
                Fix-UnremovableProfileFolders -UserProfileFolder (Get-item $profileImagePath)
                if((Test-Path $profileImagePath\NTUSER.DAT) -eq $true){
                    if((Get-Item $profileImagePath\NTUSER.DAT).LastWriteTime -lt $profileAgeLimitDate){
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Last write time of NTUSER.DAT: $((Get-Item $profileImagePath\NTUSER.DAT).LastWriteTime)"                        
                        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "$($profileImagePath)\NTUSER.DAT is older then $($profileAgeLimitDate), profile:$($profileImagePath) will be removed"
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
                        #f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Closing open file handles referencing $($profileImagePath)"
                        #$closeFileHandlesResult = Close-FileHandles -PathToHandleEXE "$($KworkingDir)\Handle.exe" -PathToProcess $profileImagePath -ErrorAction SilentlyContinue -ErrorVariable closeFileHandleError
                        #if(!($closeFileHandleError) -and ($closeFileHandlesResult -eq $true)){
                            #f_New-Log -logvar $logvar -status 'Success' -LogDir $KworkingDir -Message "Sucessfully closed open file handles referencing $($profileImagePath)"
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
                        #}
                        #else{
                            #f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error while closing open file handles referencing $($profileImagePath):$($closeFileHandleError[0].Exception)"
                            #f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Resetting profile removal action" 
                            #$removeLocalProfile = $false
                            #f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "`$removeLocalProfile:$($removeLocalProfile)"
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
f_New-Log -logvar $logvar -status 'Successs' -Message 'Procedure Completed' -LogDir $KworkingDir
#endregion Execution