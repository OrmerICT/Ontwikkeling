<#
	.SYNOPSIS
		Exports and Imports AD-users from and to the Users OU in Active Directory.
	
	.DESCRIPTION
		Exports and Imports AD-users from and to the Users OU in Active Directory.
	
	.PARAMETER Export
		Switch that determines users in the Users OU are Exported to a CSV-file.
	
	.PARAMETER Import
		Switch that determines users in the Users OU are Imported from a CSV-file.
	
	.PARAMETER WorkingDirectory
		The Directory the script will use for Import/Export. Defaults to the Users Desktop.
	
	.EXAMPLE
		PS C:\> Import-Export-ADUsers.ps1 -Export

	.EXAMPLE
		PS C:\> Import-Export-ADUsers.ps1 -Import
	
	.NOTES
		Additional information about the file.
#>
[CmdletBinding(DefaultParameterSetName = 'Export')]
param
(
	[Parameter(ParameterSetName = 'Export')]
	[switch]$Export,
	
	[Parameter(ParameterSetName = 'Import')]
	[switch]$Import,
	
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path -Path $_ })]
	[ValidateNotNullOrEmpty()]
	[string]$WorkingDirectory = "$($ENV:userprofile)\Desktop"
)


#region Windows Server 2008

$Server2008 = [environment]::OSVersion | Select-Object -ExpandProperty Version | Where-Object { $_.Major -like "6" -and $_.Minor -like "0" }
if ($Server2008)
{
	Write-Error "Windows server 2008 detected, PowerShell Modules not supported"
	throw "Windows server 2008 detected, PowerShell Modules not supported"
}

#endregion Windows Server 2008

#region Load module Server manager

Write-Verbose -Message "Check to see if the servermanager PowerShell module is installed"
if ((get-module -name servermanager -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) -ne "servermanager")
{
	Write-Verbose -Message "Adding servermanager PowerShell module"
	Import-Module servermanager
}
else
{
	Write-Verbose -Message "servermanager PowerShell module is Already loaded"
}

#endregion Load module Server manage

#region Install RSAT-AD-PowerShell

Write-Verbose -Message "Check if RSAT-AD-PowerShell is installed"
$RSAT = (Get-WindowsFeature -name RSAT-AD-PowerShell).Installed

if ($RSAT -eq $false)
{
	Write-Warning "RSAT-AD-PowerShell not found: $($RSAT)"
	Add-WindowsFeature RSAT-AD-PowerShell
	Write-Verbose -Message "Add Windows Feature RSAT-AD-PowerShell"
	Import-module ActiveDirectory
	Write-Verbose -Message "Import module ActiveDirectory"
}
else
{
	Write-Verbose -Message "Windows Feature RSAT-AD-PowerShell installed"
}

#endregion Install RSAT-AD-PowerShell

#region Import Module Active Directory

if ((get-module -name ActiveDirectory -ErrorAction SilentlyContinue | foreach { $_.Name }) -ne "ActiveDirectory")
{
	Write-Verbose -Message "Adding ActiveDirectory PowerShell module"
	import-module ActiveDirectory
}
else
{
	Write-Verbose -Message "ActiveDirectory PowerShell module is Already loaded"
}

#endregion Import Module Active Directory

