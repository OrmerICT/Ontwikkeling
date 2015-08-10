function Clean-WSUS {
    [cmdletbinding()]
    param ()
f_New-Log -logvar $logvar -status 'Info' -Message 'Loading the WSUS assembly' -LogDir $KworkingDir
  try
  {
    [reflection.assembly]::LoadWithPartialName("Microsoft.UpdateServices.Administration") | Out-Null
    $CleanUpScope = New-Object Microsoft.UpdateServices.Administration.CleanupScope
    f_New-Log -logvar $logvar -status 'Success' -Message 'Loaded the WSUS assembly' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to load the WSUS assembly' -LogDir $KworkingDir
    return
  }

  f_New-Log -logvar $logvar -status 'Info' -Message 'Cleaning computers not contacting the WSUS server' -LogDir $KworkingDir
  try
  {
    #Computers not contacting the server
    'Computers not contacting the server'
    $cleanUpScope.CleanupObsoleteComputers = $true
    $WSUSServer= [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
    $cleanUpManager = $WSUSServer.GetCleanupManager()
    $CleanUpManager.PerformCleanup($cleanupScope)
    f_New-Log -logvar $logvar -status 'Success' -Message 'Cleaned computers not contacting the WSUS server' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to clean computers not contacting the WSUS server' -LogDir $KworkingDir
  }

  f_New-Log -logvar $logvar -status 'Info' -Message 'Cleaning expired updates' -LogDir $KworkingDir
  try
  {
    #Expired Updates
    'Expired Updates'
    $cleanUpScope.DeclineExpiredUpdates = $true
    $WSUSServer= [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
    $cleanUpManager = $WSUSServer.GetCleanupManager()
    $CleanUpManager.PerformCleanup($cleanupScope)
    f_New-Log -logvar $logvar -status 'Success' -Message 'Cleaned expired updates' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to clean expired updates' -LogDir $KworkingDir
  }

  f_New-Log -logvar $logvar -status 'Info' -Message 'Cleaning unused updates and update revisions' -LogDir $KworkingDir
  try
  {
    #Unused Updates and Update Revisions
    'Unused Updates and Update Revisions'
    $CleanUpScope.CleanObsoleteUpdates = $true
    $WSUSServer= [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
    $cleanUpManager = $WSUSServer.GetCleanupManager()
    $CleanUpManager.PerformCleanup($cleanupScope)
    f_New-Log -logvar $logvar -status 'Success' -Message 'Cleaned unused updates and update revisions' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to clean unused updates and update revisions' -LogDir $KworkingDir
  }

  f_New-Log -logvar $logvar -status 'Info' -Message 'Cleaning superseded updates' -LogDir $KworkingDir
  try
  {
    #Superseded Updates
    'Superseded Updates'
    $cleanUpScope.DeclineSupersededUpdates = $true
    $WSUSServer= [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
    $cleanUpManager = $WSUSServer.GetCleanupManager()
    $CleanUpManager.PerformCleanup($cleanupScope)
    f_New-Log -logvar $logvar -status 'Success' -Message 'Cleaned superseded updates' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to clean superseded updates' -LogDir $KworkingDir
  }

  f_New-Log -logvar $logvar -status 'Info' -Message 'Cleaning unneeded update files' -LogDir $KworkingDir
  try
  {
    #Unneeded update files
    'Unneeded update files'
    $cleanUpScope.CleanupUnneededContentFiles = $true
    $WSUSServer= [Microsoft.UpdateServices.Administration.AdminProxy]::GetUpdateServer()
    $cleanUpManager = $WSUSServer.GetCleanupManager()
    $CleanUpManager.PerformCleanup($cleanupScope)
    f_New-Log -logvar $logvar -status 'Success' -Message 'Cleaned unneeded update files' -LogDir $KworkingDir
  }
  catch
  {
    f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to clean unneeded update files' -LogDir $KworkingDir
  }
}

Export-ModuleMember -Function 'Clean-WSUS'