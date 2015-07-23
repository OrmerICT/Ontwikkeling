Function f_CreateSecurePassword {

Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminPassword
      )

$SecurePassword = $AdminPassword | ConvertTo-SecureString -AsPlainText -Force

    #Error handling
    If ($SecurePassword) {

        #Write secure string confirmation to screen
        Write-Verbose "$(Get-Date -f T) - Admin password converted to a secure string"

     }   #End of If ($SecurePassword)
     Else {

        #Write Error and exit
        Write-Error "Unable to convert secure password" -ErrorAction Stop

    }   #End of Else ($SecurePassword)
    return $SecurePassword
}