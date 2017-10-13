# azure-demo

Demo Web App on Azure


Files:

$ tree .

├── README.md

└── web

    ├── azure-demo-bastion.ps1
    ├── azure-demo-web.ps1
    ├── azure-demo-web_vm.ps1
    └── azure-demo_env.ps1

1 directory, 5 files


Overview:

azure-demo_env.ps1 : Global default parameters to enforce a standard naming convention for Azure resources

azure-demo-web.ps1 : Main script to create under US East, the Resouce Group, VNet, Subnet and the Web App related stack :-
  i.e.
  External Load Balancer plus it rule(s)
  Network Security Group for the Subnet/VMs
  VMs (Windows 2016 running IIS for the web service)

azure-demo-web_vm.ps1 : Script to create the VMs and attach them to the xLB & NSG

azure-demo-bastion.ps1 : Script to create a Bastion Linux host to be used as the JumpBox

