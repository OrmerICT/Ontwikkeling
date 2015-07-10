[cmdletbinding()]
param ( 
         [parameter(
            Mandatory=$False,
            Position=1
            ) ][string[]]$LogVariable
      )
  #region Begin
    $ServerInstance = 'tcp:hljcmewuql.database.windows.net,1433'
    $Database = 'Temp'
    $UserName = 'OrmerDB@hljcmewuql'
    $Password = 'Welkom2015!'
    $QueryTimeout = 600
    $ConnectionTimeout = 15
  #endregion Begin

    $Connectionstring = "Server = $ServerInstance; 
                         Database = $Database; 
                         User ID= $username; 
                         Password= $Password; 
                         Integrated Security= False;
                         Encrypt= True;
                         Trusted_Connection= False;" 
    try {
        ##########################
        # Open database
        ##########################

        $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
        $SqlConnection.ConnectionString = $Connectionstring
        $Sqlconnection.Open()

        } # End try

    catch {

               Write-Error $_

          } # End Catch


    foreach ($Line in $Logvariable) { 

      $Split = $Line -split '\[' -replace '\]'

      $var = New-Object -TypeName PSObject -Property @{
        'Date' = $split[0]
        'Time' = $Split[1]
        'Operator' = $Split[2]
        'Domain' = $Split[3]
        'MachineName' = $Split[4]
        'Customer' = $Split[5]
        'TDNumber' = $Split[6]
        'Status' = $Split[7]
        'Message' = $Split[8]

         } # end split record to Var

        $Query = "insert into Logging 
                  (Date,Time,Operator,Domain,MachineName,Customer,TDNumber,Status,Message) 
                  values ('$($Var.Date)',
                          '$($Var.Time)',
                          '$($Var.Operator)',
                          '$($Var.Domain)',
                          '$($Var.MachineName)',
                          '$($Var.Customer)',
                          '$($Var.TDNumber)',
                          '$($Var.Status)',  
                          '$($Var.Message)'
                         )"

        try {

            ################################
            # Write Record to database 
            ################################

            $Cmd = New-Object system.Data.SqlClient.SqlCommand($Query,$SqlConnection) 
            $Cmd.CommandTimeout=$QueryTimeout 
            $ds = New-Object system.Data.DataSet 
            $da = New-Object system.Data.SqlClient.SqlDataAdapter($Cmd) 
            [void]$da.fill($ds)
            $ds.Tables[0]

            Write-verbose "Record added"

            } # End Try
        Catch {
                  Write-Error $_
            } #End Catch
 
    } # end foreach


    ######################
    #   Close Database
    ######################

    try {

        # database Interaction

        $Sqlconnection.Close()

        #End :database Interaction

        } #End Try

    Catch {

      Write-Error $_

    } #End Catch