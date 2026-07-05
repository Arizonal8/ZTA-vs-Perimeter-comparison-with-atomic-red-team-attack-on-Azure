# Security Analysis — MITRE ATT&CK Techniques

Security context for each technique used, explaining the real-world threat it represents and which ZTA control provides protection.

## T1110.001 — Brute Force: Password Guessing

**Real-world threat:** Automated credential stuffing against network-exposed services (SMB, RDP, SSH). One of the most common initial access techniques in enterprise breaches.

**How simulated:** `net use \\<IP>\IPC$ /user:<domain>\<user> <password>` — seven password attempts against each domain controller's IPC$ share using a wordlist of commonly-used passwords.

**ZTA control response:** Conditional Access MFA policy (`Require MFA - ZTA Research`) would block authentication even with correct credentials — the attacker would need both the password AND a registered MFA device. The NSG evaluation overhead introduced 22–23 second delays in Runs 1–2 (connection establishment friction).

**Study limitation:** The wordlist did not include the correct account passwords. Authentication-layer controls (Conditional Access) could not therefore be empirically tested — this is a methodological limitation, not an architectural one.

## T1021.002 — Remote Services: SMB/Windows Admin Shares

**Real-world threat:** Post-compromise lateral movement. An attacker who has obtained valid credentials uses SMB to access file shares on other machines, establishing persistence and expanding access across the network.

**How simulated:** `net use \\<FS-IP>\HR_Records /user:<domain>\<user> <password>` — authenticated SMB connection to the HR_Records share on the file server using the domain user account.

**ZTA control response:** NSG rule `block-attacker-to-fs` (priority 220, deny TCP from 10.2.0.0/16 to 10.0.1.20 on port 445) blocks all SMB traffic from the attacker VNet to the ZTA file server at the network layer, before any authentication occurs. Result: `System error 53 — The network path was not found`.

**Why network-layer blocking matters:** The attack was blocked regardless of whether the attacker had valid credentials. Even `adminuser01` / `AdminPass@123` (Domain Admin) could not overcome an NSG deny rule — credentials are irrelevant when the network path is closed.

## T1039 — Data from Network Shared Drive

**Real-world threat:** Data theft from compromised file servers. After establishing lateral movement, attackers copy sensitive files to their own infrastructure.

**How simulated:** `Copy-Item "\\<FS-IP>\HR_Records\document_1.txt" "C:\exfil.txt"` — copy a specific file from the remote share to the attacker machine after establishing the SMB connection.

**ZTA control response:** Same NSG rule as T1021.002 — the SMB path to the file server was closed before `Copy-Item` could execute. Result: `File exfiltrated: False`.

## T1078 — Valid Accounts: ADMIN$ Share

**Real-world threat:** An attacker with stolen administrator credentials accesses the Windows ADMIN$ hidden administrative share, gaining system-level access to the domain controller — a critical step in full domain compromise.

**How simulated:** `net use \\<DC-IP>\ADMIN$ /user:<domain>\adminuser01 AdminPass@123` — authenticated connection to the ADMIN$ share using Domain Admin credentials.

**ZTA control response:** Two controls contributed. JIT access had locked port 445 and 3389 on the domain controller, requiring explicit approval for access. The NSG also evaluated the connection. Run 1 returned `System error 64` (JIT terminated an already-initiated connection), Runs 2–3 returned `System error 53` (NSG blocked before connection established). All three runs were categorically blocked.

## T1530 — Data from Cloud Storage Object

**Real-world threat:** Unauthenticated access to Azure Blob storage containers that have been left with public access enabled — the exact attack pattern exploited in the 2022 BlueBleed breach affecting Microsoft Azure customers.

**How simulated:** `Invoke-WebRequest -Uri "https://sa<name>.blob.core.windows.net/sensitive-documents/document_1.txt"` — unauthenticated HTTP GET to the blob storage endpoint.

**ZTA control response:** `public_network_access_enabled = false` on `saztaresearch01` means all public HTTP requests are rejected at the Azure infrastructure level, before reaching the storage container. Result: `AuthorizationFailure — This request is not authorized to perform this operation`.

**Conventional result:** `saconvresearch01` with `public_network_access_enabled = true` and `allow_nested_items_to_be_public = true` returned HTTP 200 with the full file contents — exactly replicating the BlueBleed vulnerability pattern.
