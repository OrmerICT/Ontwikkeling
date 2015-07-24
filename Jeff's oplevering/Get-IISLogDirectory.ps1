function Get-IISLogDirectory
{
  <#
      .SYNOPSIS
      Get the IIS log directory.
      .DESCRIPTION
      Get the IIS log directory.
      .NOTES
      Version  :  0.1
      Customer :  Ormer ICT
      Author   :  Jeff Wouters
  #>
  [cmdletbinding()]
  param ()
  try {
    Import-Module WebAdministration
    (Get-WebConfigurationProperty '/system.applicationHost/sites/siteDefaults' -Name 'logfile.directory').Value
  }
  catch {
    Write-Error $_
  }
}