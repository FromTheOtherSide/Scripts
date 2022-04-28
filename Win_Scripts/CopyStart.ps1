
<#
.SYNOPSIS
  <Overview of script>

.DESCRIPTION
  <Brief description of script>

.PARAMETER RegPath
    Registry Key Path

.PARAMETER Destination
    .reg file destination

.PARAMETER Name
    .reg file name    >

.OUTPUTS
  .reg file stored in $Destination

.NOTES
  Version:        1.0
  Author:         <Name>
  Creation Date:  <Date>
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>

Param(
    [Parameter(Mandatory=$true)]
    [string[]]
    $RegPath
    [Parameter(Mandatory=$true]
    [string[]]
    $Actions
)


### Exporting an existing start menu
$Backup="D:\Win10.Cofig\"
$Backup.Shell=$Backup + "Shell\"
$TimeStamp=Get-Date -Format "yyyy.mm.dd_hh.mm"
$Stamp= "." + $env:USERNAME + "." + $TS

#Get UserB credential
$Credential = Get-Credential -UserName
#Start the Job as UserB
$GetProcessJob = Start-Job -ScriptBlock {Get-Process Explorer} -Credential $Credential
#Wait until the job is completed
Wait-Job $GetProcessJob
#Get the Job results
$GetProcessResult = Receive-Job -Job $GetProcessJob
#Print the Job results
$GetProcessResult

### Exporting an existing start menu
$Backup="D:\Win10.Cofig\"
$Backup.Shell=$Backup + "Shell\"
$TimeStamp=Get-Date -Format "yyyy.mm.dd_hh.mm"
$Stamp= "." + $env:USERNAME + "." + $TS

#Get UserB credential
$Credential = Get-Credential -UserName
#Start the Job as UserB
$GetProcessJob = Start-Job -ScriptBlock {Get-Process Explorer} -Credential $Credential
#Wait until the job is completed
Wait-Job $GetProcessJob
#Get the Job results
$GetProcessResult = Receive-Job -Job $GetProcessJob
#Print the Job results
$GetProcessResult
```$SLxml=$Backup.Shell +  "StartLayout" + $Stamp + "xml"
```Export-StartLayout -Path $SLxml

```$SLAppIDxml=$Backup.Shell + "StartLayoutAppID" + $Stamp + "xml"
```Export-StartLayout -Path $SLAppIDxml -UseDesktopApplicationID



2. For exporting to existing accounts, the registry key is also required
```$SLreg=$Backup.Shell +  "StartLayout" + $Stamp + "reg"
```reg export HKCU\$SID\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\Cache\DefaultAccount $SLreg




Param(
    [string] $RegPath = 'YourRG',
    [string] $ResourceLocation = 'eastus | westus | etc.',
    [string] $api = 'office365 | dropbox | dynamicscrmonline | etc.',
    [string] $ConnectionName = 'YourConnectionName',
    [string] $subscriptionId = '80d4fe69-xxxx-xxxx-a938-9250f1c8ab03',
    [bool] $createConnection =  $true
)
 #region mini window, made by Scripting Guy Blog
    Function Export-UserStart {
    Add-Type -AssemblyName System.Windows.Forms
 
    $form = New-Object -TypeName System.Windows.Forms.Form -Property @{Width=600;Height=800}
    $web  = New-Object -TypeName System.Windows.Forms.WebBrowser -Property @{Width=580;Height=780;Url=($url -f ($Scope -join "%20")) }
    $DocComp  = {
            $Global:uri = $web.Url.AbsoluteUri
            if ($Global:Uri -match "error=[^&]*|code=[^&]*") {$form.Close() }
    }
    $web.ScriptErrorsSuppressed = $true
    $web.Add_DocumentCompleted($DocComp)
    $form.Controls.Add($web)
    $form.Add_Shown({$form.Activate()})
    $form.ShowDialog() | Out-Null
    }
    #endregion

#login to get an access code 

Login-AzureRmAccount 

#select the subscription

$subscription = Select-AzureRmSubscription -SubscriptionId $subscriptionId

#if the connection wasn't alrady created via a deployment
if($createConnection)
{
    $connection = New-AzureRmResource -Properties @{"api" = @{"id" = "subscriptions/" + $subscriptionId + "/providers/Microsoft.Web/locations/" + $ResourceLocation + "/managedApis/" + $api}; "displayName" = $ConnectionName; } -ResourceName $ConnectionName -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -Location $ResourceLocation -Force
}
#else (meaning the conneciton was created via a deployment) - get the connection
else{
$connection = Get-AzureRmResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -ResourceName $ConnectionName
}
Write-Host "connection status: " $connection.Properties.Statuses[0]

$parameters = @{
	"parameters" = ,@{
	"parameterName"= "token";
	"redirectUrl"= "https://ema1.exp.azure.com/ema/default/authredirect"
	}
}

#get the links needed for consent
$consentResponse = Invoke-AzureRmResourceAction -Action "listConsentLinks" -ResourceId $connection.ResourceId -Parameters $parameters -Force

$url = $consentResponse.Value.Link 

#prompt user to login and grab the code after auth
Show-OAuthWindow -URL $url

$regex = '(code=)(.*)$'
    $code  = ($uri | Select-string -pattern $regex).Matches[0].Groups[2].Value
    Write-output "Received an accessCode: $code"

if (-Not [string]::IsNullOrEmpty($code)) {
	$parameters = @{ }
	$parameters.Add("code", $code)
	# NOTE: errors ignored as this appears to error due to a null response

    #confirm the consent code
	Invoke-AzureRmResourceAction -Action "confirmConsentCode" -ResourceId $connection.ResourceId -Parameters $parameters -Force -ErrorAction Ignore
}

#retrieve the connection
$connection = Get-AzureRmResource -ResourceType "Microsoft.Web/connections" -ResourceGroupName $ResourceGroupName -ResourceName $ConnectionName
Write-Host "connection status now: " $connection.Properties.Statuses[0]

