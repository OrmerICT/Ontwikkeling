################################
## FUNCTION 6 - f_Add-DcDataDrive
################################

#Configure the data drive on the DC

Function f_Add-DcDataDrive {

Param(
      #The PS Session to connect to
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      $VMSession
      )

#We've added an additional disk to store AD's DB, logs and SYSVOl - time to initialize, partition and format the drive
$ConfigureDisk = Invoke-Command -Session $VMSession -ScriptBlock {Get-Disk | Where-Object {$_.PartitionStyle -eq "RAW"} | 
                                                                  Initialize-Disk -PartitionStyle MBR -PassThru |
                                                                  New-Partition -UseMaximumSize -DriveLetter Z | 
                                                                  Format-Volume -FileSystem NTFS -Force -Confirm:$False}
    #Error handling
    If ($ConfigureDisk) {
    
        #Write remote PS session confirmation to screen
        Write-Verbose "$(Get-Date -f T) - Additional data disk successfully configured"
    
    }   #End of If ($VMSession)
    Else {
    
        #Write Error and exit
        Write-Error "Unable to configure additional data disk" 
    
    }   #End of Else ($VMSession)


}   #End of Function f_Add-DcDataDrive



##########################################################################################################