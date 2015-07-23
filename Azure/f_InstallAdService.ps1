 Function f_InstallAdService {

Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $VMName,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $DCSession
      )
 
    Write-Verbose "$(Get-Date -f T) - Configure AD DS binaries on $VMName" 
    $ConfigureBinaries = Invoke-Command -Session $DCSession -ScriptBlock {Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools}

    #Error handling
    If ($ConfigureBinaries) {

        #Write details of current subscription to screen
        Write-Verbose "$(Get-Date -f T) - AD DS binaries added to $VMName"

    }   #End of If ($ConfigureBinaries)
    Else {
        #Write Error and exit
        Write-Error "Unable to install AD DS binaries on $VMName" -ErrorAction Stop
        } #End of Else ($ConfigureBinaries)
} # End of Function f_InstallAdService
