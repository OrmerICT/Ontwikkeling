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
$Procname = $MyInvocation.MyCommand.Name
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
  f_New-Log -logvar $logvar -status 'Info' -Message 'Getting snapshots of virtual machines' -LogDir $KworkingDir
 #endregion Execution

 function ConvertTo-WEuropeStandardTime
 {
   param (
     [datetime]$DateTime
   )
   if (([system.timezone]::CurrentTimeZone).StandardName -ne 'W. Europe Standard Time') {
     $TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById('W. Europe Standard Time')
     [System.TimeZoneInfo]::ConvertTimeFromUtc($DateTime, $TimeZone)
   }
   else
   {
     $DateTime
   }
 }

f_New-Log -logvar $logvar -status 'Info' -Message 'Getting last update datetime' -LogDir $KworkingDir
 try {
   $KeyValue = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install').lastsuccesstime   
   $System = (Get-Date -Format 'yyyy-MM-dd hh:mm:ss')  
   if ($KeyValue -lt $System) 
   {
     $UpdateTime = (ConvertTo-WEuropeStandardTime ([datetime]$KeyValue)).tostring()
     f_New-Log -logvar $logvar -status 'Success' -Message "Last updates were installed on: $UpdateTime" -LogDir $KworkingDir
   }
   else
   {
     f_New-Log -logvar $logvar -status 'Success' -Message 'Last updates were installed just now' -LogDir $KworkingDir
   }
 }
 catch
 {
   f_New-Log -logvar $logvar -status 'Error' -Message 'Unable to query when updates were last installed' -LogDir $KworkingDir
 }
