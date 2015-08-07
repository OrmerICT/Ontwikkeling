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