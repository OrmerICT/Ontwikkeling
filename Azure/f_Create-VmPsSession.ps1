Function f_Create-VmPsSession {

Param(
      #The virtual machine name
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName,

      #The admin user account 
      [parameter(Mandatory,Position=2)]
      [ValidateNotNullOrEmpty()]
      [String]$AdminUser,

      #The admin user password
      [parameter(Mandatory,Position=3)]
      [ValidateNotNullOrEmpty()]
      $SecurePassword,

      #The admin user password
      [parameter(Mandatory,Position=4)]
      [ValidateNotNullOrEmpty()]
      $Suffix
      )



    Write-Verbose "$(Get-Date -f T) - Creating PS Remoting session on $VMName"

#Get the WinRM URI of the host
$WinRmUri = Get-AzureWinRMUri -ServiceName "$VMName$Suffix" -Name $VMName

    #Error handling
    If ($WinRmUri) {

        #Write details of current subscription to screen
        Write-Verbose "$(Get-Date -f T) - WINRM connection URI obtained"

        #Create a credential object to pass to New-PSSession
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AdminUser,$SecurePassword

            #Error handling
            If ($Credential) {

                #Write credential object confirmation to screen
                Write-Verbose "$(Get-Date -f T) - Credential object created"

                #Create a new remote PS Session to pass commands to
                $VMSession = New-PSSession -ConnectionUri $WinRmUri.AbsoluteUri -Credential $Credential

                    #Error handling
                    If ($VMSession) {

                        #Write remote PS session confirmation to screen
                        Write-Verbose "$(Get-Date -f T) - Remote PS session established"
                        Return $VMSession

                    }   #End of If ($VMSession)
                    Else {

                        #Write Error and exit
                        Write-Error "Unable to create remote PS session" 

                    }   #End of Else ($VMSession)


            }   #End of If ($Credential)
            Else {

                #Write Error and exit
                Write-Error "Unable to create credential object" 

            }   #End of Else ($Credential)


    }   #End of If ($WinRmUri)
    Else {

        #Write Error and exit
        Write-Error "Unable to obtain a valid WinRM URI" 

    }   #End of Else ($WinRmUri)
return $VMSession

}   #End of Function f_Create-VmPsSession
