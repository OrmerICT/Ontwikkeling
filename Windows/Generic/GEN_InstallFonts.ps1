Function Global:WriteToLog
{param ([string]$logentry)   
    $logfile = "$($env:windir)\temp\InstallFonts.log" #bepaal logfile waar diagnostische informatie in wordt weggeschreven    
    (Get-Date -Format "dd-MM-yyyy:HH:mm:ss").ToString() + "`t" + $logentry | Out-File $logfile -Append
    Write-Host "$((Get-Date -Format "dd-MM-yyyy:HH:mm:ss").ToString())`t$($logentry)"
} 

Function Global:FileExists($file){
    if((Test-Path $file) -eq $true){
        WriteToLog "[$($file)] does exist"
        Return $true
    }
    else{
        WriteToLog "[$($file)] does not exist"
        Return $false
    }
}

Function Global:FolderExists($folder){
    if((Test-Path $folder) -eq $true){
        WriteToLog "[$($folder)] does exist"
        Return $true
    }
    else{
        WriteToLog "[$($folder)] does not exist"
        Return $false
    }
}

Function InstallFont([string]$fontPath, [string]$fontName){
    $shellObject = New-Object -Comobject Shell.Application
    $fontsNamespace =  $shellObject.NameSpace(0x14)

    if((FileExists("$($env:windir)\Fonts\$($fontName)")) -ne $true){
        WriteToLog "Installing font [$($fontName)]..."
        $copyFlag = [String]::Format("{0:x}", 4 + 16)       
        $fontsNamespace.CopyHere("$($fontPath)\$($fontName)", $copyFlag)        
        if((FileExists("$($env:windir)\Fonts\$($fontName)")) -eq $true){
            WriteToLog "Font [$($fontName)] was succesfully installed."
        }
        else{
            WriteToLog "Installation of font [$($fontName)] failed."  
        }            
    }
    else{
         WriteToLog "Font [$($fontName)] already installed."
    }  
}

#region deploy fonts
$FontsFolder = "<path to folder containing fonts>"

if ((FolderExists($FontsFolder)) -eq $true){
    $Fonts = (Get-Item -Path $FontsFolder).EnumerateFiles()
    foreach($Font in $Fonts){
        if($Font.Name.Substring($Font.Name.Length - 3, 3) -eq "otf"){            
            InstallFont $FontsFolder $Font.Name
        }
        else{
            WriteToLog "Font $($Font.Name) is not a valid font"
        }
    }
}
WriteToLog "--------------------------------------------------------------------------------------------------------"
#endregion