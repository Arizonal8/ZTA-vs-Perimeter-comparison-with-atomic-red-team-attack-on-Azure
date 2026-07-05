#!/bin/bash
# ZTA Research Infrastructure Deployment
# Sheffield Hallam University — Arinze Ihekweme 2026
# Run this from the Ubuntu research host after terraform apply

================================================================
FILE 1 — UBUNTU TERMINAL
Infrastructure Build and Deployment Commands
Sheffield Hallam University · MSc Dissertation 2026
================================================================

----------------------------------------------------------------
SECTION 1 — AZURE LOGIN AND SUBSCRIPTION SETUP
----------------------------------------------------------------

# Clear cached credentials
az logout
rm -rf ~/.azure

# Login as internal tenant account
az login --tenant arizaylab.tech

# Set correct subscription
az account set --subscription "d2baea97-676b-4bde-acc8-351170ec332a"

# Verify correct account is active
az account show

# Register required resource providers
az provider register --namespace Microsoft.Resources
az provider register --namespace Microsoft.Compute
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.Storage
az provider register --namespace Microsoft.Security
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.SecurityInsights

# Verify providers registered
az provider show --namespace Microsoft.Resources --query "registrationState"
az provider show --namespace Microsoft.Compute --query "registrationState"

----------------------------------------------------------------
SECTION 2 — TERRAFORM INITIALISE AND DEPLOY
----------------------------------------------------------------

cd ~/Desktop/Dissertation

# Initialise Terraform
terraform init

# Validate configuration files
terraform validate

# Preview resources to be created
terraform plan

# Deploy all 37 resources
terraform apply

# View all output values (IPs, workspace names)
terraform output

----------------------------------------------------------------
SECTION 3 — VERIFY DEPLOYMENT IN AZURE CLI
----------------------------------------------------------------

# List all resource groups
az group list --output table

# List all VMs and their power state
az vm list --show-details --query "[].{Name:name, Status:powerState, RG:resourceGroup}" --output table

# List all resources in each resource group
az resource list --resource-group rg-zta-environment --output table
az resource list --resource-group rg-conventional-environment --output table
az resource list --resource-group rg-attacker-vm --output table

----------------------------------------------------------------
SECTION 4 — VM START AND STOP COMMANDS
----------------------------------------------------------------

# Start all VMs
az vm start --resource-group rg-zta-environment --name vm-dc-zta --no-wait
az vm start --resource-group rg-zta-environment --name vm-fs-zta --no-wait
az vm start --resource-group rg-conventional-environment --name vm-dc-conventional --no-wait
az vm start --resource-group rg-conventional-environment --name vm-fs-conventional --no-wait
az vm start --resource-group rg-attacker-vm --name vm-attacker --no-wait

# Stop all VMs (deallocate to stop billing)
az vm deallocate --resource-group rg-zta-environment --name vm-dc-zta --no-wait
az vm deallocate --resource-group rg-zta-environment --name vm-fs-zta --no-wait
az vm deallocate --resource-group rg-conventional-environment --name vm-dc-conventional --no-wait
az vm deallocate --resource-group rg-conventional-environment --name vm-fs-conventional --no-wait
az vm deallocate --resource-group rg-attacker-vm --name vm-attacker --no-wait

# Check VM status
az vm list --show-details --query "[].{Name:name, Status:powerState}" --output table

----------------------------------------------------------------
SECTION 5 — AZURE MONITOR AGENT INSTALLATION
----------------------------------------------------------------

# Install on ZTA VMs
az vm extension set --resource-group rg-zta-environment --vm-name vm-dc-zta --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --version 1.22 --enable-auto-upgrade true

az vm extension set --resource-group rg-zta-environment --vm-name vm-fs-zta --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --version 1.22 --enable-auto-upgrade true

# Install on Conventional VMs
az vm extension set --resource-group rg-conventional-environment --vm-name vm-dc-conventional --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --version 1.22 --enable-auto-upgrade true

