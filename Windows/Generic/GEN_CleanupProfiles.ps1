Function Global:WriteToLog
{param ([string]$logentry,[string]$messageType)
    $logfile = "C:\kworking\CleanupProfilesFromRegistry.log" #bepaal logfile waar diagnostische informatie in wordt weggeschreven
    if ($messageType -eq "INF"){
        (Get-Date -Format "dd-MM-yyyy:hh:mm:ss").ToString() + "`t" + "(INF)" + "`t" + $logentry | Out-File $logfile -Append
    }
    if ($messageType -eq "ERR"){
        (Get-Date -Format "dd-MM-yyyy:hh:mm:ss").ToString() + "`t" + "(ERR)" + "`t" + $logentry | Out-File $logfile -Append
    }
    if ($messageType -ne "INF" -and $messageType -ne "ERR"){     
        (Get-Date -Format "dd-MM-yyyy:hh:mm:ss").ToString() + "`t" + $logentry | Out-File $logfile -Append
    }    
}

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
                WriteToLog "Error setting ACL on $($folder.FullName)" "ERR"
            }
        }
    }
}

#specify age limit for user profiles
$profileAgeLimit = -14

#cleanup registry
$profileAgeLimitDate = (Get-Date).AddDays($profileAgeLimit)
$profileList = Get-ChildItem -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
foreach ($profile in $profileList){
    $profileName = $profile.Name      
    $profileImagePath = $profile.GetValue("ProfileImagePath")
    $profileGuid = $profile.GetValue("Guid")
    $removeLocalProfile = $false
    $profileImagePathExists = $true    

    WriteToLog "Registry key:$($profileName)" "INF"
    WriteToLog "Gebruiker:$($profileImagePath)" "INF"

    if ($profileName -match "S-1-5-21" -and $profileName.EndsWith("-500") -eq $false){    
        if ($profileName.Substring($profileName.Length - 3, 3).ToUpper() -eq "BAK"){
            WriteToLog "Naam van het profiel eindigt op .BAK, verwijder lokaal profiel EN registry keys" "INF"
            $removeLocalProfile = $true
        }
        WriteToLog "`$removeLocalProfile:$($removeLocalProfile)" "INF"
       
        if ($profileImagePath){
            WriteToLog "profileImagePath:$($profileImagePath)" "INF"  
              
            if (!(Test-Path $profileImagePath)){                
                WriteToLog "$($profileImagePath) bestaat niet, registry key:$($profile.Name) wordt verwijderd" "INF"
                $profileImagePathExists = $false
            }
            else{
                Fix-UnremovableProfileFolders -UserProfileFolder (Get-item $profileImagePath)
                if((Test-Path $profileImagePath\NTUSER.DAT) -eq $true){
                    if((Get-Item $profileImagePath\NTUSER.DAT).LastWriteTime -lt $profileAgeLimitDate){
                        WriteToLog "$($profileImagePath)\NTUSER.DAT is ouder dan $($profileAgeLimit) dagen, profiel:$($profileImagePath) kan worden verwijderd" "INF"
                        $removeLocalProfile = $true
                    }
                }
                else{
                    WriteToLog "$($profileImagePath) bestaat, maar $($profileImagePath)\NTUSER.DAT bestaat niet, profiel:$($profileImagePath) kan worden verwijderd" "INF"
                    $removeLocalProfile = $true
                }
                if($removeLocalProfile -eq $true){
                    #check if the user belonging to the profile is not logged in
                    $profileUser = (Get-Item $profileImagePath).Name
                    $logonStatus = Get-LogonStatus -userName $profileUser
                    if($logonStatus -eq $false){
                        WriteToLog "$($profileUser) is niet ingelogd" "INF"
                        WriteToLog "$($profileImagePath) bestaat en `$removeLocalProfile = `$true, registry key:$($profile.Name) en $($profileImagePath) worden verwijderd" "INF"
                        WriteToLog "$($profileImagePath) wordt verwijderd" "INF"                        
                        Start-Process -FilePath "CMD.exe" -ArgumentList "/C RMDIR /S /Q `"$($profileImagePath)`"" -Wait -NoNewWindow
                        if((Test-Path $profileImagePath) -eq $true){
                            WriteToLog "Er is een fout opgetreden bij het verwijderen van het lokale profiel" "ERR"
                            $removeLocalProfile = $false
                        }
                        #Remove-Item -Path $profileImagePath -Force -Recurse -ErrorAction SilentlyContinue -ErrorVariable removeLocalProfileError
                        #if($removeLocalProfileError){
                        #    WriteToLog "Lokaal profiel kon niet worden verwijderd:$($removeLocalProfileError[0].Exception)" "ERR"
                        #}
                    }
                    else{
                        WriteToLog "$($profileUser) is ingelogd, er worden geen acties uitgevoerd" "INF"
                        $removeLocalProfile = $false
                    }
                }            
            }
            if ($profileImagePathExists -eq $false -or $removeLocalProfile -eq $true){
                WriteToLog "Registry key:$($profile.Name) wordt verwijderd" "INF"
                Remove-Item "Registry::$($profile.Name)" -ErrorAction SilentlyContinue -ErrorVariable removeProfileKeyError -Recurse
                if(!($removeProfileKeyError)){
                    WriteToLog "Registry key succesvol verwijderd" "INF"
                    if($profileGuid){
                        WriteToLog "profileGuid:$($profileGuid)" "INF"
                        $profileGuidPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileGuid\$($profileGuid)"                                   
                        if (Test-Path -Path "Registry::$($profileGuidPath)"){
                            WriteToLog "$($profileGuidPath) bestaat, registry key wordt verwijderd" "INF"
                            Remove-Item "Registry::$($profileGuidPath)" -ErrorAction SilentlyContinue -ErrorVariable removeProfileGuidKeyError -Recurse
                            if(!($removeProfileGuidKeyError)){
                                WriteToLog "Registry key succesvol verwijderd" "INF"
                            }
                            else{
                                WriteToLog "Fout bij verwijderen registry key:$($removeProfileGuidKeyError[0].Exception)" "ERR"
                            }
                        }
                    }    
                    else{
                        WriteToLog "profileGuid waarde bestaat niet of kan niet worden uitgelezen" "ERR"
                    }
                }
                else{
                    WriteToLog "Fout bij verwijderen registry key:$($removeProfileKeyError[0].Exception)" "ERR"
                }
            }
            else{
                WriteToLog "Lokaal profiel bestaat en hoeft niet verwijderd te worden" "INF"
                WriteToLog "Geen acties noodzakelijk" "INF"
            }
        }
        else{
            WriteToLog "ProfileImagePath waarde bestaat niet of kan niet worden uitgelezen" "ERR"
        }
    } 
    else{
        WriteToLog "$($profileName) is geen Domeinaccount" "INF"
        WriteToLog "Geen acties noodzakelijk" "INF"
    }   
    WriteToLog "------------------------------------------------------"  
}