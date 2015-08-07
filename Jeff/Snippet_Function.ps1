function Get-MyFoo {
  <#
      .SYNOPSIS
      Synopsis
      .DESCRIPTION
      Synopsis + Description
      .EXAMPLE
      A description of what this example does, followed by the example.

      PS C:\> Verb-PrefixNoun -ComputerName "Server1"
      .NOTES
      Author  : Jeff Wouters
      Version : 0.9
      Company : Ormer ICT
  #>
  [cmdletbinding(
      ConfirmImpact='Medium',
      HelpURI = 'http://www.ormer-ict.nl'
  )]
  param (
    [parameter(
        Mandatory=$true,
        Position=0,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true
    )]
    [ValidateNotNullOrEmpty()]
    [Alias('Name')]
    [string[]]$ComputerName
  )
  begin {
  }
  process {
    try {
    }
    catch {
      Write-Error $_
    }
    finally {
    }
  }
  end {
  }
}