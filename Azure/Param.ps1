#Define and validate mandatory parameters
[CmdletBinding()]
Param(
      #AzureCredentialName
	  [String] $AzureCredentialName = "TST-AutomationAccount@managedservicesormer.onmicrosoft.com",

      #AzureCredentialName Password
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String] $password = "AutoMaat2015!",

      #SubsriptionName
      [String] $AzureSubscriptionName = "Azure in Open",

      #Log Location
	  [String] $Log = "D:\Azure\Scripts\Azure.log",

      
      #The data centre location of the build items
      [parameter(Position=2)]
      [ValidateSet("East Asia",`
                   "Southeast Asia",`
                   "North Europe",`
                   "West Europe",`
                   "Central US",`
                   "East US 2",`
                   "East US",`
                   "West US",`
                   "South Central US")]
      [String]$Location = "West Europe",

      #The admin user account 
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminUser = "ormeradmin",

      #The admin user password
      [parameter(Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminPassword = "Welkom2015!"

      )



$CustomerId = $CustomerName.tolower().substring(0,4)
$Suffix = "-67637"
$SuffixStorage = "67637"
$StorageAccountName = $CustomerId + "01storage" + $SuffixStorage
$DNSServerName = $CustomerId.ToUpper() + "-DC-01"
$vNetName = $CustomerId.ToUpper() + "-VNET-01"
$SubnetName = $CustomerId.ToUpper() + "-SUBNET-01"
$ForestFqdn= $Domain + ".local"


Write-Verbose "$(Get-Date -f T) - Customernaam: [$CustomerName]"
Write-Verbose "$(Get-Date -f T) - CustomerID: [$CustomerId]"
Write-Verbose "$(Get-Date -f T) - StorageAccountName: [$StorageAccountName]"
Write-Verbose "$(Get-Date -f T) - DNSServername: [$DNSServername]"
Write-Verbose "$(Get-Date -f T) - vNetname: [$vNetName]"
Write-Verbose "$(Get-Date -f T) - Subnet: [$SubnetName]"
Write-Verbose "$(Get-Date -f T) - SubnetNumber: [10.10.$SubnetNumber.0]"
Write-Verbose "$(Get-Date -f T) - ForestFqdn: $ForestFqdn"

##########################################################################################################