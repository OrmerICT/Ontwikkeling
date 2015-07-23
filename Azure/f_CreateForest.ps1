#region Create the forest
Function f_CreateForest {

Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $ForestFqdn,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $Domain,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword
      )
    Write-Verbose "$(Get-Date -f T) - Configuring forest $ForestFqdn on $VMName"
    Invoke-Command -Session $DCSession -ArgumentList $ForestFqdn,$Domain,$SecurePassword -ScriptBlock { 
    Param(
      #The forest name
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $ForestFqdn,

      #The domain NetBios name
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $Domain,

      #The DSRM password
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword
      )

    #Promote the new forest
    Install-ADDSForest -CreateDnsDelegation:$False `
                       -DatabasePath "Z:\Windows\NTDS" `
                       -DomainMode "Win2012R2" `
                       -DomainName $ForestFqdn `
                       -DomainNetbiosName $Domain `
                       -ForestMode "Win2012R2" `
                       -InstallDns:$True `
                       -LogPath "Z:\Windows\NTDS" `
                       -NoRebootOnCompletion:$False `
                       -SysvolPath "Z:\Windows\SYSVOL" `
                       -Force:$True `
                       -SafeModeAdministratorPassword $SecurePassword `
                       -SkipPreChecks | Out-Null

}   #End of -ScriptBlock

#endregion Create the forest

#region Use a while loop to wait until 'ReadyRole' is achieved
Write-Verbose "$(Get-Date -f T) - Verifying status of $VMName" 

#Get VM status
$VMStatus = Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName -ErrorAction SilentlyContinue
While ($VMStatus.InstanceStatus -ne "ReadyRole") {

  #Write progress to verbose, sleep and check again  
  Start-Sleep -Seconds 60
  $VMStatus = Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName -ErrorAction SilentlyContinue

}   #End of While ($VMStatus.InstanceStatus -ne "ReadyRole")

Write-Verbose "$(Get-Date -f T) - InstanceStatus verification - $($VMStatus.InstanceStatus)"  

#endregion Use a while loop to wait until 'ReadyRole' is achieved
} #End Function f_CreateForest
