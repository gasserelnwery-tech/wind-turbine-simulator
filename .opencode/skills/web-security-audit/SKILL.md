---
name: web-security-audit
description: Perform comprehensive security audit for web applications. Use when asked to "audit my site security", "check for vulnerabilities", "OWASP check", "security review", "harden my app", "find security issues", or before deploying to production.
---

# Web Security Audit

## Audit Phases
1. **Reconnaissance** — Identify tech stack (Flutter Web + Firebase), map attack surface
2. **Automated Scanning**:
   - Dependencies: `osv-scanner --lockfile=pubspec.lock` + `flutter pub outdated`
   - Secrets: `gitleaks detect --source .`
   - SAST: `semgrep --config=p/security-audit lib/`
   - DAST: `docker run -t owasp/zap2docker-stable zap-baseline.py -t https://your-app.com`
3. **OWASP Top 10 Manual Testing** — Broken access control, injection, XSS, IDOR, SSRF, crypto failures
4. **Security Headers** — HSTS, X-Frame-Options, X-Content-Type-Options, Permissions-Policy, Referrer-Policy
5. **Framework-Specific**:
   - Flutter Web: No hardcoded secrets, Semantics leak check, Wasm CSP
   - Firebase: Emulator test rules, API key restrictions, non-open Firestore/Storage rules
6. **Reporting** — Severity matrix + remediation plan

## Pre-Deployment Checklist
- [ ] All Critical/High vulnerabilities fixed
- [ ] Dependencies updated, no known CVEs
- [ ] No secrets in code (gitleaks passed)
- [ ] Security headers + CSP configured
- [ ] Firebase Security Rules tested in emulator
- [ ] HTTPS enforced, TLS 1.2+
- [ ] Error messages don't leak info
- [ ] Logging/monitoring configured

## Tools Reference
| Tool | Purpose | Install |
|------|---------|---------|
| `osv-scanner` | Dependency scanning | `go install github.com/google/osv-scanner/v2@latest` |
| `gitleaks` | Secret detection | `brew install gitleaks` |
| `semgrep` | Static analysis | `pip install semgrep` |
| `OWASP ZAP` | Dynamic analysis | `docker pull owasp/zap2docker-stable` |
| `SSL Labs` | TLS testing | https://www.ssllabs.com/ssltest/ |
| `Security Headers` | Headers check | https://securityheaders.com/ |

## Related Skills
`csp-evaluator` (CSP details), `ai-seo` (don't block AI crawlers with security)
