#region Helper functions (ORM Module)
Function New-RandomComplexPassword
{
    param ( [int]$Length = 8 )
    try {
        $Assembly = Add-Type -AssemblyName System.Web
        $RandomComplexPassword = [System.Web.Security.Membership]::GeneratePassword($Length,2)
        Write-Output $RandomComplexPassword
    }
    catch
    {
        Write-Error $_
    }
}
#endregion Helper functions (ORM Module)

$SecurePassword = ConvertTo-SecureString -String "nCy7-eNT$&v{o_WJ" -AsPlainText -Force
$Creds = New-Object System.Management.Automation.PSCredential ("beheerder@ormer.onmicrosoft.com", $SecurePassword)

#Office 365 - Connect to 
Connect-MsolService -Credential $Creds

#SharePoint Online - Connect to
Connect-SPOService -Url 'https://ormer-admin.sharepoint.com' -credential $Creds

#Skype for Business Online - Connect to
$SFBOSession = New-CsOnlineSession -Credential $Creds
Import-PSSession -Session $SFBOSession

#Exchange Online - Connect to
$EOSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri "https://ps.outlook.com/powershell" -Credential $Creds -Authentication "Basic" -AllowRedirection
Import-PSSession -Session $EOSession

