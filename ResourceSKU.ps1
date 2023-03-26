Param(
    [Parameter(
		Mandatory=$false,
		HelpMessage="Specific Subscriptions it needs to look up for"
		)]
        [string[]]
    	$Targetsubscriptions,
	[Parameter(
		Mandatory=$false,
		HelpMessage="Specific ResourceType it needs to look up for"
		)]
        [string[]]
    	$resourceType,
	[Parameter(
		Mandatory=$false,
        HelpMessage="Location or Region it needs to look up for"
		)]
        [string[]]
    	$location,
    [Parameter(
		Mandatory=$false,
        HelpMessage="Name of the Resource SKU it needs to look up for"
		)]
        [string[]]
    	$skuName
)

$ErrorActionPreference = 'SilentlyContinue'

function AZConnect {
    Connect-AzAccount
}

function GetSkuRecords {
    param(
        [Parameter(
		Mandatory=$false
		)]
    	$Subscription,
	[Parameter(
		Mandatory=$false
		)]
    	$resourceType,
	[Parameter(
		Mandatory=$false
		)]
    	$location,
    [Parameter(
		Mandatory=$false
		)]
    	$skuName,
    [Parameter(
		Mandatory=$true
		)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[System.Object]]       
        $ResourceItemArray
    )

    #region command-line built up and execution    
    $cmd2invoke = '$resSkus = Get-AzComputeResourceSku';
    $resourceType2Add = $null
    $location2Add = $null
    $skuName2Add = $null

    if ([string]::IsNullOrEmpty($resourceType)) { **Write-Host ("resourceType was not passed as an argument")** }
    else{
        $resourceType2Add = '$_.ResourceType.Equals("' + "$($resourceType)" + '")'
    }
    if ([string]::IsNullOrEmpty($location)) { **Write-Host ("location was not passed as an argument")** }
    else{
        $location2Add = '$_.LocationInfo.Location.Equals("' + "$($location)" + '")'
    }
    if ([string]::IsNullOrEmpty($skuName)) { **Write-Host ("skuName was not passed as an argument")** }
    else{
        $skuName2Add = '$_.Name.Equals("' + "$($skuName)" + '")'
    }

    if ($resourceType2Add -or $location2Add -or $skuName2Add)
    {
        $firstArgs = $false
        $cmd2invoke += " | Where-Object {"
        if ($resourceType2Add)
        {
            $firstArgs = $true
            $cmd2invoke += $resourceType2Add
        }
        if ($location2Add -and $firstArgs)
        {
            $cmd2invoke += " -and " + $location2Add
        }
        else {
            $firstArgs = $true
            $cmd2invoke += $location2Add
        }
        if ($skuName2Add -and $firstArgs)
        {
            $cmd2invoke += " -and " + $skuName2Add
        }
        else {
            $cmd2invoke += $skuName2Add
        }
        $cmd2invoke += "}"
    }

    #Write-Host $cmd2invoke

    $sript2Run = {
        Import-Module Az.Compute;
        Invoke-Expression $cmd2invoke
        $resSkus
    }
    $scriptBlock = [ScriptBlock]::Create($sript2Run)
    #endregion

    $resSkus = Invoke-Command -ScriptBlock $scriptBlock

    #Write-Host "Total Resources Found: " $resSkus.Count.ToString()
    
    #We will have each line item for each unique record so that user can filter it later based on design requirement for AZ Resiliency
    foreach ($resSKU in $resSkus){
        $ResourceItemInfo = New-Object -TypeName PSCustomObject
        try {
            if(-not ([string]::IsNullOrEmpty($SUBSCRIPTION))) {
                $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "SUBSCRIPTION" -Value $SUBSCRIPTION
            }

            $ResourceType = ""
            if(-not ([string]::IsNullOrEmpty($resSKU.ResourceType))) {
                $ResourceType = $resSKU.ResourceType                
            }
            $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceType" -Value $ResourceType

            $ResourceSKUNAME = ""
            if(-not ([string]::IsNullOrEmpty($resSKU.Name))) {
                $ResourceSKUNAME = $resSKU.Name
            }
            $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceSKUNAME" -Value $ResourceSKUNAME

            $ResourceLocation = ""
            if(-not ([string]::IsNullOrEmpty($resSKU.LocationInfo.Location))) {
                $ResourceLocation = $resSKU.LocationInfo.Location
            }
            $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceLocation" -Value $ResourceLocation

            $ResourceZones = ""
            if ($null -eq $resSKU.LocationInfo.Zones)
            {                
                $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceZones" -Value $ResourceZones
                GetRestrictionRecords -resSKU $resSKU -ResourceItemInfo $ResourceItemInfo -ResourceItemArray $ResourceItemArray
            }
            else {
                foreach($zone in $resSKU.LocationInfo.Zones){
                    if(-not ([string]::IsNullOrEmpty($zone))) {
                        if(-not ($null -eq $ResourceItemInfo.ResourceZones)){
                            $ResourceItemInfoTemp = New-Object -TypeName PSCustomObject
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "SUBSCRIPTION" -Value $SUBSCRIPTION
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceType" -Value $ResourceType
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceSKUNAME" -Value $ResourceSKUNAME
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceLocation" -Value $ResourceLocation
                            $ResourceItemInfo = $ResourceItemInfoTemp
                        }
                        $ResourceZones = $zone
                        $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceZones" -Value $ResourceZones
                        GetRestrictionRecords -resSKU $resSKU -ResourceItemInfo $ResourceItemInfo -ResourceItemArray $ResourceItemArray
                    }
                }
            }
        }
        catch {
            Write-Host "Exception processing item"
            Write-Host "Ran into an issue: $PSItem"
        }
    }
    $ResourceItemArray.ToArray() | Export-Csv -LiteralPath "$pwd\ResSku.csv" -Delimiter ',' -NoTypeInformation
}

