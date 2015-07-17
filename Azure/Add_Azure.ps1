#Define and validate mandatory parameters
[CmdletBinding()]
Param(
      #CustomerName
      [parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [String] $CustomerName,

      #The NetBios name of the Active Directory domain to create
      [parameter(Mandatory=$true)]
      [String]$Domain,

      #The total number of DCs to spin up
      [parameter(Mandatory=$false)]
      [ValidateRange(1,4)]
      [Single]$DcCount = 0,

      #The number of member servers to spin up
      [parameter(Mandatory=$false)]
      [ValidateRange(0,4)]
      [Single]$RdsCount = 1,

      #The number of member servers to spin up
      [parameter(Mandatory=$false)]
      [ValidateRange(0,4)]
      [Single]$SqlCount = 0,

      #Specifies the value of the Class C subnet to be created for the virtual network, e.g. X in 10.10.X.0
      [parameter(Mandatory=$true)]
      [ValidateRange(0,255)]
      [Int]$SubnetNumber
      )



#Set strict mode to identify typographical errors
Set-StrictMode -Version Latest

#Let's make the script verbose by default
$VerbosePreference = "Continue"

####################
## Includes
####################

# Include param
. .\Param.ps1
# Include Stage 1
. .\f_LogonTest.ps1
# Stage 3
. .\f_Create-AzurevNetCfgFile.ps1
# Include Stage 4
. .\f_Update-AzurevNetConfig.ps1
# Include Stage 5
. .\f_Create-AzureVM.ps1
. .\f_Add-DcDataDrive.ps1
. .\f_Import-VMWinRmCert.ps1
. .\f_Create-VmPsSession.ps1
. .\f_Create-AzureServer.ps1
. .\f_Create-AzureRDS.ps1
. .\f_Create-AzureSQL.ps1





####################
## MAIN SCRIPT BODY
####################

##############################
#Stage 1 - Check Connectivity
##############################

#Logon Test Environment
f_LogonTest


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Checking Azure connectivity"
Write-Debug "About to check Azure connectivity"

#Check we have Azure connectivity
$Subscription = Get-AzureSubscription -Current 

    #Error handling
    If ($Subscription) {

        #Write details of current subscription to screen
        Write-Verbose "$(Get-Date -f T) - Current subscription found - $($Subscription.SubscriptionName)"

    }   #End of If ($Subscription)
    Else {

        #Write Error and exit
        Write-Error "Unable to obtain current Azure subscription details" -ErrorAction Stop

    }   #End of Else ($Subscription)




##################################
#Stage 2 - Check Storage Account
##################################

#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Referencing the storage account"
Write-Debug "About to reference the storage account"

#Reference the new storage account in preparation for the creation of VMs
Set-AzureSubscription -SubscriptionName ($Subscription).SubscriptionName -CurrentStorageAccountName $StorageAccountName -ErrorAction SilentlyContinue

    #Error handling
    If (!$?) {

        #Write Error and exit
        Write-Error "Unable to reference storage account" -ErrorAction Stop

    }   #End of If (!$?) 
    Else {

        #Troubleshooting message
        Write-Verbose "$(Get-Date -f T) - Storage account successfully referenced"

    }   #End of Else (!$?)





##############################
#Stage 3 - Check vNet
##############################

#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Check vNet"
Write-Debug "About to Check vNet"

#Variable for NetCfg file
$VnetSubNet = $(Get-AzureDeployment -ServiceName "$($CustomerId.ToUpper())-DC-01$Suffix" | Get-AzureDNS).Address.Split(“.”)[2]


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Subnetnumber is $VnetSubNet"
Write-Debug "Subnetnumber is $VnetSubNet"







######################################
#Stage 5 - Create First DC and Forest
######################################

#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Obtaining the latest Windows Server 2012 R2 image"
Write-Debug "About to obtain the latest Windows Server 2012 R2 image"

#Get the latest Windows Server 2012 R2 Datacenter OS image
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


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Commissioning first DC"
Write-Debug "About to commission first DC"

#Set VM specific variables (Name / Instance Size)
$VMName = "$DNSServerName"

$Size = "Small"


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating VM config"
Write-Debug "About to create VM config"

#Create a VM config
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


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating VM $VMName"
Write-Debug "About to create $VMName"

#Call f_Create-AzureVM function
f_Create-AzureVM -VMName $VMName -Suffix $Suffix -Location $Location -vNetName $vNetName -VMConfig $VMConfig -AzureDns $AzureDns


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Configuring certificate for PS Remoting access on $VMName$Suffix"
Write-Debug "About to configure certificate for PS Remoting access on $VMName$Suffix"

#Call f_Import-VMWinRmCert function
f_Import-VMWinRmCert -VMName $VMName


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Creating PS Remoting session on $VMName" 
Write-Debug "About to create PS Remoting session on $VMName" 

#Convert password to a secure string
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


#Call f_Create-VmPsSession function
$DCSession = f_Create-VmPsSession -VMName $VMName -AdminUser $AdminUser -SecurePassword $SecurePassword -Suffix $Suffix


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Configure additional data drive on $VMName" 
Write-Debug "About to configure additional data drive on $VMName" 

#Call f_Add-DcDataDrive function
f_Add-DcDataDrive -VMSession $DCSession


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Configure AD DS binaries on $VMName" 
Write-Debug "About to configure AD DS binaries on $VMName" 

#Now let's install the Active Directory domain services binaries
$ConfigureBinaries = Invoke-Command -Session $DCSession -ScriptBlock {Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools}

    #Error handling
    If ($ConfigureBinaries) {

        #Write details of current subscription to screen
        Write-Verbose "$(Get-Date -f T) - AD DS binaries added to $VMName"

    }   #End of If ($ConfigureBinaries)
    Else {

        #Write Error and exit
        Write-Error "Unable to install AD DS binaries on $VMName" -ErrorAction Stop

    }   #End of Else ($ConfigureBinaries)


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Configuring forest $ForestFqdn on $VMName" 
Write-Debug "About to configure forest $ForestFqdn on $VMName" 

#Now let's create the forest
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


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Verifying status of $VMName" 
Write-Debug "About to verify status of $VMName" 

#Get VM status
$VMStatus = Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName -ErrorAction SilentlyContinue

#Use a while loop to wait until 'ReadyRole' is achieved
While ($VMStatus.InstanceStatus -ne "ReadyRole") {

  #Write progress to verbose, sleep and check again  
  Start-Sleep -Seconds 60
  $VMStatus = Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName -ErrorAction SilentlyContinue

}   #End of While ($VMStatus.InstanceStatus -ne "ReadyRole")


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - InstanceStatus verification - $($VMStatus.InstanceStatus)"  


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Removing PS Remoting session on $VMName" 
Write-Debug "About to remove PS Remoting session on $VMName" 

#Remove the sessions
Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue

    #Error handling
    If (!$?) {

        #Write Error and exit
        Write-Error "Unable to remove PS Remoting session on $VMName"

    }   #End of If (!$?) 
    Else {

        #Troubleshooting message
        Write-Verbose "$(Get-Date -f T) - $VMName PS Remoting session successfully removed"

    }   #End of Else (!$?)



#################################
#Stage 6 - Create Additional DCs
#################################

#Check whether we have to create any additional DCs
If ($DcCount -gt 1) {

    #Create a domain identity
    $CombinedUser = "$($Domain)\$($AdminUser)"

    #Create a domain credential for the dcpromo
    $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CombinedUser,$SecurePassword

    $StartIp = $(get-azurevm  | measure-object).Count + 20

    #Call the f_Create-AzureServer function
    f_Create-AzureServer -CustomerId $CustomerId -Suffix $Suffix  -AdminUser $AdminUser -AdminPassword $AdminPassword -SecurePassword $SecurePassword -ForestFqdn $ForestFqdn -Domain $Domain -DomainCredential $DomainCredential -ServerCount ($DcCount - 1) -StartIp $StartIp -IsDC


}   #End of If ($DcCount -gt 1)



##########################
#Stage 7 - Create RDS
##########################

#Check whether we have to create any RDS Servers
If ($RdsCount -ge 1) {

    #Create a domain identity
    $CombinedUser = "$($Domain)\$($AdminUser)"

    #Create a domain credential for the dcpromo
    $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CombinedUser,$SecurePassword

    $StartIp = $(get-azurevm  | measure-object).Count + 20 

    #Call the f_Create-AzureRDS function for RDS
    f_Create-AzureRDS -CustomerId $CustomerId -AdminUser $AdminUser -AdminPassword $AdminPassword -SecurePassword $SecurePassword -ForestFqdn $ForestFqdn -Domain $Domain -DomainCredential $DomainCredential -RdsCount $RdsCount -StartIp $StartIp

}   #End of ($RdsCount -ge 1)



##########################
#Stage 8 - Create SQL
##########################

#Check whether we have to create any RDS Servers
If ($SqlCount -ge 1) {

    #Create a domain identity
    $CombinedUser = "$($Domain)\$($AdminUser)"

    #Create a domain credential for the dcpromo
    $DomainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $CombinedUser,$SecurePassword

    $StartIp = $(get-azurevm  | measure-object).Count + 20

    #Call the f_Create-AzureRDS function for RDS
    f_Create-AzureSQL -CustomerId $CustomerId -AdminUser $AdminUser -AdminPassword $AdminPassword -SecurePassword $SecurePassword -ForestFqdn $ForestFqdn -Domain $Domain -DomainCredential $DomainCredential -SqlCount $SqlCount -StartIp $StartIp

}   #End of ($RdsCount -ge 1)








###############################
#Stage 9 - That's all folks...
###############################

##Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Finished creating $ForestFqdn forest in Microsoft Azure!"
Write-Verbose "$(Get-Date -f T) - Script Ends Like a Boss"


##########################################################################################################
