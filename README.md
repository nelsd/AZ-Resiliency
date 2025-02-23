# AZ Resiliency
This Repo has 2 files<br/>
1.> ResourceSKU.ps1<br/>
2.> Check-AzureAZmapping.ps1<br/>

**1.> Resource SKU information in Azure Region and Avaialbility zones via ResourceSKU.ps1**<br/>
**Usage:** <br/>
Below command would generate a csv file in the same folder and all the arguments are optional. Please be aware that it would generate a large file depending upon your subscription and organization if you dont pass any arguments to the below command.<br/>
PS C:\> .\ResourceSKU.ps1 -Targetsubscriptions "SubscriptionID1", "SubscriptionID2" -resourceType "virtualMachines" -skuName "Standard_M128" -location "eastus2"
<br/><br/><br/><br/><br/><br/>

**2.> AZ Peer Mapping information via Check-AzureAZmapping.ps1**</br>
Comparing multiple subscriptions as that's how underlying REST API works which will help with a single REST API call for multiple subscriptions instead of calling this in a loop<br/>
**Prerequisite** <br/>
 This Script calls [CheckZonePeers API](https://learn.microsoft.com/en-us/rest/api/resources/subscriptions/check-zone-peers?tabs=HTTP) API and we need to make sure 'AvailabilityZonePeering' feature is registered for the source subscription before using this REST API OR powershell scripts.
<br/><br/>
PS C:\> az feature register -n AvailabilityZonePeering --namespace Microsoft.Resources <br/>
Once the feature 'AvailabilityZonePeering' is registered, invoking 'az provider register -n Microsoft.Resources' is required to get the change propagated
{
  "id": "/subscriptions/SubscriptionID1/providers/Microsoft.Features/providers/Microsoft.Resources/features/AvailabilityZonePeering",
  "name": "Microsoft.Resources/AvailabilityZonePeering",
  "properties": {
    "state": "Registering"
  },
  "type": "Microsoft.Features/providers/features"
}
<br/><br/>
You can check the status with the below command,<br/>
PS C:\> az feature show -n AvailabilityZonePeering --namespace Microsoft.Resources <br/>
{
  "id": "/subscriptions/SubscriptionID1/providers/Microsoft.Features/providers/Microsoft.Resources/features/AvailabilityZonePeering",
  "name": "Microsoft.Resources/AvailabilityZonePeering",
  "properties": {
    "state": "Registered"
  },
  "type": "Microsoft.Features/providers/features"
}
<br/><br/>
PS C:\>az provider register -n Microsoft.Resources<br/><br/>

**Usage:** <br/>
PS C:\> .\Check-AzureAZmapping.ps1 -Targetsubscriptions SubscriptionID2, SubscriptionID3 -location eastus2 -SourceSubscription SubscriptionID1

 This script validates the Availability Zone mapping between two subscriptions
  Checking:  SubscriptionID1
  Versus:    SubscriptionID2, SubscriptionID3,

AV Zone peering for subscription SubscriptionID1 in eastus2 is: <br/>
availabilityZone&emsp;&emsp;&emsp;peers <br/>
==========&ensp;&emsp;&emsp;&ensp;====<br/>
1&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;{@{subscriptionId=SubscriptionID2; availabilityZone=3}, @{subscriptionId=SubscriptionID3; availabilityZone=1}} <br/>
2&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;{@{subscriptionId=SubscriptionID2; availabilityZone=1}, @{subscriptionId=SubscriptionID3; availabilityZone=2}} <br/>
3&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;{@{subscriptionId=SubscriptionID2; availabilityZone=2}, @{subscriptionId=SubscriptionID3; availabilityZone=3}} <br/>


**NOTE:** <br/>
These Script is developed on an "as-is" basis and this has not been properply tested. Before using it, please perform your own testing.
