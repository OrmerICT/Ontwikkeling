[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$true)]
    [string]$KworkingDir
)

Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$Procname = $MyInvocation.MyCommand.Name
$Customer = $MachineGroep.Split(“.”)[2]

#region Object
$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}
#endregion Object
    
#region Execution
f_New-Log -logvar $logvar -status 'Start' -Message "START $procname" -LogDir $KworkingDir

$UrlList = @{"googlechromestandaloneenterprise.msi" = "https://dl.google.com/tag/s/appguid%3D%7B8A69D345-D564-463C-AFF1-A69D9E530F96%7D%26iid%3D%7BACDAF21C-DF95-12A1-44B1-EF2E6CA9286B%7D%26lang%3Dnl%26browser%3D4%26usagestats%3D0%26appname%3DGoogle%2520Chrome%26needsadmin%3Dprefers%26installdataindex%3Ddefaultbrowser/dl/chrome/install/googlechromestandaloneenterprise.msi";}
 
      foreach ($filename in $UrlList.Keys) {
        $url = $UrlList.Get_Item($filename)
        try {
            Start-BitsTransfer -Source $url -Destination $KworkingDir\$filename -DisplayName "Downloading `'$filename`' to $KworkingDir" -Priority High -Description "From $url..." -ErrorVariable err
                If ($err) {Throw ""}
            ## Check if app already installed
            $CheckApp = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Where-Object Displayname -Like "google chrome"
            if ($CheckApp) {
                f_New-Log -logvar $logvar -status 'Info' -Message 'Google Chrome already installed' -LogDir $KworkingDir
                f_New-Log -logvar $logvar -status 'Info' -Message 'Start update process' -LogDir $KworkingDir
                Start-Process -FilePath "$env:systemroot\system32\msiexec.exe" -ArgumentList "/i `"$($KworkingDir)\$($filename)`" /quiet /qn /norestart" -Wait}
                f_New-Log -logvar $logvar -status 'Info' -Message 'Google Chrome updatet successfully' -LogDir $KworkingDir
            else {
                f_New-Log -logvar $logvar -status 'Info' -Message 'Google Chrome not found' -LogDir $KworkingDir
                Start-Process -FilePath "$env:systemroot\system32\msiexec.exe" -ArgumentList "/i `"$($KworkingDir)\$($filename)`" /quiet /qn /norestart" -Wait}
                f_New-Log -logvar $logvar -status 'Info' -Message 'Google Chrome installed successfully' -LogDir $KworkingDir
                } catch {
            f_New-Log -logvar $logvar -status 'Error' -Message 'Failed to install  '$filename''
            }
    }
f_New-Log -logvar $logvar -status 'Info' -Message "Remove $filename" -LogDir $KworkingDir
Remove-Item `"$($KworkingDir)\$($filename)`" -force
f_New-Log -logvar $logvar -status 'Success' -Message "END $procname" -LogDir $KworkingDir

#endregion Execution
