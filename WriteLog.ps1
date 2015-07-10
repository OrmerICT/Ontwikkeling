﻿function f_New-Log {
    [cmdletbinding()]
    param (
        [Parameter(Mandatory=$False)]
        [PSObject]$logvar,
        [parameter(mandatory=$true)][validateset('Start','Error','Success','Failure','Info')]
        [string]$Status,
        [Parameter(Mandatory=$False)]
        [string]$Message
    )
    $LogFile="C:\kworking\ProcedureLog.log"
    try 
    {
        $DateTime = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'
        $Ormlogstring = '[{0}][{1}][{2}][{3}][{4}][{5}][{6}][{7}][{8}]' -f $($DateTime.SubString(0,10)),$($DateTime.SubString(11)),$logvar.Operator,$logvar.Domain,$Logvar.MachineName,$logvar.Customer,$logvar.TDNumber,$Status,$Message
        $OrmLogString | Out-File $logFile -Append
    }
    catch
    {
        Write-Error -Message 'Unable to generate OrmLog'
    }
}