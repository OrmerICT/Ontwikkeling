#Basic rules:
## Don't use Write-Host
## Every (!) action requires error handling
## It is prefered to give a parameter an attribute, than to put validation inside the script block.

#Approved Verbs
##Get-Verb

#Prefix
## 2-3 characters

#Naming
##Every word or abbrivation starts with a capital.
##Example: Get-OrmADUser
function Verb-PrefixNoun {
  <#
      .SYNOPSIS
      A synopsis so a short description of what this function does.
      .DESCRIPTION
      The synopsis + a more elaborate description of what this function does, including which
      technologies it leverages, constraints, prereqs, etc.
      .EXAMPLE
      A description of what this example does, followed by the example.

      PS C:\> Verb-PrefixNoun -ComputerName "Server1"
      .EXAMPLE
      A second example, no need to number them. PowerShell does this for you.

      PS C:\> "Server1","Server2" | foreach { Verb-PrefixNoun -ComputerName $_ }
      .NOTES
      Author  : Jeff Wouters
      Version : 0.9
      Company : Ormer ICT
  #>
  #Makes usability of the pipeline and verbose/debug output possible.
  [cmdletbinding(
      DefaultParameterSetName='Computer',
      #The ConfirmImpact attribute is used to set the importance of what a cmdlet 
      #can do, typically based around its ability to destroy data.
      ConfirmImpact='High',
      #Where does the system go to when the -Online parameter is used if 
      #the help is called for this command.
      HelpURI = 'http://www.ormer-ict.nl',
      #Makes the -WhatIf parameter possible.
      SupportsShouldProcess = $true
  )]
  #In case of CmdletBinding, a param block is required... even if it's empty.
  param (
    [parameter(
        #Makes the use of this parameter Mandatory. Negates the option of a default value!
        Mandatory=$true,
        #Makes the value positional:
        #Ver-PrefixNoun Server1 (instead of Verb-PrefixNoun -ComputerName Server1)
        Position=0,
        #Makes input from the pipeline possible:
        #"Server1","Server2" | foreach {Verb-PrefixNoun $_}
        ValueFromPipeline=$true,
        #Makes input from the pipeline by property name possible:
        #Get-ADComputer -Filter * | foreach {Verb-PrefixNoun $_}
        ValueFromPipelineByPropertyName=$true,
        #Sets the parameterset. The use of this parameter excludes the use of 
        #all parameters that are not a member of this parameterset.
        ParameterSetName='Computer'
    )]
    [ValidateNotNullOrEmpty()]
    #Set an alias to the parameter for useability.
    [Alias('Name','Computer')]
    [string[]]$ComputerName,
    [parameter(
        Mandatory=$false,
        Position=1,
        ValueFromPipelineByPropertyName = $true,
        ParameterSetName='Season'
    )]
    #Make sure the value is not $null or ''.
    [ValidateNotNullOrEmpty]
    #Only an item from this set can be the value of the parameter
    [ValidateSet('North','East','South','West')]
    [string[]]$Season = 'East',
    
    #The following sets the parameter mandatory in one parameterset, and optional in the other.
    [parameter(
        Mandatory=$false,
        ParameterSetName='Season'
    )]
    [parameter(
        Mandatory=$true,
        ParameterSetName='Computer'
    )]
    #Checks to make sure the number provided is within a range.
    [ValidateRange(1,10)]
    [int]$Number
  )
  begin {
    #Everything in this block is executed FIRST.
  }
    #You use the syntax on the following line to determine whether or not -WhatIf was specified
    if($PSCmdlet.ShouldProcess($User,"Set Property to '$SomeProperty'")){
        Write-output ("Preparing to Verb-NounPrefix: $SomeProperty on $User")
    }
  process {
    #Everything in this block is executed FOR EACH item.
    
    try {
      #A try block catches all terminating errors inside the block.
      #When a single command has a terminating error, the entire sequence is terminated and the script enters the catch block.
      #So only put in here that 'group' together. In other words, one one fail, the next things should not be executed.
    }
    catch {
      #In the catch block you actually catch the terminating error, which is defined by $_
      #So be aware that $_ is the error and not an item used in a pipeline!
      #So basically this code is executed when an error occurs.
      #Start with putting the following in this block:
      Write-Error $_
      #You can catch specific error types by putting the error class after the catch definition:
      #catch [System.Management.Automation.PSArgumentException] {}
      #}
      #The default is [System.Exception]
      #You can have multiple catch blocks within a single try-catch-finally construct.
    }
    finally {
      #The finally block is executed after the error is catched.
      #This block is mainly used as a 'clean up' section.
      #Note that his code will be executed even if the user stops the script while it is executing code in a try block.
      #Using finally isn't mandatory, but optional.
    }
    
  }
  end {
    #Everything in this block is executed FIRST.
  }
}