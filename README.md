# AZPeerMapping
Comparing multiple subscriptions as that's how underlying REST API works which will help with a single REST API call for multiple subscriptions instead of calling this in a loop

<b>Usage:</b>

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
