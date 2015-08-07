Function Update-AzurevNetConfig {

Param(
      #The VirtualnetworkName
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$vNetName,

      #The netcfg file path
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$NetCfgFile
)

    #Attempt to retrive vNet config
    $vNetConfig = Get-AzureVNetConfig

    #If we don't have an existing virtual network use the netcfg file to create a new one
    If (!$vNetConfig) {
    
        #Write the fact that we don't have a vNet config file to screen
        Write-Verbose "$(Get-Date -f T) - Existing Azure vNet configuration not found"
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Creating $vNetName virtual network from $NetCfgFile"
        Write-Debug "About to create $vNetName virtual network from $NetCfgFile"
    
        #Create a new virtual network from the config file
        Set-AzureVNetConfig -ConfigurationPath $NetCfgFile -ErrorAction SilentlyContinue | Out-Null
    
            #Error handling
            If (!$?) {
    
                #Write Error and exit
                Write-Error "Unable to create $vNetName virtual network" -ErrorAction Stop
    
            }   #End of If (!$?) 
            Else {
    
                #Troubleshooting message
                Write-Verbose "$(Get-Date -f T) - $vNetName virtual network successfully created"
    
            }   #End of Else (!$?)
    
    }   #End of If (!$vNetConfig)
    
    #If we find a virtual network configuration update the existing one
    Else {
    
        #Write confirmation of existing vNet config to screen
        Write-Verbose "$(Get-Date -f T) - Existing Azure vNet configuration found"
    
        #Set the vNetConfig update flag to false (this determines if changes are committed later)
        $UpdatevNetConfig = $False
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Backing up existing vNetConfig to $($NetCfgFile).backup"
        Write-Debug "About to backup up existing vNetConfig to $($NetCfgFile).backup"
    
        #Backup the existing vNet configuration
        Set-Content -Value $vNetConfig.XMLConfiguration -Path "$($NetCfgFile).backup" -Force
    
            #Error handling
            If (!$?) {
    
                #Write Error and exit
                Write-Error "Unable to backup existing vNetConfig" -ErrorAction Stop
    
            }   #End of If (!$?) 
            Else {
    
                #Troubleshooting message
                Write-Verbose "$(Get-Date -f T) - vNetConfig backed up to $($NetCfgFile).backup"
    
            }   #End of Else (!$?)
    
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Reading contents of $NetCfgFile"
        Write-Debug "About to read contents of $NetCfgFile"
    
        #Convert previously created NetCfgFile to XML
        [XML]$NetCfg = Get-Content -Path $NetCfgFile
    
            #Error handling
            If (!$?) {
    
                #Write Error and exit
                Write-Error "Unable to convert $NetCfgFile to XML object" -ErrorAction Stop
    
            }   #End of If (!$?) 
            Else {
    
                #Troubleshooting message
                Write-Verbose "$(Get-Date -f T) - $NetCfgFile successfully converted to XML object"
    
            }   #End of Else (!$?)
    
            
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Converting existing vNetConfig object to XML"
        Write-Debug "About to convert existing vNetConfig object to XML"
    
        #Convert vNetConfig (VirtualNetworkConfigContext object) to XML
        $vNetConfig = [XML]$vNetConfig.XMLConfiguration
    
            #Error handling
            If (!$?) {
    
                #Write Error and exit
                Write-Error "Unable to convert vNetConfig object to XML object" -ErrorAction Stop
    
            }   #End of If (!$?) 
            Else {
    
                #Troubleshooting message
                Write-Verbose "$(Get-Date -f T) - vNetConfig object successfully converted to XML object"
    
            }   #End of Else (!$?)
    
        
        ###Check for existence of DNS entry
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Checking for Dns node"
        Write-Debug "About to check for Dns node"
    
        #Get the Dns child of the VirtualNetworkConfiguration Node
        $DnsNode = $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.ChildNodes | Where-Object {$_.Name -eq "Dns"}
    
        #Check if the Dns node was found
        If ($DnsNode) {
    
            #Update comment
            Write-Verbose "$(Get-Date -f T) - Dns node found"
    
            #Now check for whether Dns node is empty
            If ($DnsNode.HasChildNodes -eq $False) {
    
                #Write that no existing DNS servers were found to screen
                Write-Verbose "$(Get-Date -f T) - No existing DNS servers found"
    
                #Troubleshooting messages
                Write-Verbose "$(Get-Date -f T) - Adding DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
                Write-Debug "About to add DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
    
                #Create a template for the DNS node
                $DnsEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.Dns, $True)
                
                #Import the newly created template
                $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.ReplaceChild($DnsEntry, $DnsNode) | Out-Null
    
                    #Error handling
                    If (!$?) {
    
                        #Write Error and exit
                        Write-Error "Unable to replace DNS server node" -ErrorAction Stop
    
                    }   #End of If (!$?) 
                    Else {
    
                        #Troubleshooting message
                        Write-Verbose "$(Get-Date -f T) - DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) - added to in-memory network configuration"

                        #Set the vNetConfig update flag to true so we know we have changes to commit later
                        $UpdatevNetConfig = $True
    
                    }   #End of Else (!$?)
    
            }   #End of If ($DnsNode.HasChildNodes -eq $False)
            Else {
    
                #Write that we have found child nodes
                Write-Verbose "$(Get-Date -f T) - DNS node has child nodes"

                #Troubleshooting messages
                Write-Verbose "$(Get-Date -f T) - Checking for Dns servers in child nodes"
                Write-Debug "About to check for Dns servers in child nodes"

                #Check that DnsServers exists
                If (($DnsNode.FirstChild).Name -eq "DnsServers") {

                    #Now, check whether we have any DNS entries
                    If ($DnsNode.DnsServers.HasChildNodes) {

                        #Write confirmation of existing DNS servers to screen
                        Write-Verbose "$(Get-Date -f T) - Existing DNS servers found"

                        #Get a list of currently configured DNS servers
                        $DnsServers = $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.DnsServer

                        #Troubleshooting messages
                        Write-Verbose "$(Get-Date -f T) - Checking for DNS server conflicts"
                        Write-Debug "About to check for DNS server conflicts"

                        #Set $DnsAction as "Update"
                        $DnsAction = "Update"

                        #Loop through the DNS server entries
                        $DnsServers | ForEach-Object {

                            #See if we have the DNS server or IP address already in use
                            If (($_.Name -eq "$DNSServerName") -and ($_.IPAddress -eq "10.10.$($SubnetNumber).20")) {
                                
                                #Set a flag for a later action
                                $DnsAction = "NoFurther"

                            }   #End of If (($_.Name -eq "$DNSServerName") -and $_.IPAddress -eq "10.10.$($SubnetNumber).20")

                            ElseIf (($_.Name -eq "$DNSServerName") -xor ($_.IPAddress -eq "10.10.$($SubnetNumber).20")) {

                                #Set a flag for a later action
                                $DnsAction = "PotentialConflict"

                            }   #End of ElseIf (($_.Name -eq "$DNSServerName") -xor ($_.IPAddress -eq "10.10.$($SubnetNumber).20"))
                

                        }   #End of ForEach-Object

                        #Perform appropriate action after looping through all DNS entries
                        Switch ($DnsAction) {

                            "NoFurther" {
                        
                                #Write confirmation that our DNS server already exists
                                Write-Verbose "$(Get-Date -f T) - $DNSServerName (10.10.$($SubnetNumber).20) already exists - no further action required"
                        
                            }   #End of "NoFurther"


                            "PotentialConflict" {

                                #Write confirmation that one element of our DNS server's setting already exist
                                Write-Error "There is a name or IP conflict with an existing DNS server - please investigate" -ErrorAction Stop
                        
                            }   #End of "PotentialConflict"

                            Default {
 
                                ##As the first two conditions aren't met, it must be safe to update the node
                                #Troubleshooting messages
                                Write-Verbose "$(Get-Date -f T) - No conflicts found"
                                Write-Verbose "$(Get-Date -f T) - Adding DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
                                Write-Debug "About to add DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"

                                #Create a template for an entry to the DNSservers node
                                $DnsServerEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.DnsServer, $True)

                                #Add the template to out copy of the vNetConfig in memory
                                $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.Dns.DnsServers.AppendChild($DnsServerEntry) | Out-Null

                                    #Error handling
                                    If (!$?) {

                                        #Write Error and exit
                                        Write-Error "Unable to append DNS server" -ErrorAction Stop

                                    }   #End of If (!$?) 
                                    Else {

                                        #Troubleshooting message
                                        Write-Verbose "$(Get-Date -f T) - DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) - added to in-memory network configuration"

                                        #Set the vNetConfig update flag to true so we know we have changes to commit later
                                        $UpdatevNetConfig = $True

                                    }   #End of Else (!$?)                      
                        
                            }   #End of Default
                                              
                        }   #End of Switch ($DnsAction)

                    }   #End of If ($DnsNode.DnsServers.HasChildNodes)
                    Else {

                        #Write that no existing DNS servers were found to screen
                        Write-Verbose "$(Get-Date -f T) - No existing DNS server entries found in child nodes"
    
                        #Troubleshooting messages
                        Write-Verbose "$(Get-Date -f T) - Adding DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
                        Write-Debug "About to add DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
    
                        #Create a template for the DNS node
                        $DnsEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.Dns, $True)
                
                        #Import the newly created template
                        $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.ReplaceChild($DnsEntry, $DnsNode) | Out-Null
    
                            #Error handling
                            If (!$?) {
    
                                #Write Error and exit
                                Write-Error "Unable to replace DNS server node" -ErrorAction Stop
    
                            }   #End of If (!$?) 
                            Else {
    
                                #Troubleshooting message
                                Write-Verbose "$(Get-Date -f T) - DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) - added to in-memory network configuration"
                                
                                #Set the vNetConfig update flag to true so we know we have changes to commit later
                                $UpdatevNetConfig = $True

                            }   #End of Else (!$?)

                    }   #End of Else ($DnsNode.DnsServers.HasChildNodes)


                }   #End of If (($DnsNode.FirstChild).Name -eq "DnsServers")
                Else {

                    #Write that no existing DNS servers were found to screen
                    Write-Verbose "$(Get-Date -f T) - No existing DNS server entries found in child nodes"
    
                    #Troubleshooting messages
                    Write-Verbose "$(Get-Date -f T) - Adding DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
                    Write-Debug "About to add DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
    
                    #Create a template for the DNS node
                    $DnsEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.Dns, $True)
                    
                    #Import the newly created template
                    $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.ReplaceChild($DnsEntry, $DnsNode) | Out-Null
    
                        #Error handling
                        If (!$?) {
    
                            #Write Error and exit
                            Write-Error "Unable to replace DNS server node" -ErrorAction Stop
    
                        }   #End of If (!$?) 
                        Else {
    
                            #Troubleshooting message
                            Write-Verbose "$(Get-Date -f T) - DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) - added to in-memory network configuration"

                            #Set the vNetConfig update flag to true so we know we have changes to commit later
                            $UpdatevNetConfig = $True
    
                        }   #End of Else (!$?)

                }   #End of Else (($DnsNode.FirstChild).Name -eq "DnsServers")
    
    
            }   #End of Else ($DnsNode.HasChildNodes -eq $False)
    
    
        }   #End of If ($DnsNode.Name -eq "Dns")
        Else {
    
            #Write that Dns node not found to screen
            Write-Verbose "$(Get-Date -f T) - Dns node not found"
    
            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Adding DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
            Write-Debug "About to add DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) to network configuration"
    
            #Create a template for the DNS node
            $DnsEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.Dns, $True)
            
            #Import the newly created template
            $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.AppendChild($DnsEntry) | Out-Null
    
                #Error handling
                If (!$?) {
    
                    #Write Error and exit
                    Write-Error "Unable to  DNS server node" -ErrorAction Stop
    
                }   #End of If (!$?) 
                Else {
    
                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - DNS Server - $DNSServerName (10.10.$($SubnetNumber).20) - added to in-memory network configuration"

                    #Set the vNetConfig update flag to true so we know we have changes to commit later
                    $UpdatevNetConfig = $True
    
                }   #End of Else (!$?)
    
        }   #End of Else ($DnsNode)
    
        ###Check for existence of our virtual network 
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Checking for VirtualNetworkSites node"
        Write-Debug "About to check for VirtualNetworkSites node"
    
        #Get the VirtualNetworkSites child of the VirtualNetworkConfiguration Node
        $SitesNode = $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.ChildNodes | Where-Object {$_.Name -eq "VirtualNetworkSites"}
    
        #Check if the VirtualNetworkSites node was found
        If ($SitesNode) {
    
            #Update comment
            Write-Verbose "$(Get-Date -f T) - VirtualNetworkSites node found"
    
            #Now check for whether VirtualNetworkSites node is empty
            If ($SitesNode.HasChildNodes -eq $False) {
    
                #Write that no existing DNS servers were found to screen
                Write-Verbose "$(Get-Date -f T) - No existing virtual network sites found"
    
                #Troubleshooting messages
                Write-Verbose "$(Get-Date -f T) - Adding virtual network site - $vNetName"
                Write-Debug "About to add virtual network site - $vNetName - to network configuration"
    
                #Create a template for the VirtualNetworkSites node
                $SitesEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites, $True)
                
                #Import the newly created template
                $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.ReplaceChild($SitesEntry, $SitesNode) | Out-Null
    
                    #Error handling
                    If (!$?) {
    
                        #Write Error and exit
                        Write-Error "Unable to replace VirtualNetworkSites node" -ErrorAction Stop
    
                    }   #End of If (!$?) 
                    Else {
    
                        #Troubleshooting message
                        Write-Verbose "$(Get-Date -f T) - VirtualNetworkSite - $vNetName - added to in-memory network configuration"

                        #Set the vNetConfig update flag to true so we know we have changes to commit later
                        $UpdatevNetConfig = $True
    
                    }   #End of Else (!$?)
                    
            }   #End of If ($SitesNode.HasChildNodes -eq $False)
            Else {
    
                #Write that we have found child nodes
                Write-Verbose "$(Get-Date -f T) - VirtualNetworkSites node has child nodes"

                #Troubleshooting messages
                Write-Verbose "$(Get-Date -f T) - Checking for $vNetName in child nodes"
                Write-Debug "About to check for $vNetName in child nodes"

                #Get a list of currently configured virtual network sites
                $vNetSites = $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite

                #Troubleshooting messages
                Write-Verbose "$(Get-Date -f T) - Checking for virtual network site conflict"
                Write-Debug "About to check for virtual network site conflict"

                #Loop through the DNS server entries
                $vNetSites | ForEach-Object {

                    #See if we have the vNetSite name already in use
                    If ($_.Name -eq $vNetName) {
                        
                        #Write confirmation that our virtual network site already exists
                        Write-Error "$vNetName already exists - please investigate" -ErrorAction Stop

                    }   #End of If ($_.Name -eq $vNetName)

                }   #End of ForEach-Object


                #Troubleshooting messages
                Write-Verbose "$(Get-Date -f T) - No conflicts found"
                Write-Verbose "$(Get-Date -f T) - Adding virtual network site - $vNetName"
                Write-Debug "About to add virtual network site - $vNetName - to network configuration"

                #Create a template for an entry to the DNSservers node
                $vNetSiteEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.VirtualNetworkSite, $True)

                #Add the template to out copy of the vNetConfig in memory
                $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites.AppendChild($vNetSiteEntry) | Out-Null

                    #Error handling
                    If (!$?) {

                        #Write Error and exit
                        Write-Error "$(Get-Date -f T) - Unable to append virtual network site - $vNetName" -ErrorAction Stop

                    }   #End of If (!$?) 
                    Else {

                        #Troubleshooting message
                        Write-Verbose "$(Get-Date -f T) - Virtual network site - $vNetName - added to in-memory network configuration"

                        #Set the vNetConfig update flag to true so we know we have changes to commit later
                        $UpdatevNetConfig = $True

                    }   #End of Else (!$?)

            }   #End of Else ($SitesNode.HasChildNodes -eq $False)
    
        }   #End of If ($SitesNode)
        Else {
    
            #Write that VirtualNetworkSites node not found to screen
            Write-Verbose "$(Get-Date -f T) - VirtualNetworkSites node not found"
    
            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Adding virtual network site - $vNetName"
            Write-Debug "About to add virtual network site - $vNetName - to network configuration"
    
            #Create a template for the VirtualNetworkSites node
            $SitesEntry = $vNetConfig.ImportNode($NetCfg.NetworkConfiguration.VirtualNetworkConfiguration.VirtualNetworkSites, $True)
            
            #Import the newly created template
            $vNetConfig.NetworkConfiguration.VirtualNetworkConfiguration.AppendChild($SitesEntry) | Out-Null
    
                #Error handling
                If (!$?) {
    
                    #Write Error and exit
                    Write-Error "Unable to add VirtualNetworkSites to VirtualNetworkConfiguration node" -ErrorAction Stop
    
                }   #End of If (!$?) 
                Else {
    
                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - VirtualNetworkSite - $vNetName - added to in-memory network configuration"

                    #Set the vNetConfig update flag to true so we know we have changes to commit later
                    $UpdatevNetConfig = $True
    
                }   #End of Else (!$?)
    
        }   #End of Else ($SitesNode)
    
        #Check whether we have any configuration to update
        If ($UpdatevNetConfig) {

            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Exporting updated in-memory configuration to $NetCfgFile"
            Write-Debug "About to export updated in-memory configuration to $NetCfgFile"

            #Copy the in-memory config back to a file
            Set-Content -Value $vNetConfig.InnerXml -Path $NetCfgFile

                #Error handling
                If (!$?) {
    
                    #Write Error and exit
                    Write-Error "Unable to export updated vNet configuration to $NetCfgFile" -ErrorAction Stop
    
                }   #End of If (!$?) 
                Else {
    
                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - Exported updated vNet configuration to $NetCfgFile"
    
                }   #End of Else (!$?)


            #Troubleshooting messages
            Write-Verbose "$(Get-Date -f T) - Creating $vNetName virtual network from updated config file"
            Write-Debug "About to create $vNetName virtual network from updated config file"
    
            #Create a new virtual network from the config file
            Set-AzureVNetConfig -ConfigurationPath $NetCfgFile -ErrorAction SilentlyContinue | Out-Null
    
                #Error handling
                If (!$?) {
    
                    #Write Error and exit
                    Write-Error "Unable to create $vNetName virtual network" -ErrorAction Stop
    
                }   #End of If (!$?) 
                Else {
    
                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - $vNetName virtual network successfully created"
    
                }   #End of Else (!$?)


        }   #End of If ($UpdatevNetConfig)
        Else {

            #Troubleshooting message
            Write-Verbose "$(Get-Date -f T) - vNet config does not need updating"


        }   #End of Else ($UpdatevNetConfig)
    
    }   #End of Else (!$vNetConfig)

}

