function Export-ADOUStructure
{
    param (
        [parameter(
            Mandatory=$false,
            Position=0,
            ValueFromPipeline=$true
        )]
        $SearchScope= 'OU=Groups,OU=?????,DC=?????,DC=?????'
    )
    begin {
    } process {
        Get-ADOrganizationalUnit -SearchBase $SearchScope -Filter *
    } end {
    }
}
Export-ADOUStructure | ConvertTo-Csv | Out-File $(Join-Path (Split-Path $MyInvocation.InvocationName) 'ADOUStructure.csv')
