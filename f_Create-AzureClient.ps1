###################################
## FUNCTION 8 - f_Create-AzureClient
###################################

#Creates member servers

Function f_Create-AzureClient {

Param(
      #The admin user account 
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminUser,

      #The admin password
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminPassword,

      #The secure password
      [parameter(Position=3)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword,

      #The FQDN of the Active Directory forest
      [parameter(Position=4)]
      [String]$ForestFqdn,

      #The NetBios name of the Active Directory domain
      [parameter(Position=5)]
      [String]$Domain,

      #Credentials for the dcpromo
      [parameter(Position=6)]
      $DomainCredential,

      #The number of DCs to spin up
      [parameter(Position=7)]
      [ValidateRange(1,4)]
      [Single]$ClientCount,

      #The type of client, e.g. Win7 or Win8
      [parameter(Position=8)]
      [ValidateSet("Win7", "Win8")]
      [String]$ClientType
      )


    #Set VM size
    $Size = "Small"
    
    #Obtain client image to be used
    If ($ClientType -eq "Win7") {
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Obtaining the latest Windows 7 image"
        Write-Debug "About to obtain the latest Windows 7 image"
    
        #Get the latest Windows 7 OS image
        $Image = (Get-AzureVMImage | 
                  Where-Object {$_.Label -like "Windows 7 Enterprise SP1 (x64)*"} | 
                  Sort-Object PublishedDate -Descending)[0].ImageName
    
            #Error handling
            If ($Image) {
    
                #Write details of current subscription to screen
                Write-Verbose "$(Get-Date -f T) - Image found - $($Image)"
    
            }   #End of If ($Image)
            Else {
    
                #Write Error and exit
                Write-Error "Unable to obtain valid OS image"

                #Exit the function
                Exit
    
            }   #End of Else ($Image)
    
    
    }   #End of If ($ClientType -eq "Win7")
     
    Else {
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Obtaining the latest Windows 8 image"
        Write-Debug "About to obtain the latest Windows 8 image"
    
        #Get the latest Windows 8 OS image
        $Image = (Get-AzureVMImage | 
                  Where-Object {$_.Label -like "Windows 8.1 Enterprise (x64)*"} | 
                  Sort-Object PublishedDate -Descending)[0].ImageName
    
            #Error handling
            If ($Image) {
    
                #Write details of current subscription to screen
                Write-Verbose "$(Get-Date -f T) - Image found - $($Image)"
    
            }   #End of If ($Image)
            Else {
    
                #Write Error and exit
                Write-Error "Unable to obtain valid OS image"

                #Exit the function
                Exit
    
            }   #End of Else ($Image)

    
    }   #End of Else ($ClientType -eq "Win7")


    #Create a loop to process each additional client needed
    for ($i = 1; $i -le $ClientCount; $i++) {
 

        #Set VM name
        $VMName = "$($klantId)CLI$(($ClientType).SubString(3))0$i".ToUpper()
        
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Commissioning client - $VMName"
        Write-Debug "About to commission client - $VMName"
        
        
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Creating VM config"
        Write-Debug "About to create VM config"
        
        #Create a VM config
        $VMConfig = New-AzureVMConfig -Name $VMName -InstanceSize $Size -ImageName $Image |
                    Add-AzureProvisioningConfig -WindowsDomain -AdminUsername $AdminUser -Password $AdminPassword -JoinDomain $ForestFqdn `
                                                -Domain $Domain -DomainUserName $AdminUser -DomainPassword $AdminPassword |
                    Set-AzureSubnet -SubnetNames "$SubnetName"
        

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
        f_Create-AzureVM -VMName $VMName -Location $Location -vNetName $vNetName -VMConfig $VMConfig -AzureDns $AzureDns

        
    }   #End of for ($i = 1; $i -le $ClientCount; $i++)


}   #End of Function f_Create-AzureClient


##########################################################################################################