function Get-ChildItemToDepth
{
  param
  (
    [Parameter(Mandatory = $true)]
    $Path,
    
    $Filter = '*',
    
    [System.Int32]
    $ToDepth = 3,
    
    [System.Int32]
    $CurrentDepth = 0
  )
  
  $CurrentDepth++

  Get-ChildItem -Path $Path -Filter $Filter -File
  
  if ($CurrentDepth -le $ToDepth)
  {
    Get-ChildItem -Path $Path -Directory |
      ForEach-Object { Get-ChildItemToDepth -Path $_.FullName -Filter $Filter -CurrentDepth $CurrentDepth -ToDepth $ToDepth}
  } 
}
# Get-ChildItemToDepth -Path 'D:\Vuze Downloads' -ToDepth 5 -CurrentDepth 2