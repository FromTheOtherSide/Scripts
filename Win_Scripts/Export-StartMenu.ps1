

    [CmdletBinding()]
    param (
      [Parameter(Mandatory,Position = 0)]
      [ValidateScript({get-localuser $User})]
      [string]
      $User,
  
      [Parameter(Position = 1)]
      [ValidateScript({$null -eq $Path -or {new-item -type directory -path $Path -whatif}})]
      [string]
      $Path, 
  
      [Parameter(Position = 2)]
      [string]
      $Name
    )


        $Path ??= "D:\Win10.Cofig\Shell\StartMenuBackups\"
        new-item -ItemType Directory -Path $Path

        function Get-FilePath {

            param (
                $Type
            )
        
            if ($Type="RegStartLayout")
            {
                $Ext=.reg
            }
            else
            {
                $Ext=.xml
            }
        
            return "$Path.$Type.${$Name ??= $User}.${Get-Date -Format "yyyy.mm.dd_hh.mm"}.$Ext"
        }
        


        write-host "Exporting Registry Key"
        reg export "HKCU\${Get-LocalUser -Name otherside | Select-Object -Property SID}\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount" {Get-FilePath -Type "RegStartLayout"}
        $
        
        Copy-Item ""
        $Ext="reg"
        Export-StartLayout -Path 


        Start-Process Powershell -Argumentlist '-ExecutionPolicy Bypass -NoProfile -File "C:\script.ps1"' -Verb RunAs

        $Cred = Get-Credential $User 
        Invoke-Command -ScriptBlock {
          Export-StartLayout -Path {Get-FilePath StartLayout} 
        } -Credential $Cred
        
        $Cred = Get-Credential $User 
        Invoke-Command -ScriptBlock {
          Export-StartLayout -Path {Get-FilePath StartLayoutAppID} -UseDesktopApplicationID
        } -Credential $Cred

        if (test-path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml")
          {
            Copy-Item -Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml" -Destination "${env:USERPROFILE}\Desktop\DefaultUser.DefaultLayouts.xml"
            write-host "copied DefaultUser.DefaultLayouts.xml"
          }

        if (test-path -Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml")
          {
            Copy-Item -Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Destination "${env:USERPROFILE}\Desktop\DefaultUser.LayoutModification.xml"
            write-host "copied DefaultUser.LayoutModification.xml"
          }
        
        if (test-path -Path "C:\Users\${User}\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml")
          {
            Copy-Item -Path "C:\Users\${User}\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml" -Destination "${env:USERPROFILE}\Desktop\${User}.LayoutModification.xml"
            write-host "copied ${User}.LayoutModification.xml"
          }
          
        if (test-path -Path "C:\Users\${User}\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml")
          {
            Copy-Item -Path "C:\Users\${User}\AppData\Local\Microsoft\Windows\Shell\DefaultLayouts.xml" -Destination "${env:USERPROFILE}\Desktop\${User}.DefaultLayouts.xml"
            write-host "copied ${User}.DefaultLayouts.xml"
          }