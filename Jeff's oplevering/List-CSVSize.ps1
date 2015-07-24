function List-CSVSize {
<#
  .SYNOPSIS
  List the data size information of Cluster Shared Volumes.
  .DESCRIPTION
  List the data size information of Cluster Shared Volumes in GB, such as the size,
  free space, used space and the percentage of free space.
  .EXAMPLE
  List-CSVSize -ClusterName 'Cluster01.domain.local'
  .EXAMPLE
  List-CSVSize 'Cluster01'
  .NOTES
  Version  :  0.1
  Customer :  Ormer ICT
  Author   :  Jeff Wouters
#>
  [cmdletbinding()]
  param
  (
    [parameter(
      Mandatory=$true,
      Position=0
    )]
    [string]$ClusterName
  )
  Import-Module FailoverClusters
  foreach ( $csv in (Get-ClusterSharedVolume -Cluster $ClusterName))
  {
    foreach ( $csvinfo in ($csv | Select-Object -Property Name -ExpandProperty SharedVolumeInfo) )
    {
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