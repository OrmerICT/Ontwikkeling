function Add-OrmMsolUserLicense
{
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipelineByPropertyName=$true
        )]
        [string]$UserPrincipalName,
        [parameter(
            Mandatory=$true,
            Position=1
        )]
        [string]$License,
        [parameter(
            Mandatory=$false,
            Position=2
        )]
        [string]$UsageLocation
    )
    begin
    {
    }
    process
    {
        $MSOLAccountSkuId = try {(Get-MsolAccountSku -ErrorAction SilentlyContinue).AccountSkuId} catch {}
        if ($MsolAccountSkuId -contains "$License")
        {
            $MsolUser = try {Get-MsolUser -UserPrincipalName "$UserPrincipalName" -ErrorAction SilentlyContinue} catch {}
            if ($MsolUser -ne $null)
            {
                #If usage location is not set, adding the license will fail
                if (($MsolUser).UsageLocation -ne $null)
                {
                    try
                    {
                        Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -AddLicenses $License
                    }
                    catch
                    {
                        Write-Error "Unable to set license $License to MsolUser $UserPrincipalName"
                    }
                }
                else
                {
                    Write-Error "No UsageLocation set to MsolUser $UserPrincipalName"
                }   
            }
            else
            {
                Write-Error "MsolUser $UserPrincipalName not found!"
            }
        }
        else
        {
            Write-Error -Message "License $License is not available"
        }
    }
    end
    {
    }
}
Add-OrmMsolUserLicense -UserPrincipalName 'JeffWouters@ormer.onmicrosoft.com' -UsageLocation 'NL' -License 'Ormer:ENTERPRISEPACK'