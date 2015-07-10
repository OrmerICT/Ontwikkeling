function f_New-Log {
    [cmdletbinding()]
    param (

        [Parameter(Mandatory=$False)]
        [String[]]$logvar,
        [parameter(mandatory=$true)][validateset('Start','Error','Success','Failure','Info')]
        [string]$Status,
        [Parameter(Mandatory=$False)]
        [string]$Message

    )
    begin {

        $LogFile="D:\ProcedureLog.log"



    }
    process {
      try 
      {

      

          $DateTime = Get-Date -Format 'yyyy-MM-dd hh:mm:ss'


          $Ormlogstring = New-Object -TypeName PSObject -Property @{
            'Date' = $($DateTime.SubString(0,10))

            'Time' = $($DateTime.SubString(11))
            'Operator' = $logvar.Operator
            'Domain' = $logvar.Domain
            'MachineName' = $MachineName
            'Customer'= $logvar.Customer
            'TDNumber'= $logvar.TDNumber
            'Status' = $Status
            'Message' = $Message
            }

          $OrmLogString | Out-File $logFile -Append
          
      }
      catch
      {
          Write-Error -Message 'Unable to generate OrmLog'
      }
    } 
  end
  {
  }
}

