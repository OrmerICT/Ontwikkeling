function f_CreateFirstDC {

#region Get the latest Windows Server 2012 R2 Datacenter OS image
    Write-Verbose "$(Get-Date -f T) - Obtaining the latest Windows Server 2012 R2 image"

    $Image = (Get-AzureVMImage | 
              Where-Object {$_.Label -like "Windows Server 2012 R2 Datacenter*"} | 
              Sort-Object PublishedDate -Descending)[0].ImageName

    #Error handling
    If ($Image) {

        #Write details of current subscription to screen
        Write-Verbose "$(Get-Date -f T) - Image found - $($Image)"

    }   #End of If ($Image)
    Else {

        #Write Error and exit
        Write-Error "Unable to obtain valid OS image " -ErrorAction Stop

    }   #End of Else ($Image)

#endregion Get the latest Windows Server 2012 R2 Datacenter OS image

#region Create a VM config
Write-Verbose "$(Get-Date -f T) - Commissioning first DC"

#Set VM specific variables (Name / Instance Size)
$VMName = "$DNSServerName"

$Size = "Small"

Write-Verbose "$(Get-Date -f T) - Creating VM config"

$VMConfig = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $Image |
            Add-AzureProvisioningConfig -Windows -AdminUsername $AdminUser -Password $AdminPassword |
            Add-AzureDataDisk -CreateNew -DiskSizeInGB 20 -DiskLabel "$($DNSServerName)-Data" -LUN 0 -HostCaching None |
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
#endregion Create a VM config

#region Create VM
    Write-Verbose "$(Get-Date -f T) - Creating VM $VMName"

    f_Create-AzureVM -VMName $VMName -Suffix $Suffix -Location $Location -vNetName $vNetName -VMConfig $VMConfig -AzureDns $AzureDns
#endregion Create VM
 
#region Convert password to a secure string
$SecurePassword = $AdminPassword | ConvertTo-SecureString -AsPlainText -Force

    #Error handling
    If ($SecurePassword) {

        #Write secure string confirmation to screen
        Write-Verbose "$(Get-Date -f T) - Admin password converted to a secure string"

     }   #End of If ($SecurePassword)
     Else {

        #Write Error and exit
        Write-Error "Unable to convert secure password" -ErrorAction Stop

    }   #End of Else ($SecurePassword)
#endregion Convert password to a secure string

#region Call f_Create-VmPsSession function
    Write-Verbose "$(Get-Date -f T) - Configuring certificate for PS Remoting access on $VMName$Suffix"

    f_Import-VMWinRmCert -VMName $VMName

    Write-Verbose "$(Get-Date -f T) - Creating PS Remoting session on $VMName"

    $DCSession = f_Create-VmPsSession -VMName $VMName -AdminUser $AdminUser -SecurePassword $SecurePassword -Suffix $Suffix
#endregion Call f_Create-VmPsSession function

#region Configure additional data drive
    Write-Verbose "$(Get-Date -f T) - Configure additional data drive on $VMName" 

    #Call f_Add-DcDataDrive function
    f_Add-DcDataDrive -VMSession $DCSession
#endregion Configure additional data drive

#region install the Active Directory domain services binaries
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
#endregion install the Active Directory domain services binaries

#region Create the forest
    Write-Verbose "$(Get-Date -f T) - Configuring forest $ForestFqdn on $VMName"
    Invoke-Command -Session $DCSession -ArgumentList $ForestFqdn,$Domain,$SecurePassword -ScriptBlock { 
    Param(
      #The forest name
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      $ForestFqdn,

      #The domain NetBios name
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      $Domain,

      #The DSRM password
      [parameter(Mandatory,Position=3)]
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

#region Remove the sessions
Write-Verbose "$(Get-Date -f T) - Removing PS Remoting session on $VMName" 

Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue

    #Error handling
    If (!$?) {

        #Write Error and exit
        Write-Error "Unable to remove PS Remoting session on $VMName"

    }   #End of If (!$?) 
    Else {

        Write-Verbose "$(Get-Date -f T) - $VMName PS Remoting session successfully removed"

    }   #End of Else (!$?)
#endregion Remove the sessions

} #End function CreateFirstDC
