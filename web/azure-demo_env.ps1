#
# Parameters for $_project-$environ-$app (default is azure-demo-web) application
#

# SubscriptionName 'Free Trial'
if (! ($mysubsription)) {
  $mysubscription = '...'
}
if (! ($loc)) {
  $loc = "East US"
}
if (! ($_project)) {
  $_project = 'azure'
}
if (! ($environ)) {
  $environ = 'demo'
}
if (!($app)) {
  $app = 'web'
}
if (! ($vnetcidr)) {
  $vnetcidr = '10.0.0.0/16'
}
if (! ($snetcidr)) {
  $snetcidr = '10.0.2.0/24'
}

$whatresgroup = "$_project-rg-$environ"
$whatvnet = "$whatresgroup-vnet"
$whatsubnet = "$whatresgroup-snet"
$xlb = "$whatresgroup-xlb-$app"
$xlbpip = "$xlb-pip"
$xlbfeip = "$xlb-feip"
$xlbbe = "$xlb-be"
$xlbdname = "$_project-$environ-$app"
$xlbproto = 'TCP'
$xlbfep = 80
$xlbbep = 80
$xlbprobe = "$xlb-probe"
$xlbprobep = 80
$xlbprobeproto = 'HTTP'
$xlbprobepath = '/'
$xlbprobeint = 15
$xlbprobecount = 2
$xlbrule = "$xlb-rule"

$xlbnatproto = 'TCP'
$xlbnat1 = "$xlb-nat1"
$xlbnat1fep = 3441
$xlbnat1bep = 3389
$xlbnat2 = "$xlb-nat2"
$xlbnat2fep = 3442
$xlbnat2bep = 3389

# VMs
$vm = "$environ-$app"
$vm1 = "$environ-${app}1"
$vm2 = "$environ-${app}2"
$vmnic = "${vm}-nic"
$vm1nic = "${vm}1-nic"
$vm1nicip = '10.0.2.6'
$vm2nic = "${vm}2-nic"
$vm2nicip = '10.0.2.7'

#
