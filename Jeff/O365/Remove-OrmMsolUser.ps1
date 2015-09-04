function Remove-OrmMsolUser
{
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory=$true,
            Position=0
        )]
        $UserPrincipalName
    )
    begin
    {
        New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Starting procedure: $($procname)"
    }
    process
    {
        New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Checking if $UserPrincipalName exists"
        if (Get-MsolUser -UserPrincipalName $UserPrincipalName)
        {
            New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "$UserPrincipalName exist"
            try
            {
                New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Removing $UserPrincipalName"
                Remove-MsolUser -UserPrincipalName $UserPrincipalName -Force
                New-OrmLog -logvar $logvar -Status 'Success' -LogDir $KworkingDir -ErrorAction Stop -Message "Removed $UserPrincipalName"
            }
            catch
            {
                New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Failed to remove $UserPrincipalName"
            }
        }
        else
        {
            New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message "$UserPrincipalName does not exist!"
        }
    }
    end
    {
    }
}
Remove-OrmMsolUser -UserPrincipalName 'Jeff@ormer.onmicrosoft.com'