#region Functions
function New-RandomComplexPassword
{
<#
	.SYNOPSIS
		Generates a random complex password.
	
	.DESCRIPTION
		Generates a random complex password.
	
	.PARAMETER Length
		The length of the password that will be generated.
	
	.PARAMETER AsSecureString
		Determines if the generated password will be output as a Secure String
	
	.EXAMPLE
		PS C:\> New-RandomComplexPassword -Length 10 -AsSecureString
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false)]
		$Length = '8',
		
		[switch]$AsSecureString
	)
	
	Write-Verbose -Message ('Generating random complex password with [{0}] characters...' -f $Length)
	
	Try
	{
		
		# Define the character codes that will be used in the password generation process
		$PasswordCharCodes = { 33..126 }.Invoke()
		
		# Define characters that will be excluded from the password generation process (",',/,`,O,0)
		$CharactersToExclude = @(34, 39, 47, 48, 79, 96)
		
		foreach ($CharacterToExclude in $CharactersToExclude)
		{
			$PasswordCharCodes.Remove($CharacterToExclude) | Out-Null
		}
		
		# Convert the Hashtable of character codes to an Array of characters
		$PasswordChars = [char[]]$PasswordCharCodes
		
		# Generate a password using the valid characters until a valid password (containing uppercase,lowercase, digits and special characters) is generated
		do
		{
			$GeneratedPassword = ''
			for ($i = 0; $i -lt $Length; $i++)
			{
				$GeneratedPassword += Get-Random -InputObject $PassWordChars
			}
		}
		until (($GeneratedPassword -cmatch '[A-Z]') -and ($GeneratedPassword -cmatch '[a-z]') -and ($GeneratedPassword -imatch '[0-9]') -and ($GeneratedPassword -imatch '[^A-Z0-9]'))
		
		if (-not ($AsSecureString))
		{
			Write-Verbose -Message ('Generated random complex password: [{0}]' -f $GeneratedPassword)
			Write-Output -InputObject $GeneratedPassword
		}
		else
		{
			Write-Output -InputObject (ConvertTo-SecureString -String $GeneratedPassword -AsPlainText -Force)
		}
		
	}
	Catch
	{
		Write-Error -Message 'Failed to generate random complex password'
		Write-Error -ErrorRecord $_		
	}
}

function Get-ADUsersOrganizationalUnit
{
<#
	.SYNOPSIS
		Retrieves Organizational Units with the name 'Users' in the first 2 levels of Organizational Units.
	
	.DESCRIPTION
		Retrieves Organizational Units with the name 'Users' in the first 2 levels of Organizational Units.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	
	# Retrieve the OU's in the root of the Active Directory Domain
	$RootOrganizationalUnits = Get-ADOrganizationalUnit -SearchScope OneLevel -Filter *
	if ($RootOrganizationalUnits -ne $null)
	{
		$UserOUArray = @()
		foreach ($RootOrganizationalUnit in $RootOrganizationalUnits)
		{
			# For each OU in the root of the Active Directory Domain, check if there is an Users OU
			$UsersOU = Get-ADOrganizationalUnit -SearchBase $RootOrganizationalUnit.DistinguishedName -SearchScope OneLevel -Filter "Name -like '*User*'"
			if ($UsersOU)
			{
				$UserOUArray += $UsersOU
			}
		}
		Write-Output -InputObject $UserOUArray
	}
}
#endregion

#region Variables
$ExportFile = "$($WorkingDirectory)\Export-Users.csv"
$ImportUsersResult = "$($WorkingDirectory)\Result-Import-Users.csv"

Write-Verbose -Message 'Retrieving Forest and Domain information...'
$Domain = Get-ADDomain -ErrorAction Stop
$Forest = Get-ADForest -ErrorAction Stop

# Retrieve the Users OU(s)
$UsersOUS = Get-ADUsersOrganizationalUnit -ErrorAction SilentlyContinue
if ($UsersOUS -eq $null)
{
	Write-Error -Message ("No User OU's found in Active Directory Domain [{0}]" -f $Domain.DistinguishedName)
	Throw
}
#endregion


