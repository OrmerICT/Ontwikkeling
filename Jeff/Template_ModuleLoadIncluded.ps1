[cmdletbinding()]
param (
    [parameter(mandatory=$true)]
    [string]$Operator,

    [parameter(mandatory=$true)]
    [string]$MachineGroep,

    [parameter(mandatory=$true)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [string]$KworkingDir    
)

#region StandardFramework
Import-Module -Name OrmLogging -ErrorAction SilentlyContinue -ErrorVariable ImportModuleOrmLoggingError
if($ImportModuleOrmLoggingError)
{
    Write-Error "Unable to import the Ormer Logging Powershell Module"
    Break
}
Import-Module -Name OrmToolkit -ErrorAction SilentlyContinue -ErrorVariable ImportModuleOrmToolkitError
if($ImportModuleOrmLoggingError)
{
    Write-Error "Unable to import the Ormer Toolkit Powershell Module"
    Break
}

Set-Location $KworkingDir -ErrorAction SilentlyContinue -ErrorVariable SetLocationError
if($ImportModuleOrmLoggingError)
{
    Write-Error "Unable to set the working directory of the script"
    Break
}
    
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
$Customer = $MachineGroep.Split('.')[2]


$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'Procname' = $Procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

Remove-Item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Starting procedure: $($procname)"
#endregion StandardFramework
    
#region Execution

New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Hello World!"
    
#endregion Execution
