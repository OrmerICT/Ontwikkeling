﻿function ConvertTo-WEuropeStandardTime
{
  param (
    [datetime]$DateTime
  )
  $TimeZoneInfo = [System.TimeZoneInfo]::FindSystemTimeZoneById('W. Europe Standard Time')
  $CurrentTimeZone = [system.timezone]::CurrentTimeZone
  if ($CurrentTimeZone.StandardName -ne $TimeZoneInfo.StandardName) {    
    [System.TimeZoneInfo]::ConvertTimeFromUtc($DateTime.ToUniversalTime(), $TimeZoneInfo)
  }
  else{
    $DateTime
  }
}

function Format-LogDateTime
{
  param (
    [datetime]$DateTime
  )
    if(($DateTime.Day -lt 10)){
        $Day = "0$($DateTime.Day)"
    }
    else{
        $Day = "$($DateTime.Day)"
    }

    if(($DateTime.Month -lt 10)){
        $Month = "0$($DateTime.Month)"
    }
    else{
        $Month = "$($DateTime.Month)"
    }

    $Year = "$($DateTime.Year)"

    if(($DateTime.Hour -lt 10)){
        $Hour = "0$($DateTime.Hour)"
    }
    else{
        $Hour = "$($DateTime.Hour)"
    }

    if(($DateTime.Minute -lt 10)){
        $Minute = "0$($DateTime.Minute)"
    }
    else{
        $Minute = "$($DateTime.Minute)"
    }

    if(($DateTime.Second -lt 10)){
        $Second = "0$($DateTime.Second)"
    }
    else{
        $Second = "$($DateTime.Second)"
    }
    $Millisecond = "$($DateTime.Millisecond)"

    $TimeArray = @()
    $TimeArray+=("$($Day)-$($Month)-$($Year)")
    $TimeArray+=("$($Hour):$($Minute):$($Second):$($Millisecond)")

    Return $TimeArray
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
        $DateTime = ConvertTo-WEuropeStandardTime -DateTime (Get-Date)
        $FormattedDateTime = Format-LogDateTime -DateTime $DateTime
        $LogDate = $FormattedDateTime[0]
        $LogTime = $FormattedDateTime[1]
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