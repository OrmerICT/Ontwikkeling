[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [string]$KworkingDir,

    # Procedure vars
    [Parameter(Mandatory=$true)]
	[String] $UserName,
	
	[Parameter(Mandatory=$true)]
	[String] $PassWord,

	[Parameter(Mandatory=$false)]
	[String] $Domain = $env:USERDOMAIN
)

Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$GetProcName = Get-PSCallStack
$procname = $GetProcname.Command
$Customer = $MachineGroep.Split(“.”)[2]

#region Object
$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}
#endregion Object
    
#region Execution
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message $procname
    




#######################################
## FUNCTION 1 - f_Import-Module
########################################

function f_Import-Module{

    if ((Get-Module -ListAvailable ActiveDirectory) -eq $null){
		f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Server is no DC"
		f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END $procname"
		exit
		}
    else {
		f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Importing module ServerManager"
		Import-module servermanager
		f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Searching for RSAT-AD-PowerShell"
	
		if ((Get-WindowsFeature -Name RSAT-AD-PowerShell) -eq $null){
			f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Server is no DC"
			f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END $procname"
			exit
			}
		else{
			$RSAT = (Get-WindowsFeature -name RSAT-AD-PowerShell).Installed
			
			If ($RSAT -eq $false){
				f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "RSAT-AD-PowerShell not found"
				f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Add Windows Feature RSAT-AD-PowerShell"
				Add-WindowsFeature RSAT-AD-PowerShell
				f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Import module ActiveDirectory"
				Import-module ActiveDirectory
				}
			else{
				f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "RSAT-AD-PowerShell found"
				f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Import module ActiveDirectory"
				Import-module ActiveDirectory
				}
			}
		}	
}   #End of Function f_Import-Module
##########################################################################################################


#######################################
## FUNCTION 2 - f_UserExist
#######################################

function f_UserExist{

Param(
	 [String]$UserName
	 )

	$TestUser = Get-ADUser -LDAPFilter "(sAMAccountName=$UserName)"
	If ($TestUser  -eq $Null){
		f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "User $UserName does not exist"
		f_New-Log -logvar $logvar -status 'Failure' -LogDir $KworkingDir -Message "END $procname"
		exit
		}
	Else{
		f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "User $UserName found"
		}
}   #End of Function f_UserExist
##########################################################################################################


#######################################
## FUNCTION 3 - f_UserDisabled
#######################################

function f_UserDisabled{

Param(
	 [String]$UserName
	 )
	 
	$UserEnabled = (Get-ADUser -Identity $UserName).Enabled
	If ($UserEnabled -eq $false){
		f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "User $UserName is disabled. Please contact the manager."
		f_New-Log -logvar $logvar -status 'Failure' -LogDir $KworkingDir -Message "END $procname"
		exit
		}
	else{
		f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "User $UserName is enabled"
		}
}   #End of Function f_UserDisabled
##########################################################################################################


#######################################
## FUNCTION 4 - f_resetPassword
#######################################

function f_resetPassword{

Param(
	 [String]$UserName,
	 
	 [String]$PassWord
	 )
	 
	f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Reset user password"
	Set-ADAccountPassword -identity $UserName -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$PassWord" -Force) | Set-ADuser -ChangePasswordAtLogon $Value
	f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Unlock user account"
	Unlock-ADAccount -Identity $UserName
}   #End of Function f_resetPassword
##########################################################################################################


#######################################
## FUNCTION 5 - f_TestLogin
#######################################

function f_TestLogin{

Param(
	 [String]$Domain,
	 
	 [String]$UserName,
	 
	 [String]$PassWord
	 )

	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
	$pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct,$Domain
	If ($pc.ValidateCredentials($UserName,$Password) -eq $true){
		f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "Authentication successfully"
		}
	else{
		f_New-Log -logvar $logvar -status 'Error' -LogDir $KworkingDir -Message "Authentication not successful"
        f_New-Log -logvar $logvar -status 'Failure' -LogDir $KworkingDir -Message "END $procname"
        exit
		}

}   #End of Function f_TestLogin
##########################################################################################################



####################
## MAIN SCRIPT BODY
####################


#########################
#Stage 1 - import modules
#########################

#Call f_Import-Module
f_Import-Module


##################################################
#Stage 2 - Check if user exists in ActiveDirectory
##################################################

#Call f_UserExist
f_UserExist -UserName $UserName


####################################
#Stage 3 - Check if user is disabled
####################################

#Call f_UserDisabled
f_UserDisabled -UserName $UserName


##############################
#Stage 4 - Reset User Password
##############################

#Call f_resetPassword
f_resetPassword -UserName $UserName -PassWord $PassWord


##########################
#Stage 4 - User login Test
##########################

#Call f_TestLogin
f_TestLogin -Domain $Domain -UserName $UserName -PassWord $PassWord


f_New-Log -logvar $logvar -status 'Success' -LogDir $KworkingDir -Message "END $procname"


#endregion Execution