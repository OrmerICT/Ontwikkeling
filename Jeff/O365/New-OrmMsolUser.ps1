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
        New-OrmLog -logvar $logvar -Status 'Start' -LogDir $KworkingDir -ErrorAction Stop -Message "Starting procedure: $($procname)"
    }
    process
    {
        New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Checking if $UserPrincipleName already exists"
        if (!(Get-MsolUser -UserPrincipalName $UserPrincipleName -ErrorAction SilentlyContinue))
        {
            try
            {
                $Password = New-RandomComplexPassword -Length 8
                New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Creating user $UserPrincipleName"
                New-MsolUser -UserPrincipalName "$UserPrincipleName" -DisplayName "$DisplayName" -Password "$Password"
                New-OrmLog -logvar $logvar -Status 'Info' -LogDir $KworkingDir -ErrorAction Stop -Message "Created user $UserPrincipleName"
            }
            catch
            {
                New-OrmLog -logvar $logvar -Status 'Failure' -LogDir $KworkingDir -ErrorAction Stop -Message "Failed to create $UserPrincipleName"
            }
        }
        else
        {
            New-OrmLog -logvar $logvar -Status 'Error' -LogDir $KworkingDir -ErrorAction Stop -Message "$UserPrincipleName already exists"
        }
    }
    end
    {
    }
}
New-OrmMsolUser -DisplayName 'Jeff Wouters' -UserPrincipleName 'JeffWouters@ormer.onmicrosoft.com'