Export-ModuleMember -Function 'Update-AzurevNetConfig'

Function Test-AzureLogon {
    #
    # Check if Windows Azure Powershell is avaiable
    #
    if ((Get-Module -ListAvailable Azure) -eq $null)
    {
    throw "Windows Azure Powershell not found! Please install from http://www.windowsazure.com/en-us/downloads/#cmd-line-tools"
    }

    #
    # Add Azure Account
    #
    $secstr = New-Object -TypeName System.Security.SecureString
    $password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $AzureCredentialName, $secstr
    Add-AzureAccount -Credential $cred -ErrorAction SilentlyContinue
        
    if ((Get-AzureAccount -Name $AzureCredentialName) -eq $Null){
        throw "PROGRAMM ERROR: logon failed"
        }
    else{
        Write-Verbose "$(Get-Date -f T) - logon OK"
        }
    #
    # Azure login -u TST-AutomationAccount@managedservicesormer.onmicrosoft.com -p $password
    #    
    $subscription = Get-AzureSubscription -Name $AzureSubscriptionName
    if($subscription -eq $null)
        {
            Write-Error "$(Get-Date -f T) - No subscription found with name [$AzureSubscriptionName] that is accessible to user [$($azureCredentialName)]" -ErrorAction Stop
        }
    else{
        Write-Verbose "$(Get-Date -f T) - Subscription command OK" | Out-File $Log -Append
        }
    
    #
	# Select the Azure subscription we will be working against
    #
    $subscriptionResult = Select-AzureSubscription -SubscriptionName $AzureSubscriptionName

    $GetAzureSubscription = Get-AzureSubscription
    
    Write-Verbose "$(Get-Date -f T) - Subscription: [$($GetAzureSubscription.SubscriptionName)]"
  
    $subscriptionResult = Set-AzureSubscription -SubscriptionName $AzureSubscriptionName -CurrentStorageAccountName $StorageAccountName
  
  }

