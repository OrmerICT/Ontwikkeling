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
    [string]$ClusterName
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
f_New-Log -logvar $logvar -status 'Info' -Message 'Hello world' -LogDir $KworkingDir
Import-Module FailoverClusters
try {
  foreach ($csv in (Get-ClusterSharedVolume -Cluster $ClusterName))
  {
    f_New-Log -logvar $logvar -status 'Info' -Message "Getting disk utilization of $($CSV.Name)" -LogDir $KworkingDir
    foreach ($csvinfo in ($csv | Select-Object -Property Name -ExpandProperty SharedVolumeInfo))
    {
      f_New-Log -logvar $logvar -status 'Info' -Message "Getting CSVInfo of $($CSV.Name)" -LogDir $KworkingDir
      New-Object PSObject -Property @{
        Name        = $csv.Name
        Path        = $csvinfo.FriendlyVolumeName
        Size        = "$('{0:N2}' -f ($csvinfo.Partition.Size / 1GB)) GB"
        FreeSpace   = "$('{0:N2}' -f ($csvinfo.Partition.FreeSpace / 1GB)) GB"
        UsedSpace   = "$('{0:N2}' -f ($csvinfo.Partition.UsedSpace / 1GB)) GB"
        PercentFree = "$('{0:N2}' -f ($csvinfo.Partition.PercentFree)) %"
      }
    }
  }
}
catch
{
  f_New-Log -logvar $logvar -status 'Error' -Message "Unable to query CSV from cluster $ClusterName" -LogDir $KworkingDir
}
#endregion Execution
