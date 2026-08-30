# Pipeline security gates — policy and control mapping

**Scope:** all repositories deploying to the payments platform.
**Owner:** Information Security.
**Review cycle:** every 6 months, or on change to the scanner rule sets.

---

## 1. Why gates and not reports

A finding that appears in a report is a request. A finding that fails a build is a
control. This document defines which findings are which, and why. Every threshold
below is a risk decision, not a technical default, and Information Security owns it.

The pipeline is also the evidence source. Each run writes a signed record of which
gates passed, on which commit, by which actor, retained for 400 days. That record
is what gets produced at audit, not a screenshot.

---

## 2. Gate definitions

### 2.1 Secret scanning — Gitleaks

| Condition | Action |
|---|---|
| Any verified secret in the diff | **Block.** No exception path in the pipeline. |
| Any secret in git history | **Block** and trigger credential rotation. |
| Match in an allowlisted test fixture path | Pass, logged. |

**Rationale for a zero-threshold gate.** Severity tiering does not apply to
credentials. A committed key is exposed from the moment of the push, and rewriting
history does not un-expose it — rotation is the only remediation. There is no
version of this finding that is acceptable to carry.

**Note on rule coverage.** The default rule set found the AWS key but missed a
plaintext PostgreSQL connection string and a password in a Terraform resource.
Two custom rules in `.gitleaks.toml` raised detection from 1 finding to 3 on the
same code. Tuning the rule set is a recurring control activity, not one-time setup.

### 2.2 Dependency and container scanning — Trivy

| Condition | Action |
|---|---|
| CRITICAL or HIGH with a fix available | **Block.** |
| CRITICAL or HIGH with no fix available | Warn, log, and raise a risk item with a compensating control. |
| MEDIUM or below | Report only. Reviewed at the monthly vulnerability forum. |
| Entry in `.trivyignore` | Pass. Each entry needs a ticket reference and an expiry date. |

**Rationale for `ignore-unfixed`.** Blocking on an unfixable CVE gives a team no
action except to bypass the gate, which trains everyone to bypass gates. Unfixable
findings route to risk acceptance, where they belong.

**Rationale for the base image.** `python:3.9-alpine3.14` in this repo is an
end-of-life base carrying OS-level CVEs the application team cannot patch. Base
image currency is a platform-level control, tracked separately from application
dependencies.

### 2.3 IaC misconfiguration scanning — Checkov

Checkov returned 26 failed checks against 4 resources. Seven of them block:

| Check | Finding | Why it blocks |
|---|---|---|
| `CKV_AWS_16` | RDS not encrypted at rest | Encryption at rest is not retrofittable without a migration. |
| `CKV_AWS_17` | RDS publicly accessible | Direct internet exposure of a payments datastore. |
| `CKV_AWS_24` | Security group allows 0.0.0.0/0 on port 22 | Unrestricted administrative access. |
| `CKV_AWS_53` | S3 block public ACLs disabled | Public access block is present but every setting is `false`. |
| `CKV_AWS_54` | S3 block public policy disabled | As above. |
| `CKV_AWS_55` | S3 ignore public ACLs disabled | As above. |
| `CKV_AWS_56` | S3 restrict public buckets disabled | As above. |

The remaining 19 (versioning, access logging, enhanced monitoring, Multi-AZ,
deletion protection, cross-region replication, lifecycle configuration, IAM
database authentication, performance insights, tag propagation, unrestricted
egress) are reported and tracked, not enforced.

**Rationale for enforcing 7 of 26.** A gate that fails on all 26 gets disabled
within two sprints. The seven above share one property: they are either
irreversible after provisioning or they expose data directly. The other nineteen are
real findings and belong on the backlog, but blocking a release on a missing S3
lifecycle rule spends control credibility on the wrong thing.

This split is reviewed quarterly. Checks move from report to block when the
estate's baseline has caught up, not before.

---

## 3. Exceptions

