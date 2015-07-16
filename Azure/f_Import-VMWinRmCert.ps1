##############################
## FUNCTION 4 - Import-VMCert
##############################

#Imports a VM WinRM management cert

Function f_Import-VMWinRmCert {

Param(
     #The virtual machine name
      [parameter(Mandatory,Position=1)]
      [ValidateNotNullOrEmpty()]
      [String]$VMName
      )

#Troubleshooting messages
Write-Verbose "$(Get-Date -f T) - Obtaining thumbprint of WinRM cert for $VMName"
Write-Debug "About to obtain thumbprint of WinRM cert for $VMName"

#Get the thumbprint of the VM's WinRM cert
$WinRMCert = (Get-AzureVM -ServiceName "$VMName$Suffix" -Name $VMName).VM.DefaultWinRMCertificateThumbprint

    If ($WinRMCert) {
    
        #Troubleshooting messages
        Write-Verbose "$(Get-Date -f T) - Saving $VMName$Suffix Azure certificate data to cer file"
        Write-Debug "About to save $VMName$Suffix Azure certificate data to cer file"

        #Get a certificare object for the VM's service and save it's data to a .cer file
        (Get-AzureCertificate -ServiceName "$VMName$Suffix" -Thumbprint $WinRMCert -ThumbprintAlgorithm sha1).Data | 
        Out-File $SourceParent\"$VMName$Suffix.cer"

            #Error handling
            If ($?) {

                #Troubleshooting message
                Write-Verbose "$(Get-Date -f T) - $VMName$Suffix Azure certificate exported to cer file"
                Write-Verbose "$(Get-Date -f T) - Importing $VMName$Suffix Azure certificate to Cert:\localmachine\root"
                Write-Debug "About to import $VMName$Suffix Azure certificate to Cert:\localmachine\root"

                #Import the certifcate into the local computer's root store
                Import-Certificate -FilePath "$SourceParent\$VMName$Suffix.cer" -CertStoreLocation "Cert:\localmachine\root" -ErrorAction SilentlyContinue |
                Out-Null

                #Error handling
                If ($?) {

                    #Troubleshooting message
                    Write-Verbose "$(Get-Date -f T) - $VMName$Suffix Azure certificate imported to local computer root store"


                }   #End of If ($?)
                Else {

                    #Write Error
                    Write-Error "Unable to import certificate to local computer root store - script remoting won't be possible for $VMName$Suffix"

                }   #End of 

            }   #End of If (!$?) 
            Else {

                #Write Error
                Write-Error "Unable to export certificate to cer file - script remoting won't be possible for $VMName$Suffix"

            }   #End of Else (!$?)


    }   #End of If ($WinRMCert)
    Else {

        #Write Error
        Write-Error "Unable to obtain WinRM certificate thumbprint - script remoting won't be possible for $VMName$Suffix"

    }   #Else($WinRMCert)


}   #End of Function f_Import-VMWinRmCert


##########################################################################################################