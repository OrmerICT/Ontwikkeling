function New-OrmMsolUser
{
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory=$true,
            Position=0
        )]
        $DisplayName,
        [parameter(
            Mandatory=$true,
            Position=0
        )]
        $UserPrincipleName
    )
    begin
    {
    }
    process
    {
        if (!(Get-MsolUser -UserPrincipalName $UserPrincipleName -ErrorAction SilentlyContinue))
        {
            try
            {
                $Password = New-RandomComplexPassword -Length 8
                New-MsolUser -UserPrincipalName "$UserPrincipleName" -DisplayName "$DisplayName" -Password "$Password"
            }
            catch
            {
                Write-Error $_
            }
        }
        else
        {
            Write-Error -Message "A user with UserPrincipalName $UserPrincipleName already exists!" -Category 'WriteError'
        }
    }
    end
    {
    }
}
New-OrmMsolUser -DisplayName 'Jeff Wouters' -UserPrincipleName 'JeffWouters@ormer.onmicrosoft.com'
