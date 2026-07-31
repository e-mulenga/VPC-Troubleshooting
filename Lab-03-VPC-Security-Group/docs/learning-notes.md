# 📚 Learning Notes — Security Groups

## Security Group Fundamentals

Security Groups act as a **virtual firewall at the instance level**.

| Property | Behaviour |
|---|---|
| **Default inbound** | Deny all (implicit — no rule needed) |
| **Default outbound** | Allow all (default egress rule) |
| **State** | Stateful — return traffic automatically allowed |
| **Rule matching** | ALL rules evaluated — most permissive wins |
| **Rule numbers** | No rule numbers — all rules apply simultaneously |

---

## Security Groups vs NACLs — Side by Side

| Feature | Security Group | Network ACL |
|---|---|---|
| Level | Instance | Subnet |
| State | Stateful | Stateless |
| Default inbound | Deny all | Allow all (default NACL) |
| Rule evaluation | All rules (most permissive wins) | In order (first match wins) |
| Return traffic | Automatic | Must be explicitly allowed |
| Rule numbers | None | Required (lowest first) |

---

## The Port Mismatch Pattern

Port mismatches are one of the most common AWS connectivity issues:

```
Web server listens on: port 80   (HTTP standard)
Security Group allows: port 8080 (alternative HTTP)

Result: Traffic arrives on 80 → no matching SG rule → DENIED
```

**Common port confusion pairs:**

| Intended | Accidentally Used | Service |
|---|---|---|
| 80 | 8080 | HTTP |
| 443 | 8443 | HTTPS |
| 22 | 2222 | SSH |
| 3306 | 33060 | MySQL |
| 5432 | 5433 | PostgreSQL |
| 6379 | 6380 | Redis |

---

## Lab Series — Concepts Covered

| Lab | Bug | Concept |
|---|---|---|
| **Lab 01** | Missing `0.0.0.0/0 → IGW` route | Route tables |
| **Lab 02** | DENY rule (90) before ALLOW rule (100) | NACL ordering |
| **Lab 03** | SG allows port 8080 instead of 80 | Security Group ports |

---

## Systematic Troubleshooting Order

Always work from the **outside in**:

```
1. Is the instance running?
2. Does it have a public IP?
3. Is the IGW attached and routed?
4. Is the subnet associated to the route table?
5. Does the NACL allow the traffic?
6. Does the Security Group allow the correct port?
7. Is the application actually running on that port?
```

Security Groups are Layer 6 — after IGW and NACLs,
before the application layer.
