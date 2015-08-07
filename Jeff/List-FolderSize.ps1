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

    [parameter(
        Mandatory=$true,
        Position=0
    )]
    [String]$Path, 
    [Parameter(
        Mandatory=$false
    )]
    [ValidateSet('MB','GB','TB')]
    $Format = 'GB',
    [parameter(
        Mandatory=$false
    )]
    [Byte]$ToDepth = 1, 
    [parameter(
        Mandatory=$false
    )]
    [Byte]$CurrentDepth = 0
)

#region StandardFramework
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$GetProcName = Get-PSCallStack
$procname = $GetProcname.Command
$Customer = $MachineGroep.Split(“.”)[2]

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
  $CurrentDepth++
  Get-ChildItem $Path | Where-Object {$_.Attributes -eq 'Directory' -and $_.FullName.length -lt 260 } | foreach {
    f_New-Log -logvar $logvar -status 'Info' -Message "Enumerating $($_.FullName)" -LogDir $KworkingDir
    try {
      $itemSum = Get-ChildItem $_.FullName -recurse | Where-Object {$_.length -gt 0 } | Measure-Object -property length -sum     
      New-Object -TypeName PSObject -Property @{
        'FullName' = $_.FullName
        'Size' = '{0:N3}' -f ($itemSum.sum / ('1'+$Format))
      }
      f_New-Log -logvar $logvar -status 'Success' -Message "Enumerated $($_.FullName)" -LogDir $KworkingDir
    }
    catch
    {
      f_New-Log -logvar $logvar -status 'Error' -Message 'Error found calculating the sum' -LogDir $KworkingDir
    }
    If ($_.PsIsContainer) { 
      If ($CurrentDepth -le $ToDepth) {
        Write-Verbose "$(Get-Date -f T) - Folder: $($_.FullName)"
        Get-ChildItemToDepth -Path $_.FullName -ToDepth $ToDepth -CurrentDepth $CurrentDepth
      } Else {
        f_New-Log -logvar $logvar -status 'Info' -Message "Skipping $($_.FullName)" -LogDir $KworkingDir
      } 
    } 
  }

f_New-Log -logvar $logvar -status 'Error' -Message 'Hello world' -LogDir $KworkingDir
    
#endregion Execution