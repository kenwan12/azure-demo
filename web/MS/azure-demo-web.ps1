# Script to provision the Auzure resources for a project for a web app
#
# Internet <---> xLB <---> web pool (vm1 + vm2)
#

# Params
$_project='azure'
$environ='demo'
$app='web'
$envfile = "${_project}-${environ}_env.ps1"
if (! (Test-Path $envfile)) {
  "ERROR - no env file $envfile found !"
  exit 1
}
$vmfile = "${_project}-${environ}-${app}_vm.ps1"
if (! (Test-Path $vmfile)) {
  "ERROR - no vm file $vmfile found !"
  exit 1
}

. "./$envfile"

import-module AzureRm
##
###Login-AzureRmAccount
Get-AzureRmSubscription
Select-AzureRmSubscription -SubscriptionId $mysubscription
Get-AzureRmResourceGroup

# Resource Group which can span mulitple regions - let's focus on region $loc
$resGroup = Get-AzureRmResourceGroup -Name $whatresgroup -Location $loc
if (! $resGroup) { $resGroup = New-AzureRmResourceGroup -Name $whatresgroup -location $loc }
#-$resGroup

# VNet
$vNet = Get-AzureRmVirtualNetwork -Name $whatvnet -ResourceGroupName $whatresgroup
if (! $vNet) { $vNet = New-AzureRmvirtualNetwork -Name $whatvnet -ResourceGroupName $whatresgroup -AddressPrefix $vnetcidr }
#-$vNet

# Subnet
$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $whatsubnet -VirtualNetwork $vNet
if (! $backendSubnet) { $backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $whatsubnet -AddressPrefix $snetcidr }
#-$backendSubnet

$publicIp = Get-AzureRmPublicIpAddress -Name $xlbpip -ResourceGroupName $whatresgroup
if (! $publicIp) { $publicIp = New-AzureRmPublicIpAddress -Name $xlbpip -ResourceGroupName $whatresgroup -AllocationMethod Static -DomainNameLabel $xlbdname }
#-$publicIp

$nrpLb = Get-AzureRmLoadBalancer -ResourceGroupName $whatresgroup -Name $xlb
if (! $nrpLb) { $nrpLb = New-AzureRmLoadBalancer -ResourceGroupName $whatresgroup -Name $xlb -Location $loc }
#-$nrpLb

$frontendIp = Get-AzureRmLoadBalancerFrontendIpConfig -LoadBalancer $nrpLb
if (! $frontendIp) { $frontendIp = New-AzureRmLoadBalancerFrontendIpConfig -Name $xlbfeip -PublicIpAddress $publicIp }
#-$frontendIp

# Set up a backend address pool used to receive incoming traffic from frontend IP pool
$beAddresspool = Get-AzureRmLoadBalancerBackendAddressPoolConfig -LoadBalancer $nrpLb
if (! $beAddresspool) { $beAddresspool = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name $xlbbe }
#-$beAddresspool

# Create load balancing rules, NAT rules (SSH/RDP access), probe, and load balancer

# NAT rules Not required - use the Bastion instead
## $inboundNatrule1 = Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $nrpLb
## if (! $inboundNatrule1) { $inboundNatrule1 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name $xlbnat1 -FrontendIpConfiguration $frontendIp -Protocol $xlbnatproto -FrontendPort $xlbnat1fep -BackendPort $xlbnat1bep }
## $inboundNatrule2 = Get-AzureRmLoadBalancerInboundNatRuleConfig -LoadBalancer $nrpLb
## if (! $inboundNatrule2) { $inboundNatrule2 = New-AzureRmLoadBalancerInboundNatRuleConfig -Name $xlbnat2 -FrontendIpConfiguration $frontendIp -Protocol $xlbnatproto -FrontendPort $xlbnat2fep -BackendPort $xlbnat2bep }

$healthProbe = Get-AzureRmLoadBalancerProbeConfig -LoadBalancer $nrpLb
if (! $healthProbe) { $healthProbe = New-AzureRmLoadBalancerProbeConfig -Name $xlbprobe -RequestPath $xlbprobepath -Protocol $xlbprobeproto -Port $xlbprobep -IntervalInSeconds $xlbprobeint -ProbeCount $xlbprobecount }
#-$healthProbe

$lbRule = Get-AzureRmLoadBalancerRuleConfig -LoadBalancer $nrpLb
if (! $lbRule) { $lbRule = New-AzureRmLoadBalancerRuleConfig -Name $xlbrule -FrontendIpConfiguration $frontendIp -BackendAddressPool $beAddresspool -Probe $healthProbe -Protocol $xlbproto -FrontendPort $xlbfep -BackendPort $xlbbep }
#-$lbRule

#-$nrpLb
$nrpLb.FrontendIpConfigurations=$frontendIp
$nrpLb.BackendAddressPools=$beAddresspool
$nrpLb.Probes=$healthProbe
$nrpLb.LoadBalancingRules=$lbRule
$nrpLb | Set-AzureRmLoadBalancer
#-$nrpLb

# Create if needed the network interfaces to use in the current VNet and Subnet
$backendNic1 = Get-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vm1nic -Location $loc
## if (! $backendNic1) { $backendNic1 = New-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vm1nic -Location $loc -PrivateIpAddress $vm1nicip -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrpLb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrpLb.InboundNatRules[0] }
if (! $backendNic1) { $backendNic1 = New-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vm1nic -Location $loc -PrivateIpAddress $vm1nicip -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrpLb.BackendAddressPools[0] }
$backendNic1

$backendNic2 = Get-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vm2nic -Location $loc
## if (! $backendNic2) { $backendNic2 = New-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vm2nic -Location $loc -PrivateIpAddress $vm2nicip -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrpLb.BackendAddressPools[0] -LoadBalancerInboundNatRule $nrpLb.InboundNatRules[1] }
if (! $backendNic2) { $backendNic2 = New-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vm2nic -Location $loc -PrivateIpAddress $vm2nicip -Subnet $backendSubnet -LoadBalancerBackendAddressPool $nrpLb.BackendAddressPools[0] }
$backendNic2

# Attach NICs to the LB nrpLb
if ($backendNic1) {
  $backendNic1.IpConfigurations[0].LoadBalancerBackendAddressPools = $beAddresspool
  Set-AzureRmNetworkInterface -NetworkInterface $backendNic1
}
if ($backendNic2) {
  $backendNic2.IpConfigurations[0].LoadBalancerBackendAddressPools = $beAddresspool
  Set-AzureRmNetworkInterface -NetworkInterface $backendNic2
}

# Use the Add-AzureRmVMNetworkInterface cmdlet to assign the NICs to different VMs - run the $vmfile to create them
& "./$vmfile"

exit 0
#