if ($Export)
{	
	if ((Test-Path -Path $ExportFile) -eq $true)
	{
		Write-Verbose -Message ('Removing existing export file [{0}]...' -f $ExportFile)
		Remove-Item -Path $ExportFile -Force -ErrorAction Stop
	}
	
	foreach ($UsersOU in $UsersOUS)
	{
		Write-Verbose -Message ('Exporting Users in OU [{0}]...' -f $UsersOU.DistinguishedName)
		$AdUsers = Get-ADUser -SearchScope SubTree -SearchBase $UsersOU.DistinguishedName -Properties * -Filter * | Select-Object -Property SamAccountName, UserPrincipalName, DisplayName, GivenName, Initials, Surname, mail, @{ Name = 'proxyAddresses'; Expression = { $_.proxyAddresses -join ';' } }, StreetAddress, City, st, PostalCode, Country, Title, Company, Description, Department, @{ Name = 'OfficeName'; Expression = { $_.OfficeName -join ';' } }, telephoneNumber
		if (-not(Test-Path -Path $ExportFile))
		{
			Write-Verbose -Message ('Exporting Users in OU [{0}] to CSV [{1}]...' -f $UsersOU.DistinguishedName, $ExportFile)
			$AdUsers | Export-Csv -Path $ExportFile -Delimiter ',' -NoTypeInformation -Encoding 'UTF8'
		}
		else
		{
			Write-Verbose -Message ('Appending Users in OU [{0}] to CSV [{1}]...' -f $UsersOU.DistinguishedName, $ExportFile)
			$AdUsers | ConvertTo-Csv -NoTypeInformation -Delimiter ',' | Select-Object -Skip 1 | Out-File -FilePath $ExportFile -Append -Encoding 'UTF8'
		}		
	}
}

