function ConvertTo-Epoch
{
  param (
    [datetime]$DateTime
  )
  #ToDo: Get epoch time for logging
  Get-Date $DateTime -UFormat %s
}