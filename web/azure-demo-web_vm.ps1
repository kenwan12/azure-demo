# Script to provision the Auzure VMs for the project for a web app

# Params
$_project='azure'
$environ='demo'
$app='web'
$envfile = "${_project}-${environ}_env.ps1"
if (! (Test-Path $envfile)) {
  "ERROR - no env file $envfile found !"
  exit 1
}
. "./$envfile"

##
#Login-AzureRmAccount
Get-AzureRmSubscription
Select-AzureRmSubscription -SubscriptionId $mysubscription

# Resource Group which can span mulitple regions - let's focus on region $loc
$resGroup = Get-AzureRmResourceGroup -Name $whatresgroup -location $loc
if (! $resGroup) { $resGroup = New-AzureRmResourceGroup -Name $whatresgroup -location $loc }

# VNet
$vNet = Get-AzureRmVirtualNetwork -Name $whatvnet -ResourceGroupName $whatresgroup
if (! $vNet) { $vNet = New-AzureRmvirtualNetwork -Name $whatvnet -ResourceGroupName $whatresgroup -AddressPrefix $vnetcidr }
#-$vNet

# Subnet
$backendSubnet = Get-AzureRmVirtualNetworkSubnetConfig -Name $whatsubnet -VirtualNetwork $vNet
if (! $backendSubnet) { $backendSubnet = New-AzureRmVirtualNetworkSubnetConfig -Name $whatsubnet -AddressPrefix $snetcidr }
#-$backendSubnet

$vmnsg = "${vm}-nsg"
$vmnsgrule1 = "${vm}-nsg-rule1"
$vmnsgrule2 = "${vm}-nsg-rule2"

# Create a network security group
$networkSg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $whatresgroup -Name $vmnsg
if (! $networkSg) {
$networkSg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $whatresgroup -Location $loc `
  -Name $vmnsg
}

# No public access - have to access RDP via a Bastion host !
# Create an inbound network security group rule for port 3389
$nsgRulerdp = Get-AzureRmNetworkSecurityRuleConfig -Name $vmnsgrule1 -NetworkSecurityGroup $networkSg
if (! $nsgRulerdp) {
$nsgRulerdp = New-AzureRmNetworkSecurityRuleConfig -Name $vmnsgrule1 -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow
}

# Create an inbound network security group rule for port 80
$nsgRuleweb = Get-AzureRmNetworkSecurityRuleConfig -Name $vmnsgrule2 -NetworkSecurityGroup $networkSg
if (! $nsgRuleweb) {
$nsgRuleweb = New-AzureRmNetworkSecurityRuleConfig -Name $vmnsgrule2 -Protocol Tcp `
  -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 80 -Access Allow
}

# Add the rules
if ($networkSg) {
   $networkSg.SecurityRules=$nsgRulerdp,$nsgRuleweb
   $networkSg | Set-AzureRmNetworkSecurityGroup
}

#-"-----------------------------------------------------------------------------------------"
#-$networkSg
#-"-----------------------------------------------------------------------------------------"

### Add this NSG to both backendNics

# Get the network interfaces created for the VMs in the current VNet and Subnet
$backendNic1 = Get-AzureRmNetworkInterface -Name $vm1nic -ResourceGroupName $whatresgroup
if (! $backendNic1) {
  'ERROR - no backendNic1 found !' 
  exit 1
}

#$backendNic2 = Get-AzureRmNetworkInterface -Name $vm2nic -ResourceGroupName $whatresgroup
#if (! $backendNic2) {
#  'ERROR - no backendNic2 found !' 
#  exit 1
#}

#-$backendNic1
$backendNic1.NetworkSecurityGroup=$networkSg
$backendNic1 | Set-AzureRmNetworkInterface

#$backendNic2.NetworkSecurityGroup=$networkSg
#$backendNic2 | Set-AzureRmNetworkInterface
#


$appVm1 = Get-AzureRmVM -ResourceGroupName $whatresgroup -Name $vm1
$appVm2 = Get-AzureRmVM -ResourceGroupName $whatresgroup -Name $vm2
if (!$appVm1 -Or !$appVm2) {
  # Define a credential object
  $cred = Get-Credential
  $cred
}

$vmsize='Standard_DS2'
# Create vm1 virtual machine configuration
if (!$appVm1) {
  $vm1Config = New-AzureRmVMConfig -VMName $vm1 -VMSize $vmsize | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vm1 -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $backendNic1.Id
#-  $vm1Config
  New-AzureRmVM -ResourceGroupName $whatresgroup -Location $loc -VM $vm1Config
}

# Create vm2 virtual machine configuration
##if (!$appVm2) {
##  $vm2Config = New-AzureRmVMConfig -VMName $vm2 -VMSize $vmsize | `
##    Set-AzureRmVMOperatingSystem -Windows -ComputerName $vm2 -Credential $cred | `
##    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
##    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $backendNic2.Id
##  New-AzureRmVM -ResourceGroupName $whatresgroup -Location $loc -VM $vm2Config
##}

exit 0
#
