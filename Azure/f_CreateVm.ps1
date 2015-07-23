Function f_CreateVm {

Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $VMName,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $Suffix,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $Location,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $vNetName,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $VmConfig,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $AzureDns
      )

    #region Create Azure VM

    Write-Verbose "$(Get-Date -f T) - NewAzureVM $($VMName+$Suffix)"
    #Create a new VM and new cloud service
    New-AzureVM -ServiceName "$($VMName+$Suffix)" -Location $Location -VNetName $vNetName -VMs $VmConfig -DnsSettings $AzureDns -WaitForBoot | Out-Null
             
    #endregion Create Azure VM

    #region Error handling

    If (!$?) {
        #Write Error and exit
        Write-Verbose "$(Get-Date -f T) - Something went wrong with the VM creation - we may still be ok though..."
        }   #End of If (!$?) 
    Else {
        #Troubleshooting message
        Write-Verbose "$(Get-Date -f T) - VM created successfully"
        }   #End of Else (!$?)

    #endregion Error handling

    #Troubleshooting messages
    Write-Verbose "$(Get-Date -f T) - Checking $VMName status"

    #region Get the VM status

    $VMService = Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName -ErrorAction SilentlyContinue
    
    #Check we've got status information
    If ($VMService) {
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - $VMName status verified"
        }   #End of If ($VMService)
    Else {
        #Write error and carry on 
        Write-Error "Failed to obtain status for VM $VMName exiting build function"
        }   #End of ($VMService)

    #endregion Get the VM status

}   #End of Function f_CreateVm
