# Script to provision the Auzure Bastion VM for the project for a web app
#
# Pls specify ssh pub key file in $vmsshpub !!
#

# Params
$_project='azure'
$environ='demo'
$app='bastion'
$envfile = "${_project}-${environ}_env.ps1"
if (! (Test-Path $envfile)) {
  "ERROR - no env file $envfile found !"
  exit 1
}
. "./$envfile"

$vm
$vmpip="${vm}-pip"
$vmsshpub = '.\azure_kw.pub'

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

# Create a network security group
$networkSg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $whatresgroup -Name $vmnsg
if (! $networkSg) {
$networkSg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $whatresgroup -Location $loc `
  -Name $vmnsg
}

# Public access via SSH

# Create an inbound network security group rule for port 3389
$nsgRulessh = Get-AzureRmNetworkSecurityRuleConfig -Name $vmnsgrule1 -NetworkSecurityGroup $networkSg
if (! $nsgRulessh) {
$nsgRulessh = New-AzureRmNetworkSecurityRuleConfig -Name $vmnsgrule1 -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 22 -Access Allow
}

# Add the rules
if ($networkSg) {
   $networkSg.SecurityRules=$nsgRulessh
   $networkSg | Set-AzureRmNetworkSecurityGroup
}

#-"-----------------------------------------------------------------------------------------"
#-$networkSg
#-"-----------------------------------------------------------------------------------------"

# Create a public IP address and specify a DNS name
$pIp = New-AzureRmPublicIpAddress -ResourceGroupName $whatresgroup -Location $loc `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name $vmpip

$vmnicip = '10.0.2.100'

### Add pIp/vmnicip & NSG to its NIC $vmnic
# Get the network interfaces created for the VMs in the current VNet and Subnet
$backendNic1 = Get-AzureRmNetworkInterface -Name $vmnic -ResourceGroupName $whatresgroup
if (! $backendNic1) {
  # Create it please
  $backendNic1 = New-AzureRmNetworkInterface -ResourceGroupName $whatresgroup -Name $vmnic -Location $loc -PublicIpAddress $pIp -PrivateIpAddress $vmnicip -Subnet $backendSubnet
}
#-$backendNic1

$backendNic1.NetworkSecurityGroup=$networkSg
$backendNic1 | Set-AzureRmNetworkInterface

$appVm1 = Get-AzureRmVM -ResourceGroupName $whatresgroup -Name $vm
if (! $appVm1) {

  # Definer user name and blank password
  $securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
  $cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

  ? Use a much smaller VM size
  $vmsize='Standard_B2S'

  # Create a virtual machine configuration
  $vmConfig = New-AzureRmVMConfig -VMName $vm -VMSize $vmsize | `
  Set-AzureRmVMOperatingSystem -Linux -ComputerName $vm -Credential $cred -DisablePasswordAuthentication | `
  Set-AzureRmVMSourceImage -PublisherName Canonical -Offer UbuntuServer -Skus 14.04.2-LTS -Version latest | `
  Add-AzureRmVMNetworkInterface -Id $backendNic1.Id
  
  # Configure SSH Keys
  $sshPublicKey = Get-Content $vmsshpub
  Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"
  
  # Creeate the VM
  New-AzureRmVM -ResourceGroupName $whatresgroup -Location $loc -VM $vmConfig

}

exit 0
#
