function Export-ADGroups
{
    [cmdletbinding()]
    param (
        [parameter(
            Mandatory=$true,
            Position=0,
            ValueFromPipeline=$true
        )]$SearchBase
    )
    begin {
    } process {
        Get-ADGroup -Filter * -Properties * -SearchBase $SearchBase
    } end {
    }
}
Export-ADGroups -SearchBase 'OU=Groups,OU=?????,DC=?????,DC=?????' |  ConvertTo-Csv -NoTypeInformation | Out-File $(Join-Path (Split-Path $MyInvocation.InvocationName) 'ADGroups.csv')