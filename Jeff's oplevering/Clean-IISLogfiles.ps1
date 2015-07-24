function Clean-IISLogfiles
{
<#
  .SYNOPSIS
  Clean the IIS log files.
  .DESCRIPTION
  Clean the IIS log files older than XX days, where the default is 31 days.
  .EXAMPLE
  Clean-IISLogFiles -Path 'C:\inetpub\logs\LogFiles\W3SVC1' -Days '10'
  .EXAMPLE
  Clean-IISLogFiles 'C:\inetpub\logs\LogFiles\W3SVC1' -Days '10'
  .EXAMPLE
  Clean-IISLogFiles 'C:\inetpub\logs\LogFiles\W3SVC1'
  .NOTES
  Version  :  0.1
  Customer :  Ormer ICT
  Author   :  Jeff Wouters
#>
  param (
    [parameter(
        Mandatory=$false,
        Position=0
    )]$Path = 'C:\inetpub\logs\LogFiles\W3SVC1',
    [parameter(
        Mandatory=$false
    )]$Days = 31
  )
  foreach ($File in (Get-ChildItem -Path $Path))
  {
    if (!$File.PSIsContainerCopy) 
    {
      if ($File.LastWriteTime -lt ($(Get-Date).Adddays(-$days))) 
      {
        try
        {
          Remove-Item -Path $File -Force
          Write-Verbose "Removed logfile $File"
        } catch {
          Write-Verbose "Error: Unable to removed logfile $File"
        }
      }
    }
  } 
}