Export-ModuleMember -Function 'Test-AzureLogon'

Function Install-AzureADService {

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
}

Export-ModuleMember -Function 'Install-AzureADService'

Function Import-AzureVMWinRmCert {

Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName,

      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$Suffix
      )

Write-Verbose "$(Get-Date -f T) - Configuring certificate for PS Remoting access on $VMName$Suffix"


#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Obtaining thumbprint of WinRM cert for $VMName"

#Get the thumbprint of the VM's WinRM cert
$WinRMCert = (Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName).VM.DefaultWinRMCertificateThumbprint

    If ($WinRMCert) {
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Saving $VMName$Suffix Azure certificate data to cer file"

        #Get a certificare object for the VM's service and save it's data to a .cer file
        (Get-AzureCertificate -ServiceName "$VMName$Suffix" -Thumbprint $WinRMCert -ThumbprintAlgorithm sha1).Data | 
        Out-File $SourceParent\"$VMName$Suffix.cer"

            #Error handling
            If ($?) {

                #Troubleshooting message
                Write-Verbose "$(Get-Date -f T) - $VMName$Suffix Azure certificate exported to cer file"
                Write-Verbose "$(Get-Date -f T) - Importing $VMName$Suffix Azure certificate to Cert:\localmachine\root"

                #Import the certifcate into the local computer's root store
                Import-Certificate -FilePath "$SourceParent\$VMName$Suffix.cer" -CertStoreLocation "Cert:\localmachine\root" -ErrorAction SilentlyContinue |
                Out-Null

                #Error handling
                If ($?) {

                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - $VMName$Suffix Azure certificate imported to local computer root store"


                }   #End of If ($?)
                Else {

                    #Write Error
                    Write-Error "Unable to import certificate to local computer root store - script remoting won't be possible for $VMName$Suffix"

                }   #End of 

            }   #End of If (!$?) 
            Else {

                #Write Error
                Write-Error "Unable to export certificate to cer file - script remoting won't be possible for $VMName$Suffix"

            }   #End of Else (!$?)


    }   #End of If ($WinRMCert)
    Else {

        #Write Error
        Write-Error "Unable to obtain WinRM certificate thumbprint - script remoting won't be possible for $VMName$Suffix"

    }   #Else($WinRMCert)


}

