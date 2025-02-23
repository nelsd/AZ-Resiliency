Param(
	[Parameter(
		Mandatory=$true,
		HelpMessage="Subscription(s) to check against. If multiple subscriptions are there, then please use comma as delimiter without any quotes"
		)]
	    [ValidateNotNullOrEmpty()]
        [string[]]
    	[Alias('Please provide the subscriptions to validate against. If multiple subscriptions are there, then please use comma as delimiter without any quotes')]
	    $Targetsubscriptions, #Mode
	[Parameter(
		Mandatory=$true,
        HelpMessage="Location to validate"
		)]
    	$location,
    [Parameter(
		Mandatory=$false
		)]
    	$Login,
    [Parameter(
		Mandatory=$false,
        HelpMessage="Subscription used as source"
		)]
        [Alias('Please provide the subscription used as the source - (optional)')]	
       $SourceSubscription
)
Function AZConnect {
    Add-AzAccount

}

Function GetAuthHeader{
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    $authHeader = @{
    'Content-Type'='application/json'
    'Authorization'='Bearer ' + $token.AccessToken
    }

    return $authHeader
}

#this is used later for printing all the subscriptions we are comparing against
$global:SubVersus = $null
Function CreateBody{
    $SubIDs = @()
    #looping thru all the subscriptions
    foreach ($Targetsubscription in $Targetsubscriptions)
    {
        $SubIDs += "subscriptions/$Targetsubscription,"
        $global:SubVersus += "$Targetsubscription, "
    }
    #now adding these to the request body
    $body = @{
        'location' = $location
        'subscriptionIds'= $SubIDs     
    }    
    return $body
}

#Cosmetic stuff
write-host ""
write-host ""
write-host "                               _____        __                                " -ForegroundColor Green
write-host "     /\                       |_   _|      / _|                               " -ForegroundColor Yellow
write-host "    /  \    _____   _ _ __ ___  | |  _ __ | |_ _ __ __ _   ___ ___  _ __ ___  " -ForegroundColor Red
write-host "   / /\ \  |_  / | | | '__/ _ \ | | | '_ \|  _| '__/ _' | / __/ _ \| '_ ' _ \ " -ForegroundColor Cyan
write-host "  / ____ \  / /| |_| | | |  __/_| |_| | | | | | | | (_| || (_| (_) | | | | | |" -ForegroundColor DarkCyan
write-host " /_/    \_\/___|\__,_|_|  \___|_____|_| |_|_| |_|  \__,_(_)___\___/|_| |_| |_|" -ForegroundColor Magenta
write-host "     "
write-host " This script validates the Availability Zone mapping between two subscriptions" -ForegroundColor "Green"


$azContext = Get-AzContext

If ($SourceSubscription -and $azContext.Subscription.id -ne $SourceSubscription) {
    Write-Host "  switchting subscription context" -ForegroundColor Yellow
    Set-AzContext -Subscription $SourceSubscription
    $azContext = Get-AzContext
}
If (!($azContext)) {
    $Login = $true
}
If ($Login) {
    AZConnect
}
$Auth=GetAuthHeader
$Target=CreateBody

Write-Host ("  Checking:  " + $azContext.Subscription.id)
Write-host ("  Versus:    " + $global:SubVersus)
write-host ""

$url=("https://management.azure.com/subscriptions/" + $azContext.subscription.id + "/providers/Microsoft.Resources/checkZonePeers/?api-version=2020-01-01")

$Result=Invoke-RestMethod -Method 'Post' -Uri $url -Body ($Target|ConvertTo-Json) -ContentType "application/json" -Headers $Auth

Write-host ("AV Zone peering for subscription " + $azContext.subscription.id + " in " + $location + " is:") -ForegroundColor Yellow
$result.availabilityZonePeers
