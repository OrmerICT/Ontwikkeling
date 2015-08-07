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

Export-ModuleMember -Function 'ConvertTo-WEuropeStandardTime'

function ConvertTo-Epoch
{
  param (
    [datetime]$DateTime
  )
  #ToDo: Get epoch time for logging
  Get-Date $DateTime -UFormat %s
}

Export-ModuleMember -Function 'ConvertTo-Epoch'

function ConvertFrom-Epoch
{
  param (
    [string]$Epoch
  )
   [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Epoch))
}

Export-ModuleMember -Function 'ConvertFrom-Epoch'