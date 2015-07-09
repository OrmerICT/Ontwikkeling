###################################
## FUNCTION 8 - f_Create-AzureSQL
###################################

#Creates member servers

Function f_Create-AzureSQL {

Param(
      #The CustomerId
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$CustomerId,
            
      #The admin user account 
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminUser,

      #The admin password
      [parameter(Mandatory,Position=3)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminPassword,

      #The secure password
      [parameter(Position=4)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword,

      #The FQDN of the Active Directory forest
      [parameter(Position=5)]
      [String]$ForestFqdn,

      #The NetBios name of the Active Directory domain to create
      [parameter(Position=6)]
      [String]$Domain,

      #Credentials for the dcpromo
      [parameter(Position=7)]
      $DomainCredential,

      #The number of DCs to spin up
      [parameter(Position=8)]
      [ValidateRange(1,4)]
      [Single]$SqlCount,

      #IP
      [parameter()]
      [Single]$StartIp
      )


    #Set VM size
    $Size = "Small"
    
    #Obtain sql image to be used
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Obtaining the latest SQL Server 2014 SP1 Standard on Windows Server 2012 R2 image"
        Write-Debug "About to obtain the latest SQL Server 2014 SP1 Standard on Windows Server 2012 R2 image"
    
        #Get the latest Windows Server Remote Desktop Session Host on Windows Server 2012 R2 image
        $Image = (Get-AzureVMImage | 
                  Where-Object {$_.Label -like "SQL Server 2014 SP1 Standard on Windows Server 2012 R2"} | 
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
    
    

    #Create a loop to process each additional SQL needed
    $StartNumber = $(Get-AzureVM | Where-Object {$_.Name -like "*SQL*"} | Measure-Object).Count + 1
    
    for ($i = $StartNumber; $i -le $RdsCount; $i++) {
 

        #Set VM name
        $VMName = "$($CustomerId.ToUpper())-SQL-0$i"
        
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Commissioning SQL - $VMName"
        Write-Debug "About to commission SQL - $VMName"
        
        
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
        f_Create-AzureVM -VMName $VMName -Suffix $Suffix -Location $Location -vNetName $vNetName -VMConfig $VMConfig -AzureDns $AzureDns

        
    }   #End of for ($i = 1; $i -le $SqlCount; $i++)


}   #End of Function f_Create-AzureSQL


##########################################################################################################