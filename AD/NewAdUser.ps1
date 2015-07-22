Param
(
	[Parameter(Mandatory=$true)]
	[String] $GivenName,
	
	[Parameter(Mandatory=$true)]
	[String] $Initials,
	
	[Parameter(Mandatory=$true)]
	[String] $SurName,
	
	[Parameter(Mandatory=$true)]
	[String] $Mail,
	
	[Parameter(Mandatory=$true)]
	[String] $UserName,
	
	[Parameter(Mandatory=$true)]
	[String] $PassWord,
	
	[Parameter(Mandatory=$true)]
	[String] $CopyUser,

	[Parameter(Mandatory=$false)]
	[String] $Domain = $env:USERDOMAIN,

	[Parameter(Mandatory=$false)]
	[String] $Title = "Create New AD User",

	[Parameter(Mandatory=$false)]
	[String] $LogName = "NewAdUser.log",

	[Parameter(Mandatory=$false)]
	[String] $Log = "C:\kworking" + "\" + $LogName
)

$Time = (Get-Date -UFormat "%d-%m-%Y %T")
Write-Host "[$Time] [Start] $Title"
"[$Time] [Start] $Title" | Out-File $Log -Append

Write-Host "[ ]"
"[ ]" | Out-File $Log -Append

Write-Host "[ ] Importing module ServerManager"
"[ ] Importing module ServerManager" | Out-File $Log -Append
Import-module servermanager
Write-Host "[OK] Module ServerManager" -ForegroundColor Green
"[OK] Module ServerManager" | Out-File $Log -Append

Write-Host "[ ] Searching for RSAT-AD-PowerShell"
"[ ] Searching for RSAT-AD-PowerShell" | Out-File $Log -Append
$RSAT = (Get-WindowsFeature -name RSAT-AD-PowerShell).Installed
If ($RSAT -eq $false)
{
Write-Host "[ERROR] RSAT-AD-PowerShell not found" -ForegroundColor Red
"[ERROR] RSAT-AD-PowerShell not found" | Out-File $Log -Append

Write-Host "[ ] Add Windows Feature RSAT-AD-PowerShell"
"[ ] Add Windows Feature RSAT-AD-PowerShell" | Out-File $Log -Append
Add-WindowsFeature RSAT-AD-PowerShell
Write-Host "[OK ] Add Windows Feature RSAT-AD-PowerShell" -ForegroundColor Green
"[OK] Add Windows Feature RSAT-AD-PowerShell" | Out-File $Log -Append

Write-Host "[ ] Import module ActiveDirectory"
"[ ] Import module ActiveDirectory" | Out-File $Log -Append
Import-module ActiveDirectory
Write-Host "[OK] Module ActiveDirectory" -ForegroundColor Green
"[OK] Module ActiveDirectory" | Out-File $Log -Append
}
Else
{
Write-Host "[OK] RSAT-AD-PowerShell" -ForegroundColor Green
"[OK] RSAT-AD-PowerShell" | Out-File $Log -Append

Write-Host "[ ] Import module ActiveDirectory"
"[ ] Import module ActiveDirectory" | Out-File $Log -Append
Import-module ActiveDirectory
Write-Host "[OK] Module ActiveDirectory" -ForegroundColor Green
"[OK] Module ActiveDirectory" | Out-File $Log -Append
}

#Create user account
Write-Host "[ ] Create New ActiveDirectory User account"
"[ ] Create New ActiveDirectory User account" | Out-File $Log -Append
$User = Get-AdUser -Identity $CopyUser
$DN = $User.distinguishedName
$OldUser = [ADSI]"LDAP://$DN"
$Parent = $OldUser.Parent
$OU = [ADSI]$Parent
$OUDN = $OU.distinguishedName
$NewName = "$SurName, $Initials"

New-ADUser -SamAccountName $UserName -UserPrincipalName $UserName -Name "$NewName" -GivenName "$GivenName" -Initials "$Initials" -Surname "$SurName" -DisplayName "$NewName" -EmailAddress "$Mail" -Instance $DN -Path "$OUDN" -AccountPassword (ConvertTo-SecureString -AsPlainText "$PassWord" -Force) -enabled $true

Start-Sleep -s 20

#Determine If Users Is In Active Directory 
$TestUser = Get-ADUser -LDAPFilter "(sAMAccountName=$UserName)"
If ($TestUser  -eq $Null) 
{
Write-Host "[ERROR] Create New ActiveDirectory User account" -ForegroundColor Red
"[ERROR] Create New ActiveDirectory User account" | Out-File $Log -Append
$Time = (Get-Date -UFormat "%d-%m-%Y %T")
Write-Host "[$Time] [END] $Title"
"[$Time] [END] $Title" | Out-File $Log -Append
exit
}
Else 
{
Write-Host "[OK] Create New ActiveDirectory User account" -ForegroundColor Green
"[OK] Create New ActiveDirectory User account" | Out-File $Log -Append
}


#Test user login
Write-Host "[ ] Test account authentication"
"[ ] Test account authentication" | Out-File $Log -Append
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct,$Domain
If ($pc.ValidateCredentials($UserName,$Password) -eq $true)
{
Write-Host "[OK] Authentication successfully" -ForegroundColor Green
"[OK] Authentication successfully" | Out-File $Log -Append
}
else
{
Write-Host "[ERROR] Authentication not successful" -ForegroundColor Red
"[ERROR] Authentication not successful" | Out-File $Log -Append
}

#Add the new User to the Same Groups as the old user
Write-Host "[ ] Add the new User to the Same Groups as the old user"
"[ ] Add the new User to the Same Groups as the old user" | Out-File $Log -Append
Get-ADUser -Identity $CopyUser -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $UserName
Write-Host "[OK] Add-ADGroupMember" -ForegroundColor Green
"[OK] Add-ADGroupMember" | Out-File $Log -Append

Write-Host "[ ]"
"[ ]" | Out-File $Log -Append

$Time = (Get-Date -UFormat "%d-%m-%Y %T")
Write-Host "[$Time] [END] $Title"
"[$Time] [END] $Title" | Out-File $Log -Append

#create user mailbox

#retrieve exchange cas servers
$ADConfigurationPartition = "CN=Configuration,$((Get-ADDomain).DistinguishedName)"
$ExchangeServers = Get-ADObject -Filter {ObjectClass -eq "msExchExchangeServer"} -SearchScope Subtree -SearchBase $ADConfigurationPartition
foreach ($ExchangeServer in $ExchangeServers)
{
    $ExchangeServerCurrentServerRoles = (Get-ADObject $ExchangeServer -Properties msExchCurrentServerRoles).msExchCurrentServerRoles
}