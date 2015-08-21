<#
.Synopsis
   The Ormer template for all PowerShell Scripts.
.DESCRIPTION
   The Ormer template for all PowerShell Scripts that are executed using a Kaseya Procedure.
   The template includes all requirements for scripts and logging.
.EXAMPLE
   Example of how to use this script
.EXAMPLE
   Another example of how to use this script
.NOTES
   Author: Managed Services
   Version: 1.0
   Revisions:
   01/01/2015 - Created Template. (Managed Services)
#>

[cmdletbinding()]
param (
    [parameter(mandatory=$true)]
    [string]$Operator,

    [parameter(mandatory=$true)]
    [string]$MachineGroup,

    [parameter(mandatory=$true)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$KworkingDir,
    
    [parameter(mandatory=$true)]
    [string]$FeatureChoice 
)

#region Functions
function Get-OSDetails()
{
    $OS =Get-WmiObject -class Win32_OperatingSystem

    $OSDetails = New-Object -TypeName PSObject -Property @{
        'Caption' = $OS.Caption
        'FullVersion' = $OS.Version 
        'MajorVersion' = [int]$OS.Version.ToString().Split('.')[0]
        'MinorVersion' = [int]$OS.Version.ToString().Split('.')[1]
        'BuildVersion' = [int]$OS.Version.ToString().Split('.')[2]      
        'Type' = ''
        'Architecture' = $OS.OSArchitecture
    }

    if($OS.ProductType -gt 1)
    {
        $OSDetails.Type = "Server"
    }
    else
    {
        $OSDetails.Type = "Client"
    }
    Return $OSDetails
}
#endregion

#region StandardFramework
Import-Module -Name OrmLogging -Prefix 'Orm' -ErrorAction SilentlyContinue -ErrorVariable ImportModuleOrmLoggingError
if($ImportModuleOrmLoggingError)
{
    Write-Error "Unable to import the Ormer Logging Powershell Module"
    Write-Error "$($ImportModuleOrmLoggingError.Exception.Message)"
    Break
}
Import-Module -Name OrmToolkit -Prefix 'Orm' -ErrorAction SilentlyContinue -ErrorVariable ImportModuleOrmToolkitError
if($ImportModuleOrmToolkitError)
{
    Write-Error "Unable to import the Ormer Toolkit Powershell Module"
    Write-Error "$($ImportModuleOrmToolkitError.Exception.Message)"
    Break
}

Set-Location $KworkingDir -ErrorAction SilentlyContinue -ErrorVariable SetLocationError
if($SetLocationError)
{
    Write-Error "Unable to set the working directory of the script"
    Write-Error "$($SetLocationError.Exception.Message)"
    Break
}
    
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
$Customer = $MachineGroup.Split('.')[2]

$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'Procname' = $Procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

Remove-Item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
#endregion StandardFramework
    
#region Execution
New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Starting procedure: $($procname)"

#check the OS Details to determine if the procedure should continue
$OSDetails = Get-OSDetails

if($OSDetails.Type -eq "Server")
{ 
    if($OSDetails.MajorVersion -eq 6 -and $OSDetails.MinorVersion -eq 1)
    {
        #supported for Add-WindowsFeature (Server 2008 R2)
        $AddWindowsFeature = $true
    }
    else
    {
        if($OSDetails.MajorVersion -ge 6 -and $OSDetails.MinorVersion -gt 0)
        {
            #supported for Install-WindowsFeature (Server 2012+)
            $InstallWindowsFeature = $true
        }
        else
        {
            New-OrmLog -logvar $logvar -Status 'Success' -LogDir $KworkingDir -ErrorAction Stop -Message "Unsupported OS: $($OSDetails.Caption)"
            New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Procedure failed: $($procname)" 
            Break
        } 
    }        
} 

#Import the ServerManager Module
New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Importing the ServerManager Module..."
Import-Module ServerManager -Force -ErrorAction SilentlyContinue -ErrorVariable ImportModuleError
if (!($ImportModuleError))
{
    New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "ServerManager Module Succesfully Imported"      
}  
else
{
    New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message "Failed to Import the ServerManager Module. The following error occured:"
    New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message "$($ImportModuleError.Message):"
    New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Procedure failed: $($procname)"
    Break    
} 

#check if the Windows Feature is already installed
New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Checking if $($FeatureChoice) is already installed..."
$Feature = Get-WindowsFeature -Name $FeatureChoice

if($Feature -eq $null)
{
    New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message "$($FeatureChoice) is not a valid feature name"
    New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Procedure failed: $($procname)"
}

if($Feature.Installed -eq $true)
{
     New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Feature $($Feature.Name) already installed."
     New-OrmLog -logvar $logvar -Status 'Success' -LogDir $KworkingDir -ErrorAction Stop -Message "Procedure completed: $($procname)"   
}
else
{
    #install the Windows Feature
    New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Installing Feature:$($FeatureChoice)."
    if($InstallWindowsFeature -eq $true)
    {
        Install-WindowsFeature -Name $FeatureChoice -IncludeAllSubFeature -IncludeManagementTools -ErrorAction SilentlyContinue -ErrorVariable InstallWindowsFeatureError
    }

    if($AddWindowsFeature -eq $true)
    {
        Add-WindowsFeature -Name $FeatureChoice -IncludeAllSubFeature -ErrorAction SilentlyContinue -ErrorVariable InstallWindowsFeatureError
    }
    if(!($InstallWindowsFeatureError))
    {
        New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Feature:$($FeatureChoice) installed succesfully."
        New-OrmLog -logvar $logvar -Status 'Success' -LogDir $KworkingDir -ErrorAction Stop -Message "Procedure completed: $($procname)"
    }
    else
    {
        New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message "An error occured when installing feature:$($FeatureChoice). The following error occured:"
        New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message $InstallWindowsFeatureError.Exception.Message
        New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Procedure failed: $($procname)"
    }
}
#endregion Execution