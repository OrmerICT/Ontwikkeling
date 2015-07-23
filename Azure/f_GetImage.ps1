#region Get image

function f_GetImage{
Param(
      [parameter(Mandatory)]
      [ValidateNotNullOrEmpty()]
      [String]$OsName
      )

#    Write-Verbose "$(Get-Date -f T) - Obtaining the latest Windows Server 2012 R2 image"

    $Image = (Get-AzureVMImage | Where-Object {$_.Label -like $OsName} | Sort-Object PublishedDate -Descending)[0].ImageName

    #Error handling
    If ($Image) {

                #Write details of current subscription to screen
                Write-Verbose "$(Get-Date -f T) - Image found - $($Image)"

                }   #End of If ($Image)
    Else {

                #Write Error and exit
                Write-Error "Unable to obtain valid OS image " -ErrorAction Stop

                }   #End of Else ($Image)
                return $Image
                }

#endregion Get image