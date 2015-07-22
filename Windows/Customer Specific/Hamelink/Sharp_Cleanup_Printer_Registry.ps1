###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     Cleanup_Printer_Registry.ps1
# Date:     07/22/2015
# Version:  0.1
#
# Purpose:  PowerShell script to add a new user.
#
# Usage:    Cleanup_Printer_Registry.ps1
# Needed: Remote administration tools to load the server manager
#
# Copyright (C) 2015 Ormer ICT 
#
# Revisions:
# ----------
# 0.1.0   07/22/2015   Created script.
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
    [string]$KworkingDir

#Procedure Vars
#    [parameter(mandatory=$true)]
#    [string]$printServers
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


#region Start For each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\, Remove all subkeys under \Printers\<GUID>

    $KeyPath = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers"
    f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all KEYS below:`'$($KeyPath)`'Run"

    $printServersCounter = 0
    $printServers = Get-ChildItem -Path Registry::$KeyPath -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
 
    foreach ($printServer in $printServers){
             $printServersCounter++
             f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Working on Registry KEY [$($printServer.Name)]"
             $printServerPrinterCounter = 0
             $printServerPrinters = Get-ChildItem Registry::"$($printServer.Name)\Printers"
    foreach ($printServerPrinter in $printServerPrinters){
             $printServerPrinterCounter++
             f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printServerPrinter.Name)]..." 
             Remove-Item -Path Registry::$printServerPrinter -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
            if(!($removeItemError)){
             f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printServerPrinter.Name)] succesfully removed"
            }
        else{
            f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printServerPrinter.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
            }
            }
     if ($printServerPrinterCounter -eq 0){
            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS found in [$($printServer.Name)\Printers]. Nothing to remove."
            }
        else{
            f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printServerPrinterCounter)] registry KEYS in [$($printServer.Name)\Printers]"
    }
#endregion For each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers\, Remove all subkeys under \Printers\<GUID>

#region Start Delete Monitors\Client Side Port key
         $printServerClientSidePortsCounter = 0
         $printServerClientSidePorts = Get-ChildItem Registry::"$($printServer.Name)\Monitors\Client Side Port" -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
    foreach ($printServerClientSidePort in $printServerClientSidePorts){
         $printServerClientSidePortsCounter++ 
         f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printServerClientSidePort.Name)]..."
         Remove-Item -Path Registry::$printServerClientSidePort -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
         f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printServerClientSidePort.Name)] succesfully removed"
         }
     else{
         f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printServerClientSidePort.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
        }
    }
    if ($printServerClientSidePortsCounter -eq 0){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS found in [$($printServer.Name)\Monitors\Client Side Port]. Nothing to remove."
        }
    else{
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "moved [$($printServerClientSidePortsCounter)] registry KEYS in [$($printServer.Name)\Monitors\Client Side Port]"
        }
  }
    if ($printServersCounter -eq 0){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS found in [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers]. Nothing to remove."
}
#endregion Start Delete Monitors\Client Side Port key


#region Start Remove KEY [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\Software\SHARP] and all subkeys
$keyToRemove = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\Software\SHARP"
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing Registry KEY [$($keyToRemove)]..."
if((Test-Path -Path Registry::"$($keyToRemove)") -eq $true){    
    Remove-Item -Path Registry::"$($keyToRemove)" -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
    if(!($removeItemError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($keyToRemove)] succesfully removed"
        }
    else{
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($keyToRemove)]:`n`t`t`t$($removeItemError[0].Exception)"
        }       
}
else{
    f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($keyToRemove)] not found. Nothing to remove."
    }
#endregion Remove KEY [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Terminal Server\Install\Software\SHARP] and all subkeys

#region for each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that starts with { and ends with }, remove key
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all KEYS below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers] that start with [{] and end with [}]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers" -ErrorAction SilentlyContinue
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("{") -and $printerKey.PSChildName.ToString().EndsWith("}")){
        $printerKeyCounter++
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printerKey.Name)]..." 
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printerKey.Name)] succesfully removed"
        }
    else{
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
        }          
        }           
    }
if ($printerKeyCounter -eq 0){
       f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS that start with [{] and end with [}] found. Nothing to remove."
    }
    else{
       f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printerKeyCounter)] registry KEYS that start with [{] and end with [}]"
}
#endregion for each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that starts with { and ends with }, remove key


#region Start for each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that have 'redirected' or 'omgeleid' in the name of the key
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all KEYS below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers] that have [redirected] or [omgeleid] in the name of the key"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString() -match "redirected" -or $printerKey.PSChildName.ToString() -match "omgeleid"){
        $printerKeyCounter++
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printerKey.Name)]..."  
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printerKey.Name)] succesfully removed"
        }
    else{
         f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
        }          
    }           
}
    if ($printerKeyCounter -eq 0){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS that have [redirected] or [omgeleid] in the name of the key found. Nothing to remove."
        }
    else{
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printerKeyCounter)] registry KEYS that had [redirected] or [omgeleid] in the name of the key"
}
#endregion for each KEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that have 'redirected' or 'omgeleid' in the name of the key

