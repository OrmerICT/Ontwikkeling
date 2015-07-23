function ConvertTo-WEuropeStandardTime
{
  param (
    [datetime]$DateTime
  )
  $TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Europe Standard Time")
  [System.TimeZoneInfo]::ConvertTimeFromUtc($DateTime.ToUniversalTime(), $TimeZone)
}

function f_New-Log {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$False)]
        [PSObject]$logvar,
        [parameter(mandatory=$true)][validateset('Start','Error','Success','Failure','Info')]
        [string]$Status,
        [Parameter(Mandatory=$False)]
        [string]$Message,
        [parameter(mandatory=$true)]
        [string]$LogDir
    )
    $LogFile= "$($LogDir)\ProcedureLog.log"
    try 
    {
        $DateTime = (Get-Date).ToUniversalTime()
        $DateTime = ConvertTo-WEuropeStandardTime -DateTime $DateTime
        $LogDate = "$($DateTime.Day)-$($DateTime.Month)-$($DateTime.Year)"
        $LogTime = "$($DateTime.Hour):$($DateTime.Minute):$($DateTime.Second):$($DateTime.Millisecond)"
        #$Ormlogstring = '[{0}][{1}][{2}][{3}][{4}][{5}][{6}][{7}][{8}]' -f $($DateTime.SubString(0,10)),$($DateTime.SubString(11)),$logvar.Operator,$logvar.Domain,$Logvar.MachineName,$logvar.Customer,$logvar.TDNumber,$Status,$Message
        #$DateTime = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'
        $Ormlogstring = '[{0}][{1}][{2}][{3}][{4}][{5}][{6}][{7}][{8}][{9}]' -f $LogDate,$LogTime,$logvar.Operator,$logvar.Domain,$Logvar.MachineName,$logvar.Customer,$logvar.TDNumber,$logvar.Procname,$Status,$Message
        $OrmLogString | Out-File $logFile -Append
    }
    catch
    {
        Write-Error -Message 'Unable to generate OrmLog'
    }
}