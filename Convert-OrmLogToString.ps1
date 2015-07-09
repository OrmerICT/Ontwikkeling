function Convert-OrmLogToString {
  [cmdletbinding()]
  param (
    [parameter(
        Mandatory=$true,
        ValueFromPipeline=$true
    )]
    $Object
  )
  begin
  {
  }
  process
  {
    try
    {
      '[{0}][{1}][{2}][{3}][{4}][{5}][{6}][{7}]' -f $Object.Date,$Object.Time,$Object.Output,$Object.IdentityDomain,$Object.IdentityUserName,$Object.Status,$Object.Action,$Object.Message
    }
    catch
    {
      Write-Error $_
    }
  }
  end
  {
  }
}

Convert-OrmLogToString
