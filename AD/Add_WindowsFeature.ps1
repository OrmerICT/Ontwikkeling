###############################################################################
#   Ormer LEGAL STATEMENT FOR SAMPLE SCRIPTS/CODE
###############################################################################
<#
#******************************************************************************
# File:     Add_WindowsFeature.ps1
# Date:     07/30/2015
# Version:  0.2
#
# Purpose:  PowerShell script to add a new Feature to a Windows server(s).
#
# Usage:    Add_WindowsFeature.ps1
# Needed: Remote administration tools to add a new Feature to a Windows server(s)
#
# Copyright (C) 2015 Ormer ICT 
# https://social.technet.microsoft.com/forums/windowsserver/en-US/26cc0a4e-306c-4a95-8313-ad6c09120e59/powershell-eindows-form-drop-down-selection
# Revisions:
# ----------
# 0.1.0   07/28/2015   Created script. (By PvdW)
# 0.2.0   07/30/2015   Updated script. (By PvdW)
#    
#>#******************************************************************************
#region Start Parameters
[cmdletbinding()]
param (
    [parameter(mandatory=$false)]
    [string]$Operator,

    [parameter(mandatory=$false)]
    [string]$MachineGroep,

    [parameter(mandatory=$false)]
    [string]$TDNumber,

    [parameter(mandatory=$false)]
    [string]$FeatureChoice,
    
    #[parameter(mandatory=$false)]
    #[string]$Procname,

    [parameter(mandatory=$true)]
    [string]$KworkingDir

#Procedure Vars
#    [parameter(mandatory=$true)]
#    [string]$UserName
)
#endregion Start Parameters


#region Function Show-Usage
function Show-Usage()
{
$usage = @'
Add-Font.ps1
This script is used to Add Windows Features.

Usage:

Help:
Add_WindowsFeature.ps1 -help 

Install:
Add_WindowsFeature.ps1 -kworking -TDnumber

Parameters:

    -help
     Displays usage information.

Examples:
    
'@

$usage
}
#endregion Function Show-Usage

#region Function Process-Arguments
function Process-Arguments()
{
    ## Write-host 'Processing Arguments'

    if ($unnamedArgs.Length -gt 0)
    {
        #write-host "The following arguments are not defined:"
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message 'The following arguments are not defined:'
        $unnamedArgs
    }

    if ($help -eq $true) 
    { 
        Show-Usage
        break
    }
}
#endregion Function Process-Arguments

#region Function Dropdown
function Return-DropDown {
 $script:Choice = $DropDown.SelectedItem.ToString()
 $Form.Close()
 Write-Host $Choice
}
#endregion Function Dropdown

function OnApplicationLoad {
	#Note: This function runs before the form is created
	#Note: To get the script directory in the Packager use: Split-Path $hostinvocation.MyCommand.path
	#Note: To get the console output in the Packager (Windows Mode) use: $ConsoleOutput (Type: System.Collections.ArrayList)
	#Important: Form controls cannot be accessed in this function
	#TODO: Add snapins and custom code to validate the application load
	
	return $true #return true for success or false for failure
}

function OnApplicationExit {
	#Note: This function runs after the form is closed
	#TODO: Add custom code to clean up and unload snapins when the application exits
	
	$script:ExitCode = 0 #Set the exit code for the Packager
}

