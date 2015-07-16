
###############################
## FUNCTION 3 - f_Create-AzureVM
###############################

#Creates a VM using a supplied VM config

Function f_Create-AzureVM {

Param(
     #The VMName
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName,

      #The VMName
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$Suffix,

      #The data centre location of the build items
      [parameter(Mandatory,Position=3)]
      [ValidateNotNullOrEmpty()]
      [String]$Location,

      #The virtual network name
      [parameter(Mandatory,Position=4)]
      [ValidateNotNullOrEmpty()]
      [String]$vNetName,

      #The virtual machine config
      [parameter(Mandatory,Position=5)]
      [ValidateNotNullOrEmpty()]
      $VMConfig,

      #The Azure DNS object
      [parameter(Mandatory,Position=6)]
      [ValidateNotNullOrEmpty()]
      $AzureDns
      )

#If the creation of the first DC failed stop processing
Switch -Wildcard ($VMName) {

    #Check for the first DC
    "*DC-01" {
        Write-Verbose "$(Get-Date -f T) - NewAzureVM $($VMName+$Suffix)"
        #Create a new VM and new cloud service
        New-AzureVM -ServiceName "$($VMName+$Suffix)" -Location $Location -VNetName $vNetName -VMs $VMConfig -DnsSettings $AzureDns -WaitForBoot | Out-Null

    }  #End of "*DC-01"


    #Check for RDS servers
    "*RDS*" {
        Write-Verbose "$(Get-Date -f T) - NewAzureVM $($VMName+$Suffix)"
        #Create a new VM and don't wait for reboot
        New-AzureVM -ServiceName "$($VMName+$Suffix)" -Location $Location -VNetName $vNetName -VMs $VMConfig | Out-Null

    }   #End of "*MEM*"


    #Check for clients
    "*SQL*" {
        
        #Create a new VM and don't wait for reboot
        New-AzureVM -ServiceName "$($VMName+$Suffix)" -Location $Location -VNetName $vNetName -VMs $VMConfig | Out-Null

    }   #End of "*CLI*"


    Default {
        Write-Verbose "$(Get-Date -f T) - NewAzureVM $VMName$Suffix"
        #Create a new VM and wait for reboot
        New-AzureVM -ServiceName "$($VMName+$Suffix)" -VMs $VMConfig -WaitForBoot | Out-Null

    }   #End of Default


}   #End of Switch ($VMName)       
             
    
    #Error handling
    If (!$?) {

        #Write Error and exit
        Write-Verbose "$(Get-Date -f T) - Something went wrong with the VM creation - we may still be ok though..."

    }   #End of If (!$?) 
    Else {

        #Troubleshooting message
        Write-Verbose "$(Get-Date -f T) - VM created successfully"

    }   #End of Else (!$?)


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Checking $VMName status"
Write-Debug "About to check $VMName status" 

#Get the VM status
$VMService = Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName -ErrorAction SilentlyContinue
    
    #Check we've got status information
    If ($VMService) {

        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - $VMName status verified"


    }   #End of If ($VMService)
    Else {

        #If the creation of the first DC failed stop processing
        If ($VMName -like "*DC-01") {
        
            #Write error and exit
            Write-Error "Failed to obtain staus for first VM - $VMName" -ErrorAction Stop

        }   #End of If ($VMName -like "*DC-01")
        Else {

            #Write error and carry on 
            Write-Error "Failed to obtain status for VM... exiting build function"

        }   #End of Else ($VMName -like "*DC-01")

    }   #End of ($VMService)

}   #End of Function f_Create-AzureVM


##########################################################################################################