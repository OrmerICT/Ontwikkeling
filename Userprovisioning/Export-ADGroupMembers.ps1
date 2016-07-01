function Export-ADGroupMembers
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
        $Groups = Get-ADGroup -Filter * -Properties * -SearchBase $SearchBase
        $Output = foreach ($Group in $Groups) {
            $Members = $Group | Get-ADGroupMember | select @{label='GroupName';Expression={$Group.Name}},*
            $Members 
        }
        $Output 
    } end {
    }
}
Export-ADGroupMembers -SearchBase 'OU=Groups,OU=?????,DC=?????,DC=?????' | ConvertTo-Csv -NoTypeInformation | Out-File $(Join-Path (Split-Path $MyInvocation.InvocationName) 'ADGroupMembers.csv')