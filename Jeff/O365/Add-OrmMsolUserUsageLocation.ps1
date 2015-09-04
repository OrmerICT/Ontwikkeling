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
        New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Starting procedure: $($procname)"
    }
    process
    {
        try
        {
            New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Executing procedure: $($procname) on $UserPrincipalName"
            Set-MsolUser -UserPrincipalName $UserPrincipalName -UsageLocation $UsageLocation
            New-OrmLog -logvar $logvar -Status 'Success' -LogDir $KworkingDir -ErrorAction Stop -Message "Executed procedure: $($procname) on $UserPrincipalName"
        }
        catch
        {
            New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Failed executing procedure: $($procname) on $UserPrincipalName"
        }
    }
    end
    {
    }
}
Set-OrmMsolUserUsageLocation -UserPrincipalName 'jeff@ormer.onmicrosoft.com' -UsageLocation 'NL'