function f_CloseVmpSession{
Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName
      )
      
    Write-Verbose "$(Get-Date -f T) - Removing PS Remoting session on $VMName" 

    Get-PSSession | Remove-PSSession -ErrorAction SilentlyContinue

        #Error handling
        If (!$?) {

            #Write Error and exit
            Write-Error "Unable to remove PS Remoting session on $VMName"

        }   #End of If (!$?) 
        Else {

            Write-Verbose "$(Get-Date -f T) - $VMName PS Remoting session successfully removed"

        }   #End of Else (!$?)
} # End of Function f_CloseVmpSession