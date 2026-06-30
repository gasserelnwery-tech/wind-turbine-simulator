---
name: csp-evaluator
description: "Audit and validate Content Security Policy (CSP) configurations for web applications. Use when asked to 'check my CSP', 'review security headers', 'audit content security policy', 'fix CSP errors', 'harden web security', or when deploying Flutter Web apps to production. Ensures CSP blocks XSS attacks while allowing legitimate app functionality."
---

# CSP Evaluator

## Overview
Content Security Policy (CSP) is an HTTP header that tells browsers which sources of content are allowed to load and execute. A misconfigured CSP can either be too permissive (allows XSS attacks) or too restrictive (breaks legitimate app functionality).

## Process
1. **Extract Current CSP** — From HTML meta tag or HTTP response headers
2. **Check for Dangerous Directives** — `unsafe-inline`, `unsafe-eval`, wildcard `*`, missing `object-src 'none'`, missing `base-uri 'self'`
3. **Validate Against App Needs** — Flutter Web requires `'unsafe-eval'` for dart2js, blob/data URIs for assets
4. **Generate Remediated CSP** — Strictest policy that still works

## Flutter Web CSP Rules
| Directive | Required | Reason |
|-----------|----------|--------|
| `script-src` | `'self' 'unsafe-eval' 'strict-dynamic'` | dart2js bootstrap |
| `worker-src` | `blob:` | Web Workers via blob URLs |
| `img-src` | `blob: data:` | Frames rendered to blobs |
| `style-src` | `'self' 'unsafe-inline'` | Dynamic styles |
| `connect-src` | Firebase endpoints, `https:` | API calls |
| `frame-src` | `'none'` | No embedded content |
| `base-uri` | `'self'` | Base URI injection |
| `form-action` | `'self'` | Form submission |
| `object-src` | `'none'` | Plugin-based XSS |