if($Import)
{
	#Import csv
	Write-Verbose -Message ('Checking if Import CSV-file [{0}] exists...' -f $ExportFile)
	if ((Test-Path -Path $ExportFile) -eq $false)
	{
		Write-Error -Message ('Import CSV-file [{0}] does not exist' -f $ExportFile)
		Throw
	}
	else
	{
		Write-Verbose -Message ('Import CSV-file [{0}] exists' -f $ExportFile)
		Write-Verbose -Message ('Importing CSV-file [{0}]...' -f $ExportFile)
		$CSV = Import-Csv -Path $ExportFile -Delimiter ',' -ErrorAction SilentlyContinue -ErrorVariable ImportCSVError
		if (-not($ImportCSVError))
		{
			Write-Verbose -Message ('Successfully imported CSV-file [{0}]' -f $ExportFile)
		}
		else
		{
			Write-Error -Message ('Failed to import CSV-file [{0}]' -f $ExportFile)
			Write-Error -ErrorRecord $ImportCSVError
			Throw
		}
	}
	
	#Import users	
	$UserImportArray = @()
	foreach ($User in $CSV)
	{
		# Clear variables
		Clear-Variable -Name SurNamePrefix -Force -ErrorAction SilentlyContinue
		Clear-Variable -Name Surname -Force -ErrorAction SilentlyContinue		
		
		# Determine the Users UPN-suffix
		if ($User.mail -ne '')
		{
			$UPNSuffix = $User.Mail.ToString().Split('@')[1].Trim()
		}
		else
		{
			$UPNSuffix = $Domain.DNSRoot
		}		
		
		# Check if the UPN-suffix exists in the Forest
		if (-not($Forest.UPNSuffixes -match $UPNSuffix) -and $UPNSuffix -ne $Domain.DNSRoot)
		{
			# Add the UPN-suffix to the Forest
			Write-Verbose -Message ('Adding UPN-suffix [{0}] to the Active Directory Forest...' -f $UPNSuffix)
			Set-ADForest -Identity $Forest -UPNSuffixes @{ Add = $UPNSuffix} -ErrorAction Inquire
		}
		
		# Convert the users proxyAddresses to a Hashtable containing an Array
		if ($User.proxyAddresses -ne '')		{
			
			$OtherAttributes = @{ proxyAddresses = $User.proxyAddresses.Split(';')}
		}
		else
		{
			$OtherAttributes = ''
		}
		
		# Generate a Random Complex Password
		$NewPassword = New-RandomComplexPassword -Length 10
		
		#Determine the Users Initials. If the user does not have initials, use the first character of the SamAccountName and capitalize it
		if ($User.Initials -ne '')
		{
			$User.Initials.ToUpper().Replace('.', '').ToCharArray() | ForEach-Object { $Initials += $_ + '.' }
		}
		else
		{
			$Initials = $User.SamAccountName.Substring(0, 1).ToUpper() + '.'
		}
		
		# Generate the Users Display Name
		if ($User.Surname -ne '')
		{
			# Account for users with a hyphenated Surname (married women)
			if ($User.Surname.Contains('-'))
			{
				# Check if the hyphenated Surname has a prefix
				if ($User.Surname.Split('-')[0].Trim().Contains(' '))
				{
					$SurNamePrefix = $User.Surname.Split('-')[0].Trim().Substring(0, $User.Surname.Split('-')[0].Trim().LastIndexOf(' ')).ToLower().Trim()
					$Surname = ($User.Surname.Split('-')[$User.Surname.Split('-').Length - 2].Split(' ')[$User.Surname.Split('-')[$User.Surname.Split('-').Length - 2].Trim().Split(' ').Length - 1]) + ' - ' + ($User.Surname.Split('-')[$User.Surname.Split('-').Length - 1].Trim()) -replace '\s+', " "
				}
				else
				{
					$SurNamePrefix = ''
					$Surname = $User.Surname.Trim()
				}
			}
			else
			{
				# Check if the Surname has a prefix
				if ($User.Surname.Trim().Contains(' '))
				{
					$SurNamePrefix = $User.Surname.Trim().Substring(0, $User.Surname.LastIndexOf(' ')).ToLower().Trim() -replace '\s+', " "
					$Surname = $User.Surname.Trim().Substring($User.Surname.LastIndexOf(' ') + 1)
				}
				else
				{
					$SurNamePrefix = ''
					$Surname = $User.Surname.Trim()
				}
			}
		}
		
		if ($SurNamePrefix -ne '')
		{
			$DisplayName = "$($Surname), $($Initials) $($SurNamePrefix)"
			$Name = "$($User.GivenName) $($SurNamePrefix) $($Surname)"
		}
		else
		{
			$DisplayName = "$($Surname), $($Initials)"
			$Name = "$($User.GivenName) $($Surname)"
		}
		
		# Set the Users DisplayName and CN to the SamAccountName if the user does not have a GivenName or a Surname
		if ($User.Surname.Trim() -eq '' -or $User.GivenName.Trim() -eq '')
		{
			$DisplayName = $User.SamAccountName
			$Name = $User.SamAccountName
		}
				
		# Create a hashtable with the parameters used by the New-ADUser cmdlet
		$Properties = @{
			'Name' = $Name
			'GivenName' = $User.GivenName
			'Initials' = $Initials
			'Surname' = ("$($SurNamePrefix) $($Surname)".Trim())
			'Displayname' = $DisplayName
			'Samaccountname' = $User.SamAccountName
			'UserPrincipalName' = "$($User.SamAccountName)@$($UPNSuffix)"
			'EmailAddress' = $User.mail
			'AccountPassword' = (ConvertTo-SecureString -AsPlainText $NewPassword -Force)
			'Enabled' = $true
			'ChangePasswordAtLogon' = $false
			'Description' = $User.Description
			'Path' = ($UsersOUS | Select-Object -First 1).DistinguishedName
		}
		
		<#
		Add the OtherAttributes property to the hashtable if it contains a value (currently this is only used for proxyAddresses)
		The OtherAttributes parameter of the New-ADUser cmdlet does not allow empty values, so it must only be added if it's not empty
		#>
		if ($OtherAttributes -ne '')
		{
			$Properties.Add('OtherAttributes', $OtherAttributes)
		}
		
		Write-Verbose -Message ("Creating new Active Directory User Account [{0}]..." -f $Properties.Name)
		New-ADUser @Properties -PassThru -ErrorAction SilentlyContinue -ErrorVariable NewADUserError
				
		$UserImportObject = New-Object -TypeName PSCustomObject -Property @{
			'Username' = $User.SamAccountName
			'Password' = $NewPassword
			'DisplayName' = $DisplayName
			'SuccessFullyCreated' = if(-not($NewADUserError)){$true}else{$false}
		}
		$UserImportArray += $UserImportObject
	}
	
	# Export the information about the created users to CSV and output it to the Pipeline
	Write-Verbose -Message ('Exporting Import results to CSV-file [{0}]' -f $ImportUsersResult)
	$UserImportArray | Export-Csv -Path $ImportUsersResult -NoTypeInformation -Force
	Write-Output -InputObject $ImportUsersResult
}