az vm extension set --resource-group rg-conventional-environment --vm-name vm-fs-conventional --name AzureMonitorWindowsAgent --publisher Microsoft.Azure.Monitor --version 1.22 --enable-auto-upgrade true

# Verify agent installed
az vm extension list --resource-group rg-zta-environment --vm-name vm-dc-zta --output table

----------------------------------------------------------------
SECTION 6 — DATA COLLECTION RULE (ZTA)
----------------------------------------------------------------

# List existing DCRs
az monitor data-collection rule list --resource-group rg-zta-environment --output table

# Create ZTA DCR associations
az monitor data-collection rule association create --name "dcr-assoc-dc-zta" --resource "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-zta-environment/providers/Microsoft.Compute/virtualMachines/vm-dc-zta" --rule-id "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-zta-environment/providers/Microsoft.Insights/dataCollectionRules/dcr-zta-research"

az monitor data-collection rule association create --name "dcr-assoc-fs-zta" --resource "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-zta-environment/providers/Microsoft.Compute/virtualMachines/vm-fs-zta" --rule-id "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-zta-environment/providers/Microsoft.Insights/dataCollectionRules/dcr-zta-research"

# Create Conventional DCR associations
az monitor data-collection rule association create --name "dcr-assoc-dc-conv" --resource "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-conventional-environment/providers/Microsoft.Compute/virtualMachines/vm-dc-conventional" --rule-id "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-conventional-environment/providers/Microsoft.Insights/dataCollectionRules/dcr-conventional-research"

az monitor data-collection rule association create --name "dcr-assoc-fs-conv" --resource "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-conventional-environment/providers/Microsoft.Compute/virtualMachines/vm-fs-conventional" --rule-id "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-conventional-environment/providers/Microsoft.Insights/dataCollectionRules/dcr-conventional-research"

----------------------------------------------------------------
SECTION 7 — NSG RULE CONFIGURATION (ZTA)
----------------------------------------------------------------

# Remove permissive attacker rule
az network nsg rule delete --resource-group rg-zta-environment --nsg-name nsg-zta --name allow-attacker-vnet

# Add Bastion access rule (ZTA)
az network nsg rule create --resource-group rg-zta-environment --nsg-name nsg-zta --name allow-bastion --priority 150 --direction Inbound --access Allow --protocol Tcp --source-address-prefix "168.63.129.16" --source-port-range "*" --destination-address-prefix "*" --destination-port-ranges 3389 22

# Allow attacker to reach DC only (for attack simulation)
az network nsg rule create --resource-group rg-zta-environment --nsg-name nsg-zta --name allow-attacker-to-dc-only --priority 200 --direction Inbound --access Allow --protocol Tcp --source-address-prefix "10.2.0.0/16" --source-port-range "*" --destination-address-prefix "10.0.1.10" --destination-port-ranges "3389 445"

# Allow DC to reach FS on SMB
az network nsg rule create --resource-group rg-zta-environment --nsg-name nsg-zta --name allow-dc-to-fs-smb --priority 210 --direction Inbound --access Allow --protocol Tcp --source-address-prefix "10.0.1.10" --source-port-range "*" --destination-address-prefix "10.0.1.20" --destination-port-ranges "445"

# Block attacker from reaching FS on SMB
az network nsg rule create --resource-group rg-zta-environment --nsg-name nsg-zta --name block-attacker-to-fs --priority 220 --direction Inbound --access Deny --protocol Tcp --source-address-prefix "10.2.0.0/16" --source-port-range "*" --destination-address-prefix "10.0.1.20" --destination-port-ranges "445"

# Block attacker from reaching FS on RDP
az network nsg rule create --resource-group rg-zta-environment --nsg-name nsg-zta --name block-attacker-to-fs-rdp --priority 230 --direction Inbound --access Deny --protocol Tcp --source-address-prefix "10.2.0.0/16" --source-port-range "*" --destination-address-prefix "10.0.1.20" --destination-port-ranges "3389"

