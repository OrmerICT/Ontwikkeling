#######################################
## FUNCTION 0 - logon Test Omgeving
#######################################

function f_LogonTest{



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
 ##########################################################################################################