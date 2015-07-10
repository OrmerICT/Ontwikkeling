function f_hoi{
[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber
    )

#

begin {
    . .\Olaf.ps1
    $Domain = $env:USERDOMAIN
    $MachineName = $env:COMPUTERNAME
    $procname = $MyInvocation.Scriptname.Split(“\”)[2]
    $Customer = $MachineGroep.Split(“.”)[2]

    $logvar = New-Object -TypeName PSObject -Property @{
        'Logfile' = $LogFile
        'Domain' = $Domain 
        'MachineName' = $MachineName
        'procname' = $procname
        'Customer' = $Customer
        'Operator'= $Operator
        'TDNumber'= $TDNumber
        }
} # End begin

process {
    
    f_New-Log -logvar $logvar -status 'Error' -Message 'Helo world'

} # End process
 
End {
}

}
f_hoi