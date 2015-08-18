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
  f_New-Log -logvar $logvar -status 'Info' -Message 'Getting snapshots of virtual machines' -LogDir $KworkingDir
  try
  {
    Get-VM | Get-VMSnapshot
    f_New-Log -logvar $logvar -status 'Error' -Message 'Got snapshots of virtual machines' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to get snapshots of virtual machines' -LogDir $KworkingDir
    return
  }
#endregion Execution
