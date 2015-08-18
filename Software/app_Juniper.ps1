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
)

Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
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
    
#region Execution
f_New-Log -logvar $logvar -status 'Start' -Message "START $procname" -LogDir $KworkingDir

## Check if app already installed
$CheckApp = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object{$_. Displayname -Like "Juniper Networks Setup Client Activex Control"}
    if ($CheckApp) {
        f_New-Log -logvar $logvar -status 'Info' -Message 'JuniperSetupClientInstaller.exe already installed' -LogDir $KworkingDir
        }
    else {
        f_New-Log -logvar $logvar -status 'Info' -Message 'Juniper Networks Setup Client Activex Control not found' -LogDir $KworkingDir
        Start-Process -FilePath ".\JuniperSetupClientInstaller\JuniperSetupClientOCX.exe" -WorkingDirectory $KworkingDir -Wait
        Start-Process -FilePath ".\JuniperSetupClientInstaller\JuniperSetupClientOCX64.exe" -WorkingDirectory $KworkingDir -Wait
        f_New-Log -logvar $logvar -status 'Info' -Message 'JuniperSetupClientInstaller installed successfully' -LogDir $KworkingDir
        }
    
f_New-Log -logvar $logvar -status 'Info' -Message "Remove JuniperSetupClientInstaller install directory" -LogDir $KworkingDir
Remove-Item “.\JuniperSetupClientInstaller” -Recurse -force
f_New-Log -logvar $logvar -status 'Success' -Message "END $procname" -LogDir $KworkingDir

#endregion Execution
