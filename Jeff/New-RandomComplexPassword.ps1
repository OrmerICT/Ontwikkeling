Function New-RandomComplexPassword ()
{
  <#
      .SYNOPSIS
      Generates a random password.
      .DESCRIPTION
      Generates a random password that complies with the password complexibility rules from Windows.
      The length of the password can be configured via the Length parameter.
      .PARAMETER Length
      To define the length of the password.
      The default value is 8.
      .EXAMPLE
      PS C:\> New-RandomComplexPassword 16
  #>
  param ( 
    [parameter(
        Mandatory=$false,
        Position=0
    )]
    [int]$Length = 8
  )
  
  $Assembly = Add-Type -AssemblyName System.Web
  $RandomComplexPassword = [System.Web.Security.Membership]::GeneratePassword($Length,2)
  return $RandomComplexPassword
}