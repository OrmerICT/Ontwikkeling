#region For each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\, Remove all subkeys under \Printers\<GUID>
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "Removing all KEYS below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\<servername>\Printers and <servername>\Monitors\Client Side Port]"
$printServersCounter = 0
$printServers = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers"
foreach ($printServer in $printServers){
    $printServersCounter++
    WriteToLog "Working on Registry KEY [$($printServer.Name)]"
    $printServerPrinterCounter = 0
    $printServerPrinters = Get-ChildItem Registry::"$($printServer.Name)\Printers"
    foreach ($printServerPrinter in $printServerPrinters){
        $printServerPrinterCounter++ 
        WriteToLog "Removing Registry KEY [$($printServerPrinter.Name)]..."
        Remove-Item -Path Registry::$printServerPrinter -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printServerPrinter.Name)] succesfully removed"             
        }
        else{
            WriteToLog  "Error during removal of Registry KEY [$($printServerPrinter.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }
    }
    if ($printServerPrinterCounter -eq 0){
        WriteToLog "No registry KEYS found in [$($printServer.Name)\Printers]. Nothing to remove."
    }
    else{
        WriteToLog "Removed [$($printServerPrinterCounter)] registry KEYS in [$($printServer.Name)\Printers]"
    }
    WriteToLog "---------------------------------------------------------------------------------------------------------------------------"

    $printServerClientSidePortsCounter = 0
    $printServerClientSidePorts = Get-ChildItem Registry::"$($printServer.Name)\Monitors\Client Side Port"
    foreach ($printServerClientSidePort in $printServerClientSidePorts){
        $printServerClientSidePortsCounter++ 
        WriteToLog "Removing Registry KEY [$($printServerClientSidePort.Name)]..."
        Remove-Item -Path Registry::$printServerClientSidePort -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printServerClientSidePort.Name)] succesfully removed"            
        }
        else{
            WriteToLog  "Error during removal of Registry KEY [$($printServerClientSidePort.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }
    }
    if ($printServerClientSidePortsCounter -eq 0){
        WriteToLog "No registry KEYS found in [$($printServer.Name)\Monitors\Client Side Port]. Nothing to remove."
    }
    else{
        WriteToLog "Removed [$($printServerClientSidePortsCounter)] registry KEYS in [$($printServer.Name)\Monitors\Client Side Port]"
    }
    WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
     
}
if ($printServersCounter -eq 0){
    WriteToLog "No registry KEYS found in [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers]. Nothing to remove."
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region Remove KEY [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\Software\SHARP] and all subkeys
$keyToRemove = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\Software\SHARP"
WriteToLog "Removing Registry KEY [$($keyToRemove)]..."
if((Test-Path -Path Registry::"$($keyToRemove)") -eq $true){    
    Remove-Item -Path Registry::"$($keyToRemove)" -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
    if(!($removeItemError)){
        WriteToLog  "Registry KEY [$($keyToRemove)] succesfully removed"            
    }
    else{
        WriteToLog  "Error during removal of Registry KEY [$($keyToRemove)]:`n`t`t`t$($removeItemError[0].Exception)" 
    }       
}
else{
    WriteToLog "Registry KEY [$($keyToRemove)] not found. Nothing to remove."
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region for each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that starts with { and ends with }, remove key
WriteToLog "Removing all KEYS below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers] that start with [{] and end with [}]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("{") -and $printerKey.PSChildName.ToString().EndsWith("}")){
        $printerKeyCounter++ 
        WriteToLog "Removing Registry KEY [$($printerKey.Name)]..."
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printerKey.Name)] succesfully removed"            
        }
        else{
           WriteToLog  "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }          
    }           
}
if ($printerKeyCounter -eq 0){
    WriteToLog "No registry KEYS that start with [{] and end with [}] found. Nothing to remove."
}
else{
    WriteToLog "Removed [$($printerKeyCounter)] registry KEYS that start with [{] and end with [}]"
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region for each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that have 'redirected' or 'omgeleid' in the name of the key
WriteToLog "Removing all KEYS below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers] that have [redirected] or [omgeleid] in the name of the key"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString() -match "redirected" -or $printerKey.PSChildName.ToString() -match "omgeleid"){
        $printerKeyCounter++ 
        WriteToLog "Removing Registry KEY [$($printerKey.Name)]..."
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printerKey.Name)] succesfully removed"            
        }
        else{
           WriteToLog  "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }          
    }           
}
if ($printerKeyCounter -eq 0){
    WriteToLog "No registry KEYS that have [redirected] or [omgeleid] in the name of the key found. Nothing to remove."
}
else{
    WriteToLog "Removed [$($printerKeyCounter)] registry KEYS that had [redirected] or [omgeleid] in the name of the key"
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region for each SUBKEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that start with [CSR|], remove all SUBKEYS
WriteToLog "Removing all SUBKEYS of SUBKEYS starting with [CSR|] below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("CSR|")){
    #if($printerKey.PSChildName.ToString() -match [regex]::escape("CSR|")){
        $printerKeyCounter++ 
        WriteToLog "Removing Registry KEY [$($printerKey.Name)]..."
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printerKey.Name)] succesfully removed"            
        }
        else{
           WriteToLog  "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }          
    }           
}
if ($printerKeyCounter -eq 0){
    WriteToLog "No registry KEYS starting with [CSR|] found. Nothing to remove."
}
else{
    WriteToLog "Removed [$($printerKeyCounter)] registry KEYS starting with [CSR|]"
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region for each KEY below HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers that starts with { and ends with }, remove key
WriteToLog "Removing all KEYS below [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers] that start with [{] and end with [}]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("{") -and $printerKey.PSChildName.ToString().EndsWith("}")){
        $printerKeyCounter++ 
        WriteToLog "Removing Registry KEY [$($printerKey.Name)]..."
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printerKey.Name)] succesfully removed"            
        }
        else{
           WriteToLog  "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }          
    }           
}
if ($printerKeyCounter -eq 0){
    WriteToLog "No registry KEYS that start with [{] and end with [}] found. Nothing to remove."
}
else{
    WriteToLog "Removed [$($printerKeyCounter)] registry KEYS that start with [{] and end with [}]"
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region for each SUBKEY below HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers that start with [CSR|], remove all SUBKEYS
WriteToLog "Removing all SUBKEYS of SUBKEYS starting with [CSR|] below [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("CSR|")){
    #if($printerKey.PSChildName.ToString() -match [regex]::escape("CSR|")){
        $printerKeyCounter++ 
        WriteToLog "Removing Registry KEY [$($printerKey.Name)]..."
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
            WriteToLog  "Registry KEY [$($printerKey.Name)] succesfully removed"            
        }
        else{
           WriteToLog  "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)" 
        }          
    }           
}
if ($printerKeyCounter -eq 0){
    WriteToLog "No registry KEYS starting with [CSR|] found. Nothing to remove."
}
else{
    WriteToLog "Removed [$($printerKeyCounter)] registry KEYS starting with [CSR|]"
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region Remove KEY [HKU\.Default\Software\SHARP] and all subkeys
$keyToRemove = "HKU\.Default\Software\SHARP"
WriteToLog "Removing Registry KEY [$($keyToRemove)]..."
if((Test-Path -Path Registry::"$($keyToRemove)") -eq $true){    
    Remove-Item -Path Registry::"$($keyToRemove)" -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
    if(!($removeItemError)){
        WriteToLog  "Registry KEY [$($keyToRemove)] succesfully removed"            
    }
    else{
        WriteToLog  "Error during removal of Registry KEY [$($keyToRemove)]:`n`t`t`t$($removeItemError[0].Exception)" 
    }       
}
else{
    WriteToLog "Registry KEY [$($keyToRemove)] not found. Nothing to remove."
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion

#region for each VALUE under HKU\.Default\Printers\DevModePerUser, remove all VALUES starting with [\\CSR|]
WriteToLog "Removing all registry VALUES starting with [\\CSR|] in [HKU\.Default\Printers\DevModePerUser]"
$regValues = (Get-Item -Path Registry::"HKU\.Default\Printers\DevModePerUser").Property 
$printerValueCounter = 0
foreach($regValue in $regValues){    
    if($regValue.ToString().StartsWith("\\CSR|")){   
        $printerValueCounter++ 
        WriteToLog "Removing Registry VALUE [$($regValue)]..."
        Remove-ItemProperty -Path Registry::"HKU\.Default\Printers\DevModePerUser" -Name $regValue -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemPropertyError        
        if(!($removeItemPropertyError)){
            WriteToLog  "Registry VALUE [$($regValue)] succesfully removed"            
        }
        else{
           WriteToLog  "Error during removal of Registry VALUE [$($regValue)]:`n`t`t`t$($removeItemPropertyError[0].Exception)" 
        }          
    }    
}

if ($printerValueCounter -eq 0){
    WriteToLog "No registry VALUES that start with [\\CSR|] found. Nothing to remove."
}
else{
    WriteToLog "Removed [$($printerValueCounter)] registry VALUES starting with [\\CSR|]"
}
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
WriteToLog "---------------------------------------------------------------------------------------------------------------------------"
#endregion