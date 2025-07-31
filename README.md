# Deploying a Web Server in Azure

### Project Overview

This project demonstrates how to deploy a scalable web server infrastructure on Microsoft Azure using Infrastructure as Code (IaC) principles. It includes:

- Creating and assigning an **Azure Policy** to enforce tagging on all resources.
- Building a reusable Linux VM image with **Packer** that hosts a simple website displaying `"Hello, World!"`.
- Provisioning infrastructure using **Terraform**, including:
  - Virtual Network (VNet) and Subnet
  - Public IP Addresses
  - Load Balancer with backend pool and health probe
  - Virtual Machine Scale Set (VMSS) using the custom image
  - Jumpbox VMs for SSH access
  - Network Interfaces, Security Groups, OS & Data disks

The goal is to automate deployment for consistency, security, and scalability.

---

### Getting Started

#### Prerequisites

- Active Azure subscription
- Azure CLI installed and logged in (`az login`)
- Packer installed ([Packer Downloads](https://www.packer.io/downloads))
- Terraform installed ([Terraform Downloads](https://developer.hashicorp.com/terraform/downloads))
- Azure service principal credentials (client ID, client secret, tenant ID, subscription ID)

---

### Instructions for Running Templates

#### Azure Policy

Create the Azure Policy to enforce resource tagging:
### Create the policy definition

```powershell
az policy definition create `
  --name "require-tags" `
  --display-name "Require tags on resources" `
  --description "Deny resource creation if tags are missing" `
  --rules policy.json `
  --mode All
```
### Assign the Policy

Replace `<your-subscription-id>` with your Azure subscription ID:

```powershell
az policy assignment create --name "require-tags-assignment" --policy "require-tags" --scope "/subscriptions/<your-subscription-id>"

```

## Packer Image Creation
Log in to Azure:

```
az login
```
Set environment variables for Azure credentials:

```
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
```
Customize the server1.json Packer template as needed.

## Build the image:

```
packer build server1.json
```
Verify the image exists:

```
az image show --resource-group <Resource-group> --name myPackerImage
```

## Terraform Infrastructure Deployment
Initialize Terraform and download providers:
```
terraform init
```
## Customization Instructions
  To customize this project for your environment and requirements, update the variables defined below.

  Key variables in var file:
  - prefix: Prefix for resource names to avoid conflicts.
  - location: Azure region for deployment.
  - admin_username/admin_password: Credentials for Linux VM.
  - number_of_vms: Number of VMs to create.
  - packer_image_name: Name of the Packer-built image to deploy.
  - resource_group_name: Target Azure resource group.
  - tags: Key-value pairs for resource tagging.
 

    
now run the plan
```
terraform plan
```
### Apply Terraform to create resources:

```
terraform apply 
```
### To destroy resources when no longer needed:
```
terraform destroy 
```

## Notes
Ensure variables in var.tf and terraform.tfvars match, especially list types like address_space and subnet_address_prefixes.

The VM Scale Set uses the custom image created by Packer (myPackerImage).

The load balancer exposes the VMSS instances on the port defined by application_port.

Keep credentials secure; avoid committing secrets to version control.

## Files in this repo:

policy.json - Azure Policy JSON definition to enforce tagging, Prevents users from creating resources without required tags.

server1.json - Packer template to build the Linux VM image, This creates a custom VM image with your software pre-installed, It defines the base image (such as Ubuntu), authentication settings using a service principal.

main1.tf - Terraform main configuration file to provision Azure infrastructure, It creates a virtual network and subnet, a network security group with appropriate rules, a public IP address, and a load balancer with a backend address pool and health probe. It also defines a Virtual Machine Scale Set (VMSS) that uses the Packer-built image to deploy web server instances.

var.tf - Terraform variables definitions, contains all the input variables used throughout the Terraform configuration, enabling customization and reusability of the infrastructure code. Each variable is defined with a name, a description, and an optional default value

## Expected Output
Azure Policy assigned and enforcing tags on resource creation.

A custom VM image named myPackerImage in the specified resource group.

A Virtual Network and Subnet deployed.

A Load Balancer distributing traffic to a Virtual Machine Scale Set running the custom image.

Resources properly tagged as per policy requirements.
