function ConvertFrom-Epoch
{
  param (
    [string]$Epoch
  )
   [timezone]::CurrentTimeZone.ToLocalTime(([datetime]'1/1/1970').AddSeconds($Epoch))
}