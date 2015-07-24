[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [string]$KworkingDir
)

#region StandardFramework
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$GetProcName = Get-PSCallStack
$procname = $GetProcname.Command
$Customer = $MachineGroep.Split('.')[2]


$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

Remove-Item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title: `'$Kworking`' Script"
#endregion StandardFramework
    
#region Execution
f_New-Log -logvar $logvar -status 'Error' -Message 'Hello world' -LogDir $KworkingDir
    
#endregion Execution