function f_CreateVmConfig {
Param(

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $VMName,
     
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $InstanceSize,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $Image,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $AdminUser,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $AdminPassword,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $DCDataDisk,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $DNSServerName,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      $SubnetNumber

      )

#region Create VM config

    Write-Verbose "$(Get-Date -f T) - Commissioning $VMName"




    Write-Verbose "$(Get-Date -f T) - Creating VM config"

    $VmConfig = New-AzureVMConfig -Name $VMName -InstanceSize $InstanceSize -ImageName $Image |
                Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUser -Password $AdminPassword |
                Add-AzureDataDisk -CreateNew -DiskSizeInGB $DCDataDisk -DiskLabel "$($DNSServerName)-Data" -LUN 0 -HostCaching None |
                Set-AzureSubnet -SubnetNames "$SubnetName" |
                Set-AzureStaticVNetIP -IPAddress "10.10.$($SubnetNumber).20"

    #Error handling
    If ($VMConfig) {

                    #Write details of current subscription to screen
                    Write-Verbose "$(Get-Date -f T) - VMConfig created"

                }   #End of If ($Image)
    Else {

                    #Write Error and exit
                    Write-Error "Unable to create VM config" -ErrorAction Stop

                }   #End of Else ($Image)
return $VMConfig
} #End f_CreateVmConfig

#endregion Create VM config