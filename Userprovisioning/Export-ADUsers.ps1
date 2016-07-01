function Export-ADUsers
{
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true
        )]$SearchBase,
        [parameter(
            Mandatory=$true,
            Position=1,
            ValueFromPipeline=$true
        )]$OutputFile
    )
    begin {
    } process {
        Get-ADUser -Filter * -Properties * -SearchBase $SearchBase | ConvertTo-Csv | Out-File $OutputFile
    } end {
    }
}
Export-ADUsers -SearchBase 'OU=Users,OU=?????,DC=?????,DC=?????' -OutputFile $(Join-Path (Split-Path $MyInvocation.InvocationName) 'ADUsers.csv')