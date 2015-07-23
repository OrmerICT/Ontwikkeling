####################################
## FUNCTION 7 - f_Create-AzureDC
####################################

#Creates member servers

Function f_Create-AzureDC {

Param(
      #The CustomerId
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$CustomerId,

      #The CustomerId
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$Suffix,
      
      #The admin user account 
      [parameter(Mandatory,Position=3)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminUser,

      #The admin password
      [parameter(Mandatory,Position=4)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminPassword,

      #The secure password
      [parameter(Position=5)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword,

      #The FQDN of the Active Directory forest
      [parameter(Position=6)]
      [String]$ForestFqdn,

      #The NetBios name of the Active Directory domain to create
      [parameter(Position=7)]
      [String]$Domain,

      [parameter(Position=8)]
      [String]$Size,

      #Credentials for the dcpromo
      [parameter(Position=9)]
      $DomainCredential,

      #The number of DCs to spin up
      [parameter(Position=10)]
      [ValidateRange(1,4)]
      [Single]$ServerCount,

      #IP
      [parameter()]
      [Single]$StartIp,

      #Whether we're promoting a DC
      [Switch]
      $IsDC
      )

    #Create a loop to process each additional server needed
    for ($i = 1; $i -le $ServerCount; $i++) {
   

        #Check whether we're creating a DC and set the VMConfig accordingly
        If ($IsDc) {

            #Set VM name
            $VMName = "$($CustomerId)-DC-0$($i + 1)".ToUpper()
        
            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Commissioning domain controller - $VMName"
            Write-Debug "About to commission domain controller - $VMName"

            #Create a VM config
            $VMConfig = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $Image |
                        Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $AdminUser -Password $AdminPassword -JoinDomain $ForestFqdn `
                                                    -Domain $Domain -DomainUserName $AdminUser -DomainPassword $AdminPassword |
                        Add-AzureDataDisk -CreateNew -DiskSizeInGB 20 -DiskLabel "$($CustomerId)-0$($i + 1)-Data" -LUN 0 -HostCaching None |
                        Set-AzureSubnet -SubnetNames "$SubnetName" |
                        Set-AzureStaticVNetIP -IPAddress "10.10.$($SubnetNumber).$($i + $StartIp - 1)"

            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - VMConfig for $VMName created with IP 10.10.$($SubnetNumber).$($i + $StartIp - 1)"

        }   #End of If ($IsDc)
        Else {

            #Set VM name
            $VMName = "$($CustomerId)-MEM-0$i".ToUpper()

            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Commissioning member server - $VMName"
            Write-Debug "About to commission member server - $VMName"


            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Creating VM config"
            Write-Debug "About to create VM config"
        
            #Create a VM config
            $VMConfig = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $Image |
                        Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $AdminUser -Password $AdminPassword -JoinDomain $ForestFqdn `
                                                    -Domain $Domain -DomainUserName $AdminUser -DomainPassword $AdminPassword |
                        Set-AzureSubnet -SubnetNames "$SubnetName" |
                        Set-AzureStaticVNetIP -IPAddress "10.10.$($SubnetNumber).$($i + $StartIp - 1)"

            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - VMConfig for $VMName created with IP 10.10.$($SubnetNumber).$($i + $StartIp - 1)"


        }   #End of If ($IsDc)


        #Error handling
        If ($VMConfig) {
        
            #Write details of current subscription to screen
            Write-Verbose "$(Get-Date -f T) - VMConfig created"
        
        }   #End of If ($Image)
        Else {
        
            #Write Error and exit
            Write-Error "Unable to create VM config" 
        
        }   #End of Else ($Image)
        
        
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Creating VM $VMName"
        Write-Debug "About to create $VMName"
        
        #Call f_Create-AzureVM function
        f_Create-AzureVM -VMName $VMName -Suffix $Suffix -Location $Location -vNetName $vNetName -VMConfig $VMConfig -AzureDns $AzureDns

    
        #Perform additional actions for our DC
        If ($IsDC) {

            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Creating PS Remoting session on $VMName" 
            Write-Debug "About to create PS Remoting session on $VMName" 
            
            #Call f_Create-VmPsSession function
            $DCSession = f_Create-VmPsSession -VMName $VMName -AdminUser $AdminUser -SecurePassword $SecurePassword
            
            
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
                    Write-Error "Unable to install AD DS binaries on $VMName" 
            
                }   #End of Else ($ConfigureBinaries)
            
            
            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Adding $VMName to $ForestFqdn" 
            Write-Debug "About to add $VMName to $ForestFqdn" 
            
            #Now let's promote the DC
            Invoke-Command -Session $DCSession -ArgumentList $ForestFqdn,$SecurePassword,$DomainCredential -ScriptBlock { 
                Param(
                  #The forest name
                  [parameter(Mandatory,Position=1)]
                  [ValidateNotNullOrEmpty()]
                  $ForestFqdn,
            
                  #The DSRM password
                  [parameter(Mandatory,Position=2)]
                  [ValidateNotNullOrEmpty()]
                  $SecurePassword,

                  #The Domain credentials
                  [parameter(Mandatory,Position=3)]
                  [ValidateNotNullOrEmpty()]
                  $DomainCredential
                  )
                
                #Execute the dc promotion cmdlet
                Install-ADDSDomainController -Credential $DomainCredential `
                                             -CreateDnsDelegation:$False `
                                             -DatabasePath "Z:\Windows\NTDS" `
                                             -DomainName $ForestFqdn `
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
            $VMStatus = Get-AzureVM -ServiceName "$VMName+$Suffix" -Name $VMName -ErrorAction SilentlyContinue
            
            #Use a while loop to wait until 'ReadyRole' is achieved
            While ($VMStatus.InstanceStatus -ne "ReadyRole") {
            
              #Write progress to verbose, sleep and check again  
              Start-Sleep -Seconds 60
              $VMStatus = Get-AzureVM -ServiceName "$VMName+$Suffix" -Name $VMName -ErrorAction SilentlyContinue
            
            }   #End of While ($VMStatus.InstanceStatus -ne "ReadyRole")
            
            
            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - InstanceStatus verification - $($VMStatus.InstanceStatus)"    
            

            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Removing PS Remoting session on $VMName" 
            Write-Debug "About to remove PS Remoting session on $VMName" 
            
            #Remove the session
            Remove-PSSession $DCSession -ErrorAction SilentlyContinue
            
                #Error handling
                If (!$?) {
            
                    #Write Error and exit
                    Write-Error "Unable to remove PS Remoting session on $VMName"
            
                }   #End of If (!$?) 
                Else {
            
                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - $VMName PS Remoting session successfully removed"
            
                }   #End of Else (!$?) 


        }   #End of If ($IsDC)

        
    }   #End of for ($i = 1; $i -le $ServerCount; $i++)


}   #End of Function f_Create-AzureDC


##########################################################################################################