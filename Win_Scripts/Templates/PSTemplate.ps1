#requires -version 2
<#
.SYNOPSIS
  This script calulates a hash and checks if it matches string input

.DESCRIPTION
  I will add verification methods to this as needed.

.PARAMETER $InputFIle
  The file to be verified

.PARAMETER $Hash
  What the hash should be.

.PARAMETER $Algorithim
  The has algorith to use.

.INPUTS
  The path to the file. 

.OUTPUTS
  Boolean.

.EXAMPLE
  Confirm-Integrity C:\Downloads\file.iso 'EA4EB59FC98CCDC1A898C88D28F496698A5881A491DF0C67D6D09F82736BBF71' md5
    "Confirmed Match"

.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
  
#>
Function Confirm-Integrity {
  [CmdletBinding()]
  param (
    [Parameter(Position = 0, ValueFromPipeline = $true)]
    [ValidateScript({test-path $_})]
    [string]
    $InputFile,

    [Parameter(Position = 0, ValueFromPipeline = $false, )]
    [string]
    $Hash,

    [Parameter()]
    [ValidateSet('md5','sha1','sha128','sha256','sha512')
    [string]
    $Algorithim = 'sha256'
  )
    Try {
      Get-FileHash -Algorithm $Algorithim -OutVariable $Checksum

      Write-Host "The $Algorithim checksum of $InputFile is:"
      Write-Host $Checksum -ForegroundColor 'Magenta' -BackgroundColor 'White'
      Write-Host ''
      if ($Hash -eq $Checksum){
        Write-Host 'The checksums match, the file passed the integrity confirmation.' -ForegroundColor Green
        return $true
      }
      else {
        Write-Host 'The checksums do not match, the file failed the integrity confirmed' -ForegroundColor red
        return $false
      }
      
    }

    Catch {
      $_
      Break
    }
  }
   
}

