Function List-FolderSize { 
<#
  .SYNOPSIS
  List the path and size of folders.
  .DESCRIPTION
  List the path and size of folders to a definable depth in MB, GB or TB up to 
  three decimals.
  .EXAMPLE
  Get-ChildItemToDepth -Path 'D:\' -ToDepth 3 -Format GB -ErrorAction SilentlyContinue | 
    Sort-Object -Property size | 
      ConvertTo-Csv | 
        Out-File -FilePath c:\kworking\FolderSize.csv
  .NOTES
  Version  :  0.1
  Customer :  Ormer ICT
  Author   :  Jeff Wouters
#>
  Param( 
    [parameter(
        Mandatory=$true,
        Position=0
    )]
    [String]$Path, 
    [Parameter(
        Mandatory=$false
    )]
    [ValidateSet('MB','GB','TB')]
    $Format = 'GB',
    [parameter(
        Mandatory=$false
    )]
    [Byte]$ToDepth = 1, 
    [parameter(
        Mandatory=$false
    )]
    [Byte]$CurrentDepth = 0
  ) 
  
  $CurrentDepth++
  Get-ChildItem $Path | Where-Object {$_.Attributes -eq 'Directory' -and $_.FullName.length -lt 260 } | foreach {
    $itemSum = Get-ChildItem $_.FullName -recurse | Where-Object {$_.length -gt 0 } | Measure-Object -property length -sum     
    New-Object -TypeName PSObject -Property @{
      'FullName' = $_.FullName
      'Size' = '{0:N3}' -f ($itemSum.sum / ('1'+$Format))
    }
    If ($_.PsIsContainer) { 
      If ($CurrentDepth -le $ToDepth) {
        Get-ChildItemToDepth -Path $_.FullName -ToDepth $ToDepth -CurrentDepth $CurrentDepth
      } Else { 
         Write-Debug $("Skipping Folder: $($_.FullName) ")          
      } 
    } 
  } 
}