Export-ModuleMember -Function 'Import-AzureVMWinRmCert'

function Get-AzureImage {
    Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$OsName
    )
    $Image = (Get-AzureVMImage | Where-Object {$_.Label -like $OsName} | Sort-Object PublishedDate -Descending)[0].ImageName
    #Error handling
    if ($Image) {
            #Write details of current subscription to screen
            Write-Verbose "$(Get-Date -f T) - Image found - $($Image)"
        }   #End of If ($Image)
        else {
            #Write Error and exit
            Write-Error "Unable to obtain valid OS image " -ErrorAction Stop
        }   #End of Else ($Image)
    return $Image
}

Export-ModuleMember -Function 'Get-AzureImage'

Function Create-AzureVmPsSession {
    Param(
      #The virtual machine name
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName,

      #The admin user account 
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminUser,

      #The admin user password
      [parameter(Mandatory,Position=3)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword,

      #The admin user password
      [parameter(Mandatory,Position=4)]
      [ValidateNotNullOrEmpty()]
      $Suffix
    )
    Write-Verbose "$(Get-Date -f T) - Creating PS Remoting session on $VMName"
    #Get the WinRM URI of the host
    $WinRmUri = Get-AzureWinRMUri -ServiceName "$VMName$Suffix" -Name $VMName

    #Error handling
    If ($WinRmUri) {
        #Write details of current subscription to screen
        Write-Verbose "$(Get-Date -f T) - WINRM connection URI obtained"
        #Create a credential object to pass to New-PSSession
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AdminUser,$SecurePassword
            #Error handling
            If ($Credential) {
                #Write credential object confirmation to screen
                Write-Verbose "$(Get-Date -f T) - Credential object created"

                #Create a new remote PS Session to pass commands to
                $VMSession = New-PSSession -ConnectionUri $WinRmUri.AbsoluteUri -Credential $Credential

                    #Error handling
                    If ($VMSession) {

                        #Write remote PS session confirmation to screen
                        Write-Verbose "$(Get-Date -f T) - Remote PS session established"
                        Return $VMSession
                    }   #End of If ($VMSession)
                    Else {
                        #Write Error and exit
                        Write-Error "Unable to create remote PS session" 
                    }   #End of Else ($VMSession)
            }   #End of If ($Credential)
            Else {
                #Write Error and exit
                Write-Error "Unable to create credential object" 
            }   #End of Else ($Credential)
    }   #End of If ($WinRmUri)
    Else {
        #Write Error and exit
        Write-Error "Unable to obtain a valid WinRM URI" 
    }   #End of Else ($WinRmUri)
    return $VMSession
}

Export-ModuleMember -Function 'Create-AzureVmPsSession'

function Create-AzureVmConfig {
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
}

Export-ModuleMember -Function 'Create-AzureVmConfig'

Function Create-AzureVM {

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

}

Export-ModuleMember -Function 'Create-AzureVM'

Function New-SecurePassword {
    Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminPassword
    )
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
    return $SecurePassword
}

