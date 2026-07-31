# 📚 Learning Notes — Network ACLs vs Security Groups

## The Critical Difference: Stateful vs Stateless

| Feature | Security Group | Network ACL |
|---|---|---|
| **Level** | Instance level | Subnet level |
| **State** | Stateful | Stateless |
| **Rule evaluation** | All rules evaluated | Rules evaluated in order |
| **Default action** | Deny all (implicit) | Allow all (default NACL) |
| **Return traffic** | Automatic | Must be explicitly allowed |
| **Rule numbers** | Not applicable | Lower number = higher priority |

---

## NACL Rule Processing — The Golden Rule

> **The first matching rule wins. All subsequent rules are ignored.**

```
Inbound traffic on port 80:

Rule 90  → DENY port 80   ← MATCH FOUND → STOP. Traffic DENIED.
Rule 100 → ALLOW port 80  ← NEVER EVALUATED
```

```
After fix — Rule 90 removed:

Rule 100 → ALLOW port 80  ← MATCH FOUND → STOP. Traffic ALLOWED. ✅
```

---

## NACL Stateless Gotcha — Ephemeral Ports

Because NACLs are **stateless**, return traffic must be explicitly permitted.

When a browser requests your web page:
```
Browser → Port 80 on server   (inbound — you allow this)
Server  → Browser's port ???? (outbound — what port?)
```

The browser uses a **random ephemeral port** (1024–65535) for the response.
You must allow outbound traffic to these ports, or responses never reach the browser.

```hcl
# Required in fixed version — often forgotten!
resource "aws_network_acl_rule" "inbound_allow_ephemeral" {
  rule_number = 200
  protocol    = "tcp"
  rule_action = "allow"
  egress      = false
  cidr_block  = "0.0.0.0/0"
  from_port   = 1024
  to_port     = 65535
}
```

**Security Groups do NOT need this** — they are stateful and automatically
allow return traffic for established connections.

---

## Lab Series Summary — What Each Lab Teaches

| Lab | Missing Element | Layer |
|---|---|---|
| **Lab 01** | Route `0.0.0.0/0 → IGW` missing from route table | Routing |
| **Lab 02** | NACL DENY rule overrides ALLOW due to lower rule number | Filtering |

---

## Security Best Practice

Use NACLs as a **coarse-grained subnet-level filter** and
Security Groups as the **fine-grained instance-level control**.

Do not replicate Security Group rules in NACLs — it creates
confusion and maintenance overhead. Instead:

- **NACLs:** Block known-bad IP ranges, restrict entire subnet traffic classes
- **Security Groups:** Control instance-specific access with precise rules
