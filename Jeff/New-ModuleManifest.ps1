#region OrmLogging
New-ModuleManifest -Path 'D:\Methos\Customers\Ormer ICT\GitHub\Ontwikkeling\Jeff\Modules\OrmLogging\OrmLogging.psd1' `
-FunctionsToExport @(
    'Format-OrmLogDateTime',
    'New-Log'
) `
-Guid $([GUID]::NewGuid().Guid) `
-Author 'Jeff Wouters' `
-CompanyName 'Ormer ICT' `
-Description 'Module for logging inside functions and scripts written by Ormer ICT employees' `
-ModuleVersion '1.0' `
-HelpInfoUri 'http://www.ormer.nl' `
-RootModule '.\OrmLogging.psm1' `
-DefaultCommandPrefix 'Orm'
#endregion OrmLogging

#region OrmAzure
New-ModuleManifest -Path 'D:\Methos\Customers\Ormer ICT\GitHub\Ontwikkeling\Jeff\Modules\OrmAzure\OrmAzure.psd1' `
-FunctionsToExport @(
    'Update-AzurevNetConfig',
    'Test-AzureLogon',
    'Install-AzureADService',
    'Import-AzureVMWinRmCert',
    'Get-AzureImage',
    'Create-AzureVmPsSession',
    'Create-AzureVmConfig',
    'Create-AzureVM',
    'New-SecurePassword',
    'Create-ADForest',
    'Create-DCDataDrive',
    'Create-AzurevNetCfgFile',
    'Close-VmPsSession'
) `
-Guid $([GUID]::NewGuid().Guid) `
-Author 'Jeff Wouters' `
-CompanyName 'Ormer ICT' `
-Description 'Module for Azure tasks exected by Ormer ICT employees' `
-ModuleVersion '1.0' `
-HelpInfoUri 'http://www.ormer.nl' `
-RootModule '.\OrmAzure.psm1' `
-DefaultCommandPrefix 'Orm' 
#endregion OrmAzure

#region OrmToolkit
New-ModuleManifest -Path 'D:\Methos\Customers\Ormer ICT\GitHub\Ontwikkeling\Jeff\Modules\OrmToolkit\OrmToolkit.psd1' `
-FunctionsToExport @(
    'ConvertTo-WEuropeStandardTime',
    'ConvertTo-Epoch',
    'ConvertFrom-Epoch'
) `
-Guid $([GUID]::NewGuid().Guid) `
-Author 'Jeff Wouters' `
-CompanyName 'Ormer ICT' `
-Description 'Module wth generic tools to that can be in other Ormer ICT modules' `
-ModuleVersion '1.0' `
-HelpInfoUri 'http://www.ormer.nl' `
-RootModule '.\OrmToolkit.psm1' `
-DefaultCommandPrefix 'Orm'
#endregion OrmToolkit

#region OrmWSUS
New-ModuleManifest -Path 'D:\Methos\Customers\Ormer ICT\GitHub\Ontwikkeling\Jeff\Modules\OrmWSUS\OrmWSUS.psd1' `
-FunctionsToExport @(
    'Clean-WSUS'
) `
-Guid $([GUID]::NewGuid().Guid) `
-Author 'Jeff Wouters' `
-CompanyName 'Ormer ICT' `
-Description 'Module wth tools for WSUS tasks to be executed by Ormer ICT employees' `
-ModuleVersion '1.0' `
-HelpInfoUri 'http://www.ormer.nl' `
-RootModule '.\OrmWSUS.psm1' `
-DefaultCommandPrefix 'Orm'
#endregion OrmWSUS