# DevSecOps gate demo

A deliberately insecure repo used to demonstrate three pipeline security gates and
the control mapping that makes them auditable.

## What is planted here

| File | Planted defect |
|---|---|
| `app/config.py` | Fake AWS key, plaintext PostgreSQL connection string |
| `requirements.txt` | Four end-of-life Python packages with known CVEs |
| `Dockerfile` | EOL base image (`python:3.9-alpine3.14`), runs as root |
| `infra/main.tf` | Unencrypted public RDS, SSH open to the internet, S3 public access block disabled |

**All credentials in this repo are fake.** Nothing here is a real secret.

## Files that matter

- `.github/workflows/security.yml` — the pipeline
- `.gitleaks.toml` — custom secret rules added after the defaults missed two findings
- `SECURITY-GATES.md` — the policy document and the ISO 27001 / DORA mapping

## Reproducing the scans locally

```bash
gitleaks detect --source . --no-git -c .gitleaks.toml -v
pip-audit -r requirements.txt --no-deps
checkov -d infra --compact
```

## Results from the run that produced SECURITY-GATES.md

| Scanner | Result |
|---|---|
| Gitleaks, default rules | 1 finding |
| Gitleaks, with `.gitleaks.toml` | 3 findings |
| Dependency scan | CVEs across urllib3, PyYAML, Jinja2, idna |
| Checkov | 26 failed checks across 4 resources; 7 configured to block |
