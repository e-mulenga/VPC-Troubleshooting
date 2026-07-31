# Learning Notes — NACL Ephemeral Ports

## Why NACLs Need BOTH Inbound and Outbound Rules for the Same Connection

NACLs are stateless. Every direction of traffic must be explicitly allowed.

```
Client (browser)                     Server (web server)
Random port: 54321                   Port: 80

Request:  54321 → 80    (inbound to server on port 80)
Response: 80 → 54321    (outbound from server on port 54321... wait, no)
```

Correction — the response is:
- Source port: 80 (the server's port)
- Destination port: 54321 (the client's ephemeral port)

The NACL evaluates OUTBOUND rules based on the DESTINATION port.
Since the destination is port 54321 (ephemeral), the outbound rule
must allow the ephemeral port range, not just port 80.

## The Complete Picture

| Direction | Source Port | Dest Port | Rule Type |
|---|---|---|---|
| Inbound (request) | Ephemeral (client) | 80 (server) | Inbound: allow port 80 |
| Outbound (response) | 80 (server) | Ephemeral (client) | Outbound: allow 1024-65535 |

## Standard Ephemeral Port Ranges by OS

| OS | Ephemeral Range |
|---|---|
| Linux | 32768-60999 |
| Windows | 49152-65535 |
| Older systems | 1024-65535 (safe default) |

Using 1024-65535 covers all common client operating systems.

## Complete VPC Lab Series (All 10 Labs)

| Lab | Bug |
|---|---|
| Lab 01 | Missing IGW route |
| Lab 02 | NACL DENY before ALLOW |
| Lab 03 | SG wrong port (8080 not 80) |
| Lab 04 | No subnet-RT association |
| Lab 05 | DNS hostnames disabled |
| Lab 06 | No NAT Gateway |
| Lab 07 | NAT GW in private subnet |
| Lab 08 | Both peering routes missing |
| Lab 09 | Endpoint on wrong RT |
| **Lab 10** | **NACL outbound missing ephemeral ports** |