#region Start for each SUBKEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that start with [CSR|], remove all SUBKEYS
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all SUBKEYS of SUBKEYS starting with [CSR|] below [HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("CSR|")){
    #if($printerKey.PSChildName.ToString() -match [regex]::escape("CSR|")){
        $printerKeyCounter++
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printerKey.Name)]..." 
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printerKey.Name)] succesfully removed"
        }
    else{
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
        }          
    }           
}
if ($printerKeyCounter -eq 0){
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS starting with [CSR|] found. Nothing to remove."
}
else{
f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printerKeyCounter)] registry KEYS starting with [CSR|]"
}
#endregion for each SUBKEY below HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Printers that start with [CSR|], remove all SUBKEYS

#region Start for each KEY below HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers that starts with { and ends with }, remove key
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all KEYS below [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers] that start with [{] and end with [}]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("{") -and $printerKey.PSChildName.ToString().EndsWith("}")){
        $printerKeyCounter++
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printerKey.Name)]..." 
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printerKey.Name)] succesfully removed"
        }
        else{
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
        }          
    }           
}
    if ($printerKeyCounter -eq 0){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS that start with [{] and end with [}] found. Nothing to remove."
    }
    else{
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printerKeyCounter)] registry KEYS that start with [{] and end with [}]"
}
#endregion for each KEY below HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers that starts with { and ends with }, remove key

#region start for each SUBKEY below HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers that start with [CSR|], remove all SUBKEYS
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all SUBKEYS of SUBKEYS starting with [CSR|] below [HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers]"
$printerKeys = Get-ChildItem -Path Registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers"
$printerKeyCounter = 0
foreach ($printerKey in $printerKeys){
    if($printerKey.PSChildName.ToString().StartsWith("CSR|")){
    #if($printerKey.PSChildName.ToString() -match [regex]::escape("CSR|")){
        $printerKeyCounter++
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry KEY [$($printerKey.Name)]..." 
        Remove-Item -Path Registry::$printerKey -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
        if(!($removeItemError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($printerKey.Name)] succesfully removed"
        }
    else{
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($printerKey.Name)]:`n`t`t`t$($removeItemError[0].Exception)"
        }          
    }           
}
    if ($printerKeyCounter -eq 0){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry KEYS starting with [CSR|] found. Nothing to remove."
}
    else{
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printerKeyCounter)] registry KEYS starting with [CSR|]"
}
#endregion for each SUBKEY below HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Print\Printers that start with [CSR|], remove all SUBKEYS

#region start Remove KEY [HKU\.Default\Software\SHARP] and all subkeys
        $keyToRemove = "HKU\.Default\Software\SHARP"
        f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing Registry KEY [$($keyToRemove)]..."
    if((Test-Path -Path Registry::"$($keyToRemove)") -eq $true){    
        Remove-Item -Path Registry::"$($keyToRemove)" -Recurse -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemError
    if(!($removeItemError)){
         f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($keyToRemove)] succesfully removed"
         }
    else{
         f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry KEY [$($keyToRemove)]:`n`t`t`t$($removeItemError[0].Exception)"
         }       
    }
    else{
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry KEY [$($keyToRemove)] not found. Nothing to remove."
  }
#endregion Remove KEY [HKU\.Default\Software\SHARP] and all subkeys

#region start for each VALUE under HKU\.Default\Printers\DevModePerUser, remove all VALUES starting with [\\CSR|]
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Removing all registry VALUES starting with [\\CSR|] in [HKU\.Default\Printers\DevModePerUser]"
$regValues = (Get-Item -Path Registry::"HKU\.Default\Printers\DevModePerUser").Property 
$printerValueCounter = 0
foreach($regValue in $regValues){    
    if($regValue.ToString().StartsWith("\\CSR|")){   
        $printerValueCounter++
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removing Registry VALUE [$($regValue)]..."
        Remove-ItemProperty -Path Registry::"HKU\.Default\Printers\DevModePerUser" -Name $regValue -Force -ErrorAction SilentlyContinue  -ErrorVariable removeItemPropertyError        
    if(!($removeItemPropertyError)){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Registry VALUE [$($regValue)] succesfully removed"
        }
    else{
        f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Error during removal of Registry VALUE [$($regValue)]:`n`t`t`t$($removeItemPropertyError[0].Exception)"
        }          
    }    
}

    if ($printerValueCounter -eq 0){
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "No registry VALUES that start with [\\CSR|] found. Nothing to remove."
  }
    else{
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Removed [$($printerValueCounter)] registry VALUES starting with [\\CSR|]"
  }
#endregion for each VALUE under HKU\.Default\Printers\DevModePerUser, remove all VALUES starting with [\\CSR|]     

#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log