Export-ModuleMember -Function 'New-SecurePassword'

Function Create-ADForest {

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
}

Export-ModuleMember -Function 'Create-ADForest'

Function Create-DCDataDrive {
    Param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        $VMSession
    )
    Write-Verbose "$(Get-Date -f T) - Configure additional data drive on $VMName"
    #We've added an additional disk to store AD's DB, logs and SYSVOl - time to initialize, partition and format the drive
    $ConfigureDisk = Invoke-Command -Session $VMSession -ScriptBlock {Get-Disk | Where-Object {$_.PartitionStyle -eq "RAW"} | 
                                                                  Initialize-Disk -PartitionStyle MBR -PassThru |
                                                                  New-Partition -UseMaximumSize -DriveLetter Z | 
                                                                  Format-Volume -FileSystem NTFS -Force -Confirm:$False}
    #Error handling
    If ($ConfigureDisk) {
        #Write remote PS session confirmation to screen
        Write-Verbose "$(Get-Date -f T) - Additional data disk successfully configured"
    }   #End of If ($VMSession)
    Else {
        #Write Error and exit
        Write-Error "Unable to configure additional data disk" 
    }   #End of Else ($VMSession)
}

Export-ModuleMember -Function 'Create-DCDataDrive'

Function Create-AzurevNetCfgFile {
    Param(
      #The DNS ServerName
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$DNSServerName,
      #The data centre location of the build items
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$Location,
      #The netcfg file path
      [parameter(Mandatory,Position=3)]
      [ValidateNotNullOrEmpty()]
      [String]$NetCfgFile,
      #The netcfg file path
      [parameter(Mandatory,Position=4)]
      [ValidateNotNullOrEmpty()]
      [String]$SubnetNumber,
      #The netcfg file path
      [parameter(Mandatory,Position=5)]
      [ValidateNotNullOrEmpty()]
      [String]$SubnetName
      )

#Define a here-string for our NetCfg xml structure
$NetCfg = @"
<?xml version="1.0" encoding="utf-8"?>
<NetworkConfiguration xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/ServiceHosting/2011/07/NetworkConfiguration">
  <VirtualNetworkConfiguration>
    <Dns>
      <DnsServers>
        <DnsServer name="$DNSServerName" IPAddress="10.10.$($SubnetNumber).20" />
      </DnsServers>
    </Dns>
    <VirtualNetworkSites>
      <VirtualNetworkSite name="$vNetName" Location="$($Location)">
        <AddressSpace>
          <AddressPrefix>10.10.$($SubnetNumber).0/24</AddressPrefix>
        </AddressSpace>
        <Subnets>
          <Subnet name="$SubnetName">
            <AddressPrefix>10.10.$($SubnetNumber).0/25</AddressPrefix>
          </Subnet>
          <Subnet name="Gateway">
            <AddressPrefix>10.10.$($SubnetNumber).248/29</AddressPrefix>
          </Subnet>
        </Subnets>
        <DnsServersRef>
          <DnsServerRef name="$DNSServerName" />
        </DnsServersRef>
      </VirtualNetworkSite>
    </VirtualNetworkSites>
  </VirtualNetworkConfiguration>
</NetworkConfiguration>
"@
    #Update the NetCfg file with parameter values
    Set-Content -Value $NetCfg -Path $NetCfgFile
    #Error handling
    If (!$?) {
        #Write Error and exit
        Write-Error "Unable to create $NetCfgFile with custom vNet settings" -ErrorAction Stop
    }   #End of If (!$?)
    Else {
        #Troubleshooting message
        Write-Verbose "$(Get-Date -f T) - $($NetCfgFile) successfully created"
    }   #End of Else (!$?)
}

Export-ModuleMember -Function 'Create-AzurevNetCfgFile'

function Close-VmPsSession {
Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName
      )
      
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
}

Export-ModuleMember -Function 'Close-VmPsSession'