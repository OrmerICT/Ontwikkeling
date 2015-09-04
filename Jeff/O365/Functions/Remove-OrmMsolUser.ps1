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
    }
    process
    {
        if (Get-MsolUser -UserPrincipalName $UserPrincipalName)
        {
            try
            {
                Remove-MsolUser -UserPrincipalName $UserPrincipalName -Force
            }
            catch
            {
                Write-Error $_
            }
        }
        else
        {
            Write-Error -Message "A user with UserPrincipalName $UserPrincipleName not found!" -Category 'WriteError'
        }
    }
    end
    {
    }
}
Remove-OrmMsolUser -UserPrincipalName 'Jeff@ormer.onmicrosoft.com'