function GenerateForm {

	#----------------------------------------------
	#region Import Assemblies
	#----------------------------------------------
	[void][reflection.assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
	[void][reflection.assembly]::Load("mscorlib, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	[void][reflection.assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
	#endregion
	
	#----------------------------------------------
	#region Generated Form Objects
	#----------------------------------------------
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$form1 = New-Object System.Windows.Forms.Form
	$label1 = New-Object System.Windows.Forms.Label
	$button1 = New-Object System.Windows.Forms.Button
    $button2 = New-Object System.Windows.Forms.Button
	$combobox1 = New-Object System.Windows.Forms.ComboBox
	$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
	#endregion Generated Form Objects

	#----------------------------------------------
	# User Generated Script
	#----------------------------------------------
	
	$FormEvent_Load={
		#TODO: Initialize Form Controls here
		#Import-Csv -Delimiter ";" -Path C:\kworking\FeaturesW2K12.txt | % {
         Import-Csv -Path C:\kworking\FeaturesW2K12.csv | % {
		$combobox1.Items.Add($_.name)
		}
	}
	
	$handler_button1_Click={
	#TODO: Place custom script here
		#$x = Import-Csv -Delimiter ";" -Path C:\kworking\FeaturesW2K12.txt | ? { $_.name -eq $combobox1.Text } | Select -first 1
        $x = Import-Csv -Path C:\kworking\FeaturesW2K12.csv | ? { $_.name -eq $combobox1.Text } | Select -first 1
	#	$label1.Text = (Test-Connection -ComputerName $x.server -Quiet).toString()
        $FeatureChoice = $combobox1.Text
        Write-Host $combobox1.Text
        Add-WindowsFeature -Name $FeatureChoice -ErrorAction SilentlyContinue -WhatIf
        }
	
	#----------------------------------------------
	# Generated Events
	#----------------------------------------------
	
	$Form_StateCorrection_Load=
	{
		#Correct the initial state of the form to prevent the .Net maximized form issue
		$form1.WindowState = $InitialFormWindowState
	}
	
	#region Start Form
	# form1
	#
	$form1.Controls.Add($label1)
	$form1.Controls.Add($button1)
    $form1.Controls.Add($button2)
	$form1.Controls.Add($combobox1)
	$form1.ClientSize = New-Object System.Drawing.Size(900,400)
	$form1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$form1.Name = "form1"
	$form1.Text = "Add Windows Feature"
	$form1.add_Load($FormEvent_Load)
    $Form1.StartPosition = "CenterScreen"
	#
	# label1
	#
	$label1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$label1.Location = New-Object System.Drawing.Point(40,25)
	$label1.Name = "label1"
	$label1.Size = New-Object System.Drawing.Size(500,50)
	$label1.TabIndex = 2
	$label1.Text = "Add Windows Feature"
	#
	# button1
	#
	$button1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$button1.Location = New-Object System.Drawing.Point(100,250)
	$button1.Name = "button1"
	$button1.Size = New-Object System.Drawing.Size(200,50)
	$button1.TabIndex = 1
	$button1.Text = "OK"
	$button1.UseVisualStyleBackColor = $True
	$button1.add_Click($handler_button1_Click)
	#
	# button2
	#
    $button2.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$button2.Location = New-Object System.Drawing.Point(550,250)
	$button2.Name = "button2"
	$button2.Size = New-Object System.Drawing.Size(200,50)
	$button2.TabIndex = 3
	$button2.Text = "Cancel"
	$button2.UseVisualStyleBackColor = $True
	$button2.Add_Click({
    $Form1.DialogResult = "Cancel"
    $Form1.close()
    })
           
    #$Form.Controls.Add($CancelButton)
    #
	# combobox1
	#
	$combobox1.DataBindings.DefaultDataSourceUpdateMode = [System.Windows.Forms.DataSourceUpdateMode]::OnValidation 
	$combobox1.FormattingEnabled = $True
	$combobox1.Location = New-Object System.Drawing.Point(40,150)
	$combobox1.Name = "combobox1"
	$combobox1.Size = New-Object System.Drawing.Size(800,90)
	$combobox1.TabIndex = 0
	#endregion Start Form

	#Save the initial state of the form
	$InitialFormWindowState = $form1.WindowState
	#Init the OnLoad event to correct the initial state of the form
	$form1.add_Load($Form_StateCorrection_Load)
	#Show the Form
	return $form1.ShowDialog()

} #End Function

#region StandardFramework
Set-Location $KworkingDir
    
. .\WriteLog.ps1
$Domain = $env:USERDOMAIN
$MachineName = $env:COMPUTERNAME
$GetProcName = Get-PSCallStack
$procname = $GetProcname.Command
$Customer = $MachineGroep.Split(“.”)[2]

$logvar = New-Object -TypeName PSObject -Property @{
    'Domain' = $Domain 
    'MachineName' = $MachineName
    'procname' = $procname
    'Customer' = $Customer
    'Operator'= $Operator
    'TDNumber'= $TDNumber
}

remove-item "$KworkingDir\ProcedureLog.log" -Force -ErrorAction SilentlyContinue
#endregion StandardFramework
    
#region Start log
    f_New-Log -logvar $logvar -status 'Start' -LogDir $KworkingDir -Message "Title:`'$($Procname)`'Script"
#endregion Start log

#region start Call OnApplicationLoad to initialize
if(OnApplicationLoad -eq $true)
{
	#Create the form
	GenerateForm | Out-Null
	#Perform cleanup
	OnApplicationExit
}
#endregion OnApplicationLoad to initialize


#region end log
        f_New-Log -logvar $logvar -status 'Info' -LogDir $KworkingDir -Message "END Title:`'$($Procname)`'Script"
#endregion End Log