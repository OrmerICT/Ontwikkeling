[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber
)
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$procname = $MyInvocation.Scriptname.Split(“\”)[2]
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
f_New-Log -logvar $logvar -status 'Error' -Message 'Helo world'
    
#endregion Execution