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
$GetProcName = Get-PSCallStack
$procname = $GetProcname.Command
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
# If an OS upgrade was performed, this removes old mountpoints from this upgrade.
f_New-Log -logvar $logvar -status 'Info' -Message 'Removing old mountpoints from OS upgrade' -LogDir $KworkingDir
try
{
  dism /Cleanup-Mountpoints
  f_New-Log -logvar $logvar -status 'Success' -Message 'Removed old mountpoints from OS upgrade' -LogDir $KworkingDir
}
catch
{
  f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to remove old mountpoints from OS upgrade' -LogDir $KworkingDir
}
#endregion Execution