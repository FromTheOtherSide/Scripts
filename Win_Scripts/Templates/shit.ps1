#requires -version 2
<#
.SYNOPSIS
  A brief description of the function or script. This keyword can be used only once in each topic.

.DESCRIPTION
  A detailed description of the function or script. This keyword can be used only once in each topic.

.PARAMETER <Parameter_Name>
  The description of a parameter. You can include a .PARAMETER keyword for each parameter in the function or script.

.INPUTS
  The Microsoft .NET Framework types of objects that can be piped to the function or script.
  You can also include a description of the input objects.

.OUTPUTS
  The .NET Framework type of the objects that the cmdlet returns.
  You can also include a description of the returned objects.

.EXAMPLE
  A sample command that uses the function or script, optionally followed by sample output and a description.
  Repeat this keyword for each example.

.LINK
  The name of a related topic. Repeat this keyword for each related topic. This content appears in the Related Links
  section of the Help topic. 
  The .LINK keyword content can also include a Uniform Resource Identifier (URI) to an online version of the same Help topic.
  The online version opens when you use the Online parameter of Get-Help. The URI must begin with "http" or "https".

.COMPONENT
  The name of the technology or feature that the function or script uses, or to which it is related. The Component parameter
  of Get-Help uses this value to filter the search results returned by Get-Help.

.ROLE
  The name of the user role for the help topic. The Role parameter of Get-Help uses this value to filter the search results
  returned by Get-Help.

.FUNCTIONALITY
  The keywords that describe the intended use of the function. The Functionality parameter of Get-Help uses this value to
  filter the search results returned by Get-Help.

.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "SilentlyContinue"

#Dot Source required Function Libraries
#. "C:\Scripts\Functions\Logging_Functions.ps1"

#----------------------------------------------------------[Declarations]----------------------------------------------------------

#Script Version
$ScriptVersion = "1.0"

#Log File Info
#$sLogPath = "C:\Windows\Temp"
#$sLogName = "<script_name>.log"
#$sLogFile = Join-Path -Path $sLogPath -ChildPath $sLogName

#-----------------------------------------------------------[Functions]------------------------------------------------------------


Function FunctionName {    
[CmdletBinding(ConfirmImpact=<String>,
    DefaultParameterSetName=<String>,
    HelpURI=<URI>,
    SupportsPaging=<Boolean>,
    SupportsShouldProcess=<Boolean>,
    PositionalBinding=<Boolean>)]
  param (
    [Parameter(Position = 0, ValueFromPipeline = $true, ValueFromRemainingArguments = $true)]
    [PSObject]
    $Object,

    [Switch]
    $NoNewline,

    [PSObject]
    $Separator,

    [System.ConsoleColor]
    $ForegroundColor,

    [System.ConsoleColor]
    $BackgroundColor
  )
  [string[]]  $UserPrincipalName

  Begin {
    Log-Write -LogPath $sLogFile -LineValue "<description of what is going on>..."
  }
  
  Process {
    Try {
      <code goes here>
    }

    Catch {
      Log-Error -LogPath $sLogFile -ErrorDesc $_.Exception -ExitGracefully $True
      Break
    }
  }
  
  End {
    If ($?) {
      Log-Write -LogPath $sLogFile -LineValue "Completed Successfully."
      Log-Write -LogPath $sLogFile -LineValue " "
    }
  }
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------

#Log-Start -LogPath $sLogPath -LogName $sLogName -ScriptVersion $sScriptVersion
#Script Execution goes here
#Log-Finish -LogPath $sLogFile