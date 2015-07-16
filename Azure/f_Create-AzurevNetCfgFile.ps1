#######################################
## FUNCTION 1 - f_Create-AzurevNetCfgFile
#######################################

#Creates a NetCfg XML file to be consumed by Set-AzureVNetConfig

Function f_Create-AzurevNetCfgFile {

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


}   #End of Function f_Create-AzurevNetCfgFile



##########################################################################################################