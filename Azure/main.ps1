#Define and validate mandatory parameters
[CmdletBinding()]
Param(
      #CustomerName
      [parameter(Mandatory=$False)]
      [ValidateNotNullOrEmpty()]
      [String] $ExcelFile = 'D:\Azure\Test Scripts\Azureconfig.xlsx'
)

CLS

#region Init

    #Set strict mode to identify typographical errors
    Set-StrictMode -Version Latest

    #Let's make the script verbose by default
    $VerbosePreference = "Continue"

#endregion

#region Includes
. .\f_LogonTest.ps1
. .\f_Create-AzurevNetCfgFile.ps1
. .\f_Update-AzurevNetConfig.ps1
. .\f_GetImage.ps1
. .\f_CreateVmConfig.ps1
. .\f_CreateVm.ps1
. .\f_CreateSecurePassword.ps1
. .\f_Import-VMWinRmCert.ps1
. .\f_Create-VmPsSession.ps1
. .\f_CreateDcDataDrive.ps1
. .\f_InstallAdService.ps1
. .\f_CreateForest.ps1
. .\f_CloseVmpSession.ps1

#endregion Includes

#region Open Excel

#Check for Excel inputfile
    Write-Verbose "$(Get-Date -f T) - Check if config xlsx exists"

    If (Test-Path $Excelfile){
        Write-Verbose "$(Get-Date -f T) - config xlsx found: $Excelfile"
        }
    Else {
        Write-Verbose "$(Get-Date -f T) - config xlsx not found: $Excelfile"
        Exit
        }

    # Create Excel object
    $objExcel=New-Object -ComObject Excel.Application
    $objExcel.Visible=$false
    $WorkBook=$objExcel.Workbooks.Open($ExcelFile)
    $worksheet = $workbook.sheets.item("AzureConfig")

#endregion 

#region Param

    $AzureCredentialName = "TST-AutomationAccount@managedservicesormer.onmicrosoft.com"
    $password = "AutoMaat2015!"
    $AzureSubscriptionName = "Azure in Open"
    $Log = "D:\Azure\Scripts\Azure.log"
    $Location = "West Europe"
    $AdminUser = "ormeradmin"
    $AdminPassword = "Welkom2015!"
    $SecurePassword = $AdminPassword | ConvertTo-SecureString -AsPlainText -Force
    $CustomerName = $Worksheet.cells.item(3,2).text      # customername
    $Domain = $Worksheet.cells.item(4,2).text             # Domain
    $SubnetNumber = $Worksheet.cells.item(5,2).text       # Subnet

    $CustomerId = $CustomerName.tolower().substring(0,4)
    $Suffix = "-67637"
    $SuffixStorage = "67637"
    $StorageAccountName = $CustomerId + "01storage" + $SuffixStorage
    $DNSServerName = $CustomerId.ToUpper() + "-DC-01"
    $vNetName = $CustomerId.ToUpper() + "-VNET-01"
    $SubnetName = $CustomerId.ToUpper() + "-SUBNET-01"
    $ForestFqdn= $Domain + ".local"

    Write-Verbose "$(Get-Date -f T) - AzureCredentialName: [$AzureCredentialName]"
    Write-Verbose "$(Get-Date -f T) - AzureSubscriptionName: [$AzureSubscriptionName]"
    Write-Verbose "$(Get-Date -f T) - Log: [$Log]"
    Write-Verbose "$(Get-Date -f T) - Location: [$Location]"
    Write-Verbose "$(Get-Date -f T) - Customernaam: [$CustomerName]"
    Write-Verbose "$(Get-Date -f T) - AdminUser: [$AdminUser]"
    Write-Verbose "$(Get-Date -f T) - Domain: [$Domain]"
    Write-Verbose "$(Get-Date -f T) - CustomerID: [$CustomerId]"
    Write-Verbose "$(Get-Date -f T) - StorageAccountName: [$StorageAccountName]"
    Write-Verbose "$(Get-Date -f T) - DNSServername: [$DNSServername]"
    Write-Verbose "$(Get-Date -f T) - vNetname: [$vNetName]"
    Write-Verbose "$(Get-Date -f T) - Subnet: [$SubnetName]"
    Write-Verbose "$(Get-Date -f T) - SubnetNumber: [10.10.$SubnetNumber.0]"
    Write-Verbose "$(Get-Date -f T) - ForestFqdn: $ForestFqdn"

#endregion 

#region Logon

    Write-Verbose "$(Get-Date -f T) - Logon Azure"

    If ($Worksheet.cells.item(1,2).text -eq "Test") {
        f_LogonTest
        }
    Else{
        f_LogonProd
        }

    Write-Verbose "$(Get-Date -f T) - Checking Azure connectivity"

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

#endregion

#region Storage

    Write-Verbose "$(Get-Date -f T) - Checking $($StorageAccountName) storage account"
    $CreateVnet = $False

    $CheckStorage = Get-AzureStorageAccount | Where-Object Label -like "$StorageAccountName"
    if (!$CheckStorage) {
        Write-Verbose "$(Get-Date -f T) - $($StorageAccountName) storage account not found, creating"
        #Use the New-AzureStorageAccountName cmdlet to set-up a new storage account
        New-AzureStorageAccount -StorageAccountName $storageAccountName -Location $Location -Description "Storage for [$CustomerName]" -ErrorAction SilentlyContinue | Out-Null

        #Error handling
        If (!$?) {
            Write Error and exit
            Write-Error "Unable to create storage account - $StorageAccountName" -ErrorAction Stop
            }   #End of If (!$?) 
        Else {
            Write-Verbose "$(Get-Date -f T) - $StorageAccountName storage account successfully created"
            $CreateVnet = $true
            }   #End of Else (!$?)
        }
    else {
        Write-Verbose "$(Get-Date -f T) - Referencing the storage account"
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
    }

#endregion Storage

#region Create NetCfg File

    if ($CreateVnet) {
        #Variable for NetCfg file
        $SourceParent = (Get-Location).Path
        $NetCfgFile = "$SourceParent\$($CustomerId)_vNet.netcfg"

        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Creating vNet config file"
        Write-Debug "About to create the vNet config file"

        #Use the f_Create-AzurevNetCfgFile function to create the NetCfg XML file used to seed the new Azure virtual network
        f_Create-AzurevNetCfgFile -DNSServername $DNSServername -Location $Location -NetCfgFile $NetCfgFile -SubnetNumber $Subnetnumber -SubnetName $Subnetname
        }
    else {
        Write-Verbose "$(Get-Date -f T) - vnet: no config file created, storage found!"
        }

#endregion Create NetCfg File

#region Create Virtual Network

    if ($CreateVnet) {
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Creating Azure DNS object"
        Write-Debug "About to create Azure DNS object"

        #First, create an object representing the DNS server for this vNet (this is used with the -DnsSettings parameter of New-AZureVM)
        $AzureDns = New-AzureDns -IPAddress "10.10.$($SubnetNumber).20" -Name "$DNSServerName" -ErrorAction SilentlyContinue 

        #Error handling
        If ($AzureDns) {
            Write-Verbose "$(Get-Date -f T) - DNS object successfully created"
            }   #End of If ($AzureDns) 
        Else {
            #Write Error and exit
            Write-Error "Unable to create DNS object" -ErrorAction Stop
            }   #End of Else ($AzureDns)

        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Checking for existing vNet config"
        Write-Debug "About to check for existing vNet config"

        #Call f_Update-AzurevNetConfig function to create or update the VNet configuration
        f_Update-AzurevNetConfig -vNetName $vNetName -NetCfgFile $NetCfgFile
        }
    else {
        Write-Verbose "$(Get-Date -f T) - VNET: no vNet created, storage found!"
        }

#endregion Create Virtual Network

#region Loop create

$i = 8 

Do { 

    $ServerType =  $Worksheet.cells.item($i,1).text 
    $ServerCount =  $Worksheet.cells.item($i,2).text 
    $ServerFunction =  $Worksheet.cells.item($i,3).text 
    $ServerInDomain =  $Worksheet.cells.item($i,4).text 
    $DCDataDisk =  $Worksheet.cells.item($i,5).text
    $InstanceSize =  $Worksheet.cells.item($i,6).text 

    Write-Verbose "$(Get-Date -f T) - ServerType: $ServerType, ServerCount: $ServerCount, ServerFunction: $ServerFunction, ServerInDomain: $ServerInDomain, InstanceInstanceSize: $InstanceSize, AdditionalDataDisk: $AdditionalDataDisk"          

    Switch ($Servertype) {
        "DC-01" {
        If ($ServerCount -gt 0) {
        $VMName = "$DNSServerName"
            $Image = f_GetImage -OsName "Windows Server 2012 R2 Datacenter*"
            $VMConfig = f_CreateVmConfig -VMName $VMName -InstanceSize $InstanceSize -Image $Image -AdminUser $AdminUser -AdminPassword $AdminPassword -DCDataDisk $DCDataDisk -DNSServerName $DNSServerName -SubnetNumber $SubnetNumber
            f_CreateVm -VMName $VMName -Suffix $Suffix -Location $Location -vNetName $vNetName -VMConfig $VMConfig -AzureDns $AzureDns
            f_CreateSecurePassword -AdminPassword $AdminPassword
            f_Import-VMWinRmCert -VMName $VMName -Suffix $Suffix
            $VMSession = f_Create-VmPsSession -VMName $VMName -AdminUser $AdminUser -SecurePassword $SecurePassword -Suffix $Suffix
            f_CreateDcDataDrive -VMSession $DCSession
            f_InstallAdService -VMName $VMName -DCSession $DCSession
            f_CreateForest -ForestFqdn $ForestFqdn -Domain $Domain -SecurePassword $SecurePassword
#            f_CreateDataDisk
            f_CloseVmpSession -VMName $VMName
        } # End if ServerCount

        } # End DC-01













                        } #End switch

                        $i++ 
    } 
While ($Worksheet.cells.item($i,2).text -ne "") 
#endregion Loop create

#endregion Loop create