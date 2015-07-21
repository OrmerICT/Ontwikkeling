function ConvertTo-WEuropeStandardTime
{
  param (
    [datetime]$DateTime
  )
  $TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById("W. Europe Standard Time")
  [System.TimeZoneInfo]::ConvertTimeFromUtc($DateTime.ToUniversalTime(), $TimeZone)
}