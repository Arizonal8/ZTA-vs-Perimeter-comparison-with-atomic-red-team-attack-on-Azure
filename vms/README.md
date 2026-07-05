# Virtual Machines

Per-VM configuration commands and screenshots for all five machines in the experiment.

## VM Inventory

| Folder | VM | IP | Role | Screenshots |
|---|---|---|---|---|
| `dc-zta/` | `vm-dc-zta` | `10.0.1.10` | ZTA Domain Controller | 2 |
| `fs-zta/` | `vm-fs-zta` | `10.0.1.20` | ZTA File Server | 1 |
| `dc-conventional/` | `vm-dc-conventional` | `10.1.1.10` | Conventional DC | 2 |
| `fs-conventional/` | `vm-fs-conventional` | `10.1.1.20` | Conventional File Server | 1 |
| `attacker-vm/` | `vm-attacker` | `10.2.1.4` + public | Attack Platform | 4 |

## Configuration Order

1. `dc-zta/` and `dc-conventional/` — promote to DC, create test accounts
2. `fs-zta/` and `fs-conventional/` — domain-join, create SMB shares
3. `attacker-vm/` — install Atomic Red Team, verify connectivity

## Shared Credentials

All VMs use the admin credentials set in `../terraform/terraform.tfvars`. Domain test accounts (`testuser01` / `UserPass@123`, `adminuser01` / `AdminPass@123`) are created by the DC setup commands and are deliberately identical across both environments.