# Add Bastion access rule (Conventional)
az network nsg rule create --resource-group rg-conventional-environment --nsg-name nsg-conventional --name allow-bastion --priority 150 --direction Inbound --access Allow --protocol Tcp --source-address-prefix "168.63.129.16" --source-port-range "*" --destination-address-prefix "*" --destination-port-ranges 3389 22

# Verify all NSG rules
az network nsg rule list --resource-group rg-zta-environment --nsg-name nsg-zta --output table

----------------------------------------------------------------
SECTION 8 — CONVENTIONAL FILE SERVER SMB SHARES (via run-command)
----------------------------------------------------------------

# Remove old shares
az vm run-command invoke --resource-group rg-conventional-environment --name vm-fs-conventional --command-id RunPowerShellScript --scripts "Remove-SmbShare -Name 'HR_Records' -Force; Remove-SmbShare -Name 'Finance_Reports' -Force; Remove-SmbShare -Name 'Project_Confidential' -Force"

# Recreate shares with domain permissions
az vm run-command invoke --resource-group rg-conventional-environment --name vm-fs-conventional --command-id RunPowerShellScript --scripts "New-SmbShare -Name 'HR_Records' -Path 'C:\Shares\HR_Records' -FullAccess 'CONVRESEARCH\Domain Admins' -ReadAccess 'CONVRESEARCH\Domain Users'; New-SmbShare -Name 'Finance_Reports' -Path 'C:\Shares\Finance_Reports' -FullAccess 'CONVRESEARCH\Domain Admins' -ReadAccess 'CONVRESEARCH\Domain Users'; New-SmbShare -Name 'Project_Confidential' -Path 'C:\Shares\Project_Confidential' -FullAccess 'CONVRESEARCH\Domain Admins' -ReadAccess 'CONVRESEARCH\Domain Users'"

# Verify shares
az vm run-command invoke --resource-group rg-conventional-environment --name vm-fs-conventional --command-id RunPowerShellScript --scripts "Get-SmbShare | Select-Object Name, Path | ConvertTo-Json"

----------------------------------------------------------------
SECTION 9 — BLOB STORAGE FILE UPLOADS
----------------------------------------------------------------

# Assign Storage Blob Data Contributor role
az role assignment create --role "Storage Blob Data Contributor" --assignee "Arinze@arizaylab.tech" --scope "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-conventional-environment/providers/Microsoft.Storage/storageAccounts/saconvresearch01"

az role assignment create --role "Storage Blob Data Contributor" --assignee "Arinze@arizaylab.tech" --scope "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a/resourceGroups/rg-zta-environment/providers/Microsoft.Storage/storageAccounts/saztaresearch01"

# Upload dummy files to conventional storage (bash)
for i in 1 2 3 4 5; do echo "CONFIDENTIAL DUMMY DATA - Document $i" > /tmp/document_$i.txt; az storage blob upload --account-name saconvresearch01 --container-name sensitive-documents --name document_$i.txt --file /tmp/document_$i.txt --auth-mode login; done

# Set container public access for misconfiguration test
az storage container set-permission --account-name saconvresearch01 --name sensitive-documents --public-access blob --account-key $(az storage account keys list --account-name saconvresearch01 --resource-group rg-conventional-environment --query "[0].value" -o tsv)

----------------------------------------------------------------
SECTION 10 — DESTROY ALL RESOURCES
----------------------------------------------------------------

# Re-enable public access on ZTA storage before destroy
az storage account update --resource-group rg-zta-environment --name saztaresearch01 --public-network-access Enabled

# Destroy all Terraform resources
terraform destroy

# If Terraform destroy fails, delete resource groups directly
az group delete --name rg-zta-environment --yes --no-wait
az group delete --name rg-conventional-environment --yes --no-wait
az group delete --name rg-attacker-vm --yes --no-wait

# Verify all resources deleted
az group list --output table
az resource list --output table

================================================================
END OF FILE 1
================================================================