function GetRestrictionRecords{
    param(
        [Parameter(
		Mandatory=$true
		)]    
        $resSKU,
        [Parameter(
		Mandatory=$true
		)]
        [PSCustomObject]
        $ResourceItemInfo,
        [Parameter(
		Mandatory=$true
		)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[System.Object]]       
        $ResourceItemArray
        )
    
    $ResourceRestrictionType = ""
    if ($null -eq $resSKU.Restrictions.Type) {
        $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionType" -Value $ResourceRestrictionType
        $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionReasonCode" -Value ""
        $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionLocation" -Value ""
        $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionZones" -Value ""
        $ResourceItemArray.Add($ResourceItemInfo)
    }
    else {
        for ($i = 0; $i -lt $resSKU.Restrictions.Type.Count; $i++) {
            if((-not ($null -eq $ResourceItemInfo.ResourceRestrictionType)) -or (-not ($null -eq $ResourceItemInfo.ResourceRestrictionReasonCode)) -or (-not ($null -eq $ResourceItemInfo.ResourceRestrictionLocation))){
                $ResourceItemInfoTemp = New-Object -TypeName PSCustomObject
                $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "SUBSCRIPTION" -Value $ResourceItemInfo.SUBSCRIPTION
                $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceType" -Value $ResourceItemInfo.ResourceType
                $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceSKUNAME" -Value $ResourceItemInfo.ResourceSKUNAME
                $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceLocation" -Value $ResourceItemInfo.ResourceLocation
                $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceZones" -Value $ResourceItemInfo.ResourceZones                
                $ResourceItemInfo = $ResourceItemInfoTemp
            }
            $ResourceRestrictionType = $($resSKU.Restrictions.Type[$i])
            $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionType" -Value $ResourceRestrictionType
            $ResourceRestrictionReasonCode = $($resSKU.Restrictions.ReasonCode[$i])
            $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionReasonCode" -Value $ResourceRestrictionReasonCode
            $ResourceRestrictionLocation = $($resSKU.Restrictions.RestrictionInfo[$i].Locations[0])
            $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionLocation" -Value $ResourceRestrictionLocation
            if($ResourceRestrictionType -eq "zone"){
                for ($j = 0; $j -lt $resSKU.Restrictions.RestrictionInfo[$i].Zones.Count; $j++) {
                    if (-not ($null -eq $resSKU.Restrictions.RestrictionInfo[$i].Zones[$j])) {
                        if(-not ($null -eq $ResourceItemInfo.ResourceRestrictionZones)){
                            $ResourceItemInfoTemp = New-Object -TypeName PSCustomObject
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "SUBSCRIPTION" -Value $ResourceItemInfo.SUBSCRIPTION
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceType" -Value $ResourceItemInfo.ResourceType
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceSKUNAME" -Value $ResourceItemInfo.ResourceSKUNAME
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceLocation" -Value $ResourceItemInfo.ResourceLocation
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceZones" -Value $ResourceItemInfo.ResourceZones                
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionType" -Value $ResourceRestrictionType
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionReasonCode" -Value $ResourceRestrictionReasonCode
                            $ResourceItemInfoTemp | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionLocation" -Value $ResourceRestrictionLocation
                            $ResourceItemInfo = $ResourceItemInfoTemp             
                        }
                        $ResourceRestrictionZones = $($resSKU.Restrictions.RestrictionInfo[$i].Zones[$j])                        
                        $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionZones" -Value $ResourceRestrictionZones
                        $ResourceItemArray.Add($ResourceItemInfo)
                    }                    
                }
            }
            else {
                #Since the restriction is at location and not zone this would be Not Applicable (NA)
                $ResourceItemInfo | Add-Member -MemberType NoteProperty -Name "ResourceRestrictionZones" -Value "NA"
                $ResourceItemArray.Add($ResourceItemInfo)
            }                     
        }
    }
}

$SubId = $null
$azContext = Get-AzContext
If (!($azContext)) {
    AZConnect    
}
else {
    $SubId = (Get-AzContext).Subscription.Id
}

$ResourceItemArray = New-Object -TypeName System.Collections.Generic.List[System.Object]

if ($null -eq $Targetsubscriptions){
    #no subscriptions passed, run for current context default subscription
    Write-Host ("Subscription was not passed as an argument")
    Write-Host "Subscription: " (Get-AzContext).Subscription.ID.ToString()
    GetSkuRecords -Subscription $SubId -resourceType $resourceType -location $location -skuName $skuName -ResourceItemArray $ResourceItemArray
}
else {
    #Iterate for each subscription
    foreach ($Sub in $Targetsubscriptions){
        if(-not ([string]::IsNullOrEmpty($Sub))) {
            Set-AzContext -Subscription $Sub
            Write-Host "Subscription: " (Get-AzContext).Subscription.ID
            GetSkuRecords -Subscription $Sub -resourceType $resourceType -location $location -skuName $skuName -ResourceItemArray $ResourceItemArray
        }
    }
}