# Security Configuration — Infrastructure Deployment

Post-deploy security hardening applied during the infrastructure session, separate from the Terraform-declared configuration.

## Storage Account Public Access Re-Lock (ZTA)

After uploading dummy files to `saztaresearch01`, public access was re-disabled to enforce the ZTA storage posture before attack simulation.

```bash
# Re-enable temporarily for upload
az storage account update \
  --resource-group rg-zta-environment \
  --name saztaresearch01 \
  --public-network-access Enabled

# Upload dummy files
for i in 1 2 3 4 5; do
  echo "CONFIDENTIAL DUMMY DATA - Document $i" > /tmp/document_$i.txt
  az storage blob upload \
    --account-name saztaresearch01 \
    --container-name sensitive-documents \
    --name document_$i.txt \
    --file /tmp/document_$i.txt \
    --auth-mode login
done

# Re-lock — public access disabled
az storage account update \
  --resource-group rg-zta-environment \
  --name saztaresearch01 \
  --public-network-access Disabled

# Verify
az storage account show \
  --resource-group rg-zta-environment \
  --name saztaresearch01 \
  --query "publicNetworkAccess"
```

## NSG Post-Deploy Adjustments (ZTA)

Additional NSG rules applied after Terraform to allow Bastion access while maintaining micro-segmentation.

```bash
# Allow Bastion host to reach VMs on RDP (Azure Bastion service IP)
az network nsg rule create \
  --resource-group rg-zta-environment \
  --nsg-name nsg-zta \
  --name allow-bastion \
  --priority 150 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "168.63.129.16" \
  --source-port-range "*" \
  --destination-address-prefix "*" \
  --destination-port-ranges 3389 22

# Verify all NSG rules — ZTA environment
az network nsg rule list \
  --resource-group rg-zta-environment \
  --nsg-name nsg-zta \
  --output table
```

## Role Assignment — Blob Data Contributor

Required temporarily for the blob upload commands, then removed after data collection.

```bash
# Assign — allows CLI to upload to both storage accounts
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee "Arinze@arizaylab.tech" \
  --scope "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a"

# Upload dummy data to CONVENTIONAL storage (public access enabled — intentional)
for i in 1 2 3 4 5; do
  echo "CONFIDENTIAL DUMMY DATA - Document $i" > /tmp/conv_doc_$i.txt
  az storage blob upload \
    --account-name saconvresearch01 \
    --container-name sensitive-documents \
    --name document_$i.txt \
    --file /tmp/conv_doc_$i.txt \
    --auth-mode login
done

# Remove role after data upload — principle of least privilege
az role assignment delete \
  --role "Storage Blob Data Contributor" \
  --assignee "Arinze@arizaylab.tech" \
  --scope "/subscriptions/d2baea97-676b-4bde-acc8-351170ec332a"
```

## Teardown — Security Cleanup Before Resource Deletion

```bash
# Re-enable storage public access before Terraform destroy
# (required to avoid Terraform state conflict on storage deletion)
az storage account update \
  --resource-group rg-zta-environment \
  --name saztaresearch01 \
  --public-network-access Enabled

# Destroy all resources
terraform destroy

# Verify no resource groups remain
az group list --output table
```
