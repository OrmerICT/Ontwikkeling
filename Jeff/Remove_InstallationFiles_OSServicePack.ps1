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

    [parameter(mandatory=$false)]
    $Path = 'C:\inetpub\logs\LogFiles\W3SVC1',

    [parameter(mandatory=$false)]
    $Days = 31
)

#region StandardFramework
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
$Customer = $MachineGroep.Split('.')[2]


$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

Remove-Item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title: `'$Kworking`' Script"
#endregion StandardFramework
    
#region Execution
# Remove ServicePack installation files - After this an ServicePack can't be uninstalled!!!
f_New-Log -logvar $logvar -status 'Info' -Message 'Removing old installation files from OS Service Pack(s)' -LogDir $KworkingDir
try {
  dism /online /cleanup-image /spsuperseded /NoRestart /Quiet
  f_New-Log -logvar $logvar -status 'Success' -Message 'Removed old installation files from OS Service Pack(s)' -LogDir $KworkingDir
}
catch
{
  f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to remove old installation files from OS Service Pack(s)' -LogDir $KworkingDir
}
#endregion Execution
