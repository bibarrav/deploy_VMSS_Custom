# Deploy Custom Virtual Machine Scale Set

## Quick Start

This template is intended to be deployed into pre-existing infrastructure.  Please review the entirety of this markdown file for full details.

[<img src="https://azuredeploy.net/AzureGov.png"/>](https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fusri%2Fdeploy_VMSS_Custom%2Fmaster%2Ftemplate.json)

## Details

This deployment template deploys a customized virtual machine scale set based on Windows Server 2016 with the following attributes:

* Deploys utilizing custom image, template assumes IIS is pre-installed though it can be modified for any application by modifiying the configVMSS.ps1 file.
* Auto scaling enabled
  * Scales up by 2 instances when CPU % Utilization is > 70% over 10 minute duration
  * Scales down by 1 instance when CPU & Utilization is < 30% over 10 minute duration
  * Maintains a miniumum of 2 instances at all times, Maximum of 20 instances
* Enables graceful scale-in ([termination events](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-terminate-notification)) operations via the Azure Metadata Service
* Utilizes multiple extensions
  * Customer script extension which configures IIS and enables termination event actions
    * **During scale-in operations, termination events result in the instance being un-joined from Active Directory and any required custom code executed.   This is intended to allow for graceful scale-in operations.**
  * Joins the specified Active Directory domain during initial deployment and also during all scale-up actions.

## Pre-Requisites

This template assumes that the Virtual Machin Scale Set (VMSS) is being deployed into existing infrastructure and that no internet access is permitted.  Please ensure the following is in place prior to deploying:

* Active Directory - The VMSS instances will attempt to join the local Active Directory domain, so one must be avaliable and accessible from the subnet where the VMSS is deployed.
* Artifact Storage Account - A storage account must be avaliable with an ACL applied to allow traffic from the subnet where the VMSS is deployed.
  * A blob container must be created in the storage account with an Access Policy of "Blob".  This will allow the VMSS instances from the VMSS subnet to access the blobs directly.  When configured in this fashion, no access is permitted to the storage account except from the specified subnet.
  * Upload configVMSS.ps1 & terminateInstance.ps1 to the blob container
  * Don't forget to update the template parameter "fileURI" and configVMSS.ps1 with the appropriate storage account name and blob container name.
* VMSS Subnet:  Please enable the VNET Service Endpoint for "Azure Storage" within the virtual network that houses your VMSS Subnet.
  * This allows VMSS instances to communicate directly to the storage account hosting your PowerShell scripts from private IP space without the need for network address translation

## Additional Resources

Learn all about some of the technologies utilized as part of this template deployment.

* [Virtual Machine Scale Sets](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/)
* [Virtual Machine Extensions](https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/features-windows)
* [Extension Sequencing in VMSS](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-extension-sequencing)
* [Autoscale in Virtual Machine Scale Sets](https://docs.microsoft.com/en-us/azure/virtual-machine-scale-sets/virtual-machine-scale-sets-autoscale-overview)
* [Azure Instance Metadata Service](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/instance-metadata-service)

## NOTICE/WARNING

* This template is explicitly designed for a lab/classroom environment and is intended to offer a way to move forward by allowing you to import the code and make it your own, fully compliant with the organizations security controls which you represent.

## Contributing

This project welcomes contributions and suggestions.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) with any additional questions or comments.
