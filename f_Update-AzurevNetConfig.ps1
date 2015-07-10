#######################################
## FUNCTION 2 - f_Update-AzurevNetConfig
#######################################

Function f_Update-AzurevNetConfig {

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

}   #End of Function f_Update-AzurevNetConfig


##########################################################################################################