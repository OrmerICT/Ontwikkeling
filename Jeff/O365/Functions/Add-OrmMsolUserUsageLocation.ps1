function Set-OrmMsolUserUsageLocation
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
        [string]$UsageLocation
    )
    begin
    {
    }
    process
    {
        try
        {
            Set-MsolUser -UserPrincipalName $UserPrincipalName -UsageLocation $UsageLocation
        }
        catch
        {
            Write-Error $_
        }
    }
    end
    {
    }
}
Set-OrmMsolUserUsageLocation -UserPrincipalName 'jeff@ormer.onmicrosoft.com' -UsageLocation 'NL'