| Element | Requirement |
|---|---|
| Requested by | Engineering lead of the owning team |
| Approved by | Information Security, plus Head of Payments for anything CRITICAL |
| Maximum duration | 90 days |
| Recorded in | Risk register, with the specific check ID and commit reference |
| On expiry | Gate re-enforces automatically; no silent renewal |

An exception is a documented risk acceptance with an owner and an end date.
Anything else is a bypass.

---

## 4. Control mapping

Indicative mapping. Align with the client's own control catalogue before use.

### ISO/IEC 27001:2022 Annex A

| Gate / activity | Control | How the pipeline evidences it |
|---|---|---|
| Secret scanning | A.5.17 Authentication information | Automated detection of credentials in source; rotation triggered on detection. |
| Secret scanning | A.8.4 Access to source code | Demonstrates source is monitored for embedded access credentials. |
| Dependency scanning | A.8.8 Management of technical vulnerabilities | Continuous identification of known vulnerabilities per build, with defined response thresholds. |
| Container image scanning | A.8.8, A.8.9 Configuration management | Image composition assessed against a known-vulnerability baseline before deployment. |
| IaC scanning | A.8.9 Configuration management | Infrastructure configuration validated against a defined secure baseline pre-provisioning. |
| Encryption checks (`CKV_AWS_16`) | A.8.24 Use of cryptography | Automated enforcement of encryption-at-rest for in-scope data stores. |
| Network and public-exposure checks (`CKV_AWS_17`, `CKV_AWS_24`, `CKV_AWS_53`–`56`) | A.8.20 Networks security, A.8.22 Segregation of networks | Ingress rules validated against policy before provisioning. |
| The pipeline as a whole | A.8.25 Secure development life cycle | Security activities defined and embedded in the development process. |
| Gate definitions in this document | A.8.26 Application security requirements | Security requirements stated, versioned, and enforced. |
| Blocking gates on pull requests | A.8.29 Security testing in development and acceptance | Testing performed at defined points with defined acceptance criteria. |
| Exception process (§3) | A.8.32 Change management | Deviations authorised, time-bound, and recorded. |
| Evidence artefact retention | A.5.36 Compliance with policies, A.8.15 Logging | Per-commit record of control operation retained beyond the audit cycle. |

### DORA — Regulation (EU) 2022/2554

| Gate / activity | Article | Basis |
|---|---|---|
| Gate policy owned and approved by Information Security | Art. 5 — Governance and organisation | Management body accountability for ICT risk; documented, approved control thresholds. |
| The gate set as a defined control layer | Art. 6 — ICT risk management framework | Documented framework element with defined review cycle. |
| Dependency inventory from the scan (SBOM) | Art. 8 — Identification | Contributes to the inventory of ICT assets and dependencies. |
| Secret, IaC, and encryption gates | Art. 9 — Protection and prevention | Preventive controls applied before deployment; encryption and access-control policies enforced automatically. |
| Continuous scanning and code-scanning alerts | Art. 10 — Detection | Prompt detection of anomalous conditions in ICT systems. |
| Scanners running on every commit and weekly | Art. 25 — Testing of ICT tools and systems | Vulnerability assessments and scans as part of the testing programme. |
| Third-party library findings | Art. 28 — General principles (ICT third-party risk) | Supports assessment of risk from externally sourced ICT components. |
| Evidence artefact | Art. 6(5), Art. 13 — Review and learning | Records supporting periodic review of framework effectiveness. |

Detailed requirements for vulnerability management, ICT change management, and
logging sit in the RTS on ICT risk management tools, methods, processes and
policies (Commission Delegated Regulation (EU) 2024/1774). Map to those articles
directly once the client's control catalogue is aligned to the RTS.

---

## 5. What this document does not cover

Static application security testing, dynamic testing, threat modelling, branch
protection and code review enforcement, artefact signing and provenance, and
runtime monitoring. Each needs its own gate definition and mapping.
