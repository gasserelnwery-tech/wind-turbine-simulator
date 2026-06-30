# Wind Turbine Simulator — AGENTS.md

## Commands

| Command | Purpose |
|---------|---------|
| `flutter pub get` | Install deps |
| `flutter run -d chrome` | Run dev (web only) |
| `flutter build web --wasm --release` | Production build (Wasm) — JS fallback: `flutter build web --release` |
| `flutter test` | Run tests (single smoke test exists) |
| `flutter analyze` | Lint + typecheck combined |

## Architecture

- **Flutter Web** app (also builds Android but web is primary target)
- **Custom software 3D renderer** — no WebGL/Three.js; uses `CustomPainter` + `Canvas` + custom `math3d.dart` (Vec3, Mat4, TriMesh). Painter's algorithm (back-to-front sort)
- **BEM physics** in `core/simulation_engine.dart` — actuator disk model with Newton-Raphson axial induction factor. 5 turbine presets (HAWT + VAWT)
- **2D fluid solver** in `fluid/` — Stable Fluids method (Jos Stam) on 80×80 grid. Runs on main thread in animation tick
- **No CI/CD** — no GitHub Actions, Makefile, or deploy scripts

## State Management (Riverpod)

- `SimulationNotifier` (Riverpod `Notifier`, migrated from `StateNotifier` in v3) holds all simulation state
- **Params are mutable** — `SimulationParams` fields are mutated directly, then `_recompute()` called. NOT immutable/copyWith
- Camera is **local widget state** in `_HomePageState`, not in Riverpod. Only `resetCamera` is triggered via provider
- `TurbineMeshes` is a mutable object held by `_HomePageState` — rebuilt on type change, rotation applied each frame
- `Renderer3D` is **instantiated per paint call** (every frame)
- Provider consumption: use `ref.watch(simulationProvider)` for state, `ref.read(simulationProvider.notifier)` for methods (Riverpod 3.x API)

## Firebase

- Initialized best-effort at startup — wrapped in `try/catch`, non-blocking
- `firebase_crashlytics` integrated: `FlutterError.onError` and `PlatformDispatcher.onError` route to Crashlytics (Android only; web falls back to `debugPrint`)
- Not actively used beyond error reporting (no Firestore, Auth, Storage calls). Configured for Hosting + Crashlytics
- `firebase_options.dart` only supports **web** and **android**; throws for iOS/macOS/Windows/Linux

## Routes

| Path | Page |
|------|------|
| `/` | `HomePage` (simulation viewport + controls) |
| `/standards` | `StandardsPage` (IEC 61400 reference) |
| `/calculator` | `CalculatorPage` (wind power formula reference) |

## Key Quirks

- **Only dark theme is used** — `AppTheme.darkTheme` in `app.dart`. Light theme exists but unused
- **Linter** disables `prefer_const_constructors` and `prefer_const_literals_to_create_immutables`
- **No unit tests for simulation engine** — only one widget smoke test (`test/widget_test.dart`) that checks for "Wind Turbine Sim" title
- Skills lock file at `skills-lock.json` lists Firebase skills. `opencode.json` registers both `.opencode/skills/` and `.agents/skills/`
- Layout adapts: landscape shows side-by-side (320px controls + viewport), portrait stacks vertically
- Dart SDK constraint: `>=3.0.0 <4.0.0`
- **SEO files**: `web/robots.txt` (allows AI crawlers), `web/sitemap.xml` (3 URLs: /, /standards, /calculator), `llms.txt` (root). `web/index.html` includes OG tags, Twitter Card, JSON-LD Schema (SoftwareApplication + FAQPage), CSP, `<meta keywords>`, `<noscript>` with full landing page (H1+H2+H3+paragraphs+links)
- **Semantics**: Charts (`charts.dart`), standards page data tables (`standards_page.dart`), calculator page, HUD values, home page title (Semantics header), and control panel sliders all wrapped in `Semantics` for AI crawler / screen reader access
- **Dependencies**: `flutter_riverpod: ^3.3.2`, `fl_chart: ^1.2.0`, `google_fonts: ^8.1.0`, `firebase_core: ^4.11.0`, `flutter_lints: ^6.0.0`

## Skills

### 1. Frontend Design (`frontend-design`)
**Description**: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when asked to build web components, pages, artifacts, posters, or applications.

- **Design Thinking**: Before coding, commit to a BOLD aesthetic direction. Define the Purpose, Tone (e.g., brutalist, retro-futuristic, luxury), Constraints, and Differentiation. 
- **Aesthetics Guidelines**:
  - **Typography**: Use beautiful, unique fonts. NEVER use generic fonts like Arial, Inter, or Roboto.
  - **Color & Theme**: Cohesive aesthetic with CSS variables. Dominant colors with sharp accents. Avoid cliched AI schemes (e.g., purple gradients on white).
  - **Motion**: High-impact animations and micro-interactions (e.g., staggered page load reveals).
  - **Spatial Composition**: Unexpected layouts, asymmetry, overlap, diagonal flow, and generous negative space.
  - **Backgrounds**: Create atmosphere and depth with contextual effects/textures instead of solid colors.
- **Rule**: Match implementation complexity to the aesthetic vision. No design should look like generic "AI slop".

### 2. Web Design Guidelines (`web-design-guidelines`)
**Description**: Review UI code for Web Interface Guidelines compliance. Use when asked to "review my UI", "check accessibility", "audit design", "review UX", or "check my site against best practices".

- **Workflow**:
  1. Fetch fresh guidelines from: `https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md`
  2. Read the specified files (or prompt user for files/pattern).
  3. Check against all rules in the fetched guidelines.
  4. Output findings in the terse `file:line` format.

### 3. Accessibility Audit Checklist
**Description**: Create a comprehensive accessibility audit checklist for the website/application. Format as an actionable checklist with specific items to verify.

- **WCAG Compliance**: Level A, Level AA, and Level AAA considerations.
- **Keyboard Navigation**: Tab order, focus indicators, keyboard shortcuts, skip links.
- **Screen Reader Compatibility**: ARIA labels, semantic HTML, alt text for images, form labels.
- **Visual Accessibility**: Color contrast ratios, text sizing, visual indicators (not just color), animation/motion preferences.
- **Content Accessibility**: Heading structure, link text clarity, form error messages, language attributes.
- **Interactive Elements**: Button, form, modal/dialog, and custom component accessibility.
- **Testing Checklist**: Screen reader testing, keyboard-only testing, color contrast testing, browser testing.

### 4. AI SEO & AI Visibility (`ai-seo`)
**Description**: Optimize the app to be discoverable, extractable, and citable by AI search engines (Google AI Overviews, ChatGPT, Perplexity, Claude). AI SEO focuses on getting **cited** as a source, not just ranked.

**Critical Implementation Rules for this Flutter Web Project:**
- **The Flutter Canvas Problem**: Flutter Web renders UI to `<canvas>`, which is invisible to AI crawlers and traditional SEO.
  - **Action**: ALWAYS use `Semantics` widgets for critical text, headings, data, and interactive elements.
  - **Action**: Ensure `web/index.html` contains rich, semantic HTML fallback content or comprehensive meta descriptions so AI understands the app without executing JS.
- **Machine-Readable Files (Must exist in `web/` directory)**:
  - `robots.txt`: MUST explicitly **ALLOW** AI crawlers (`GPTBot`, `ChatGPT-User`, `PerplexityBot`, `ClaudeBot`, `Google-Extended`). Do not block them.
  - `llms.txt`: Maintain a root `llms.txt` file explaining the simulator's purpose, physics models (BEM, Actuator Disk), and usage, formatted for AI agents to parse.
- **Meta & Structured Data (`web/index.html`)**:
  - Include comprehensive `<meta>` tags (description, OG, Twitter, canonical).
  - Inject JSON-LD Schema markup (e.g., `SoftwareApplication`, `EducationalApplication`, `FAQPage` for the `/standards` route).
- **Content Extractability (for `/standards` and text content)**:
  - Structure content in clear, self-contained blocks (40-60 words per key answer).
  - Use semantic HTML headings in the web index or Flutter `Semantics` headers (H1, H2, H3).
  - Include statistics, citations (IEC 61400), and authoritative context to boost citation probability.
- **Agentic Accessibility**: AI agents read the accessibility tree. Ensure clean ARIA labels, logical tab order, and visible pricing/specs (if applicable) without heavy JS blocking.
- **What NOT to do**: Do not hide critical information behind un-rendered JS states. Do not write separate "AI-bait" content; write clear, structured, human-first content that AI can easily extract.

### 5. UX Writing (`ux-writing`)
**Description**: Write effective microcopy for digital interfaces.

**Core Principles:**
- **Clarity Over Cleverness** — Use simple words, avoid jargon, say what you mean
- **Be Concise** — Cut unnecessary words, one idea per sentence, front-load info
- **Be Helpful** — Tell users what to do, provide next steps, reduce anxiety

**Button Labels:**
Use action verbs (Save, Send, Create, "Add to Cart"). Avoid generic: OK, Submit, Continue, "Click here".

**Error Messages:** What happened + Why + How to fix it. Be specific, avoid blame, suggest a solution.

**Empty States:** What this space is for + Why it's empty + How to fill it.

**Loading & Progress:** <2s → spinner only; 2-10s → specific text; >10s → estimated time + progress.

**Voice:** Friendly but professional, clear and direct, helpful. Tone varies by context (success = warm, error = calm, onboarding = encouraging).

### 6. CSP Evaluator (`csp-evaluator`)

### 7. Web Security Audit (`web-security-audit`)
**Description**: Perform comprehensive security audit for web applications. Use when asked to "audit my site security", "check for vulnerabilities", "OWASP check", "security review", "harden my app", "find security issues", or before deploying to production. Covers OWASP Top 10, security headers, dependencies, secrets, and framework-specific checks.

**Audit Phases:**
1. **Reconnaissance** — Identify tech stack (Flutter Web + Firebase), map attack surface (routes `/`, `/standards`, Canvas renderer, fluid solver, Riverpod state)
2. **Automated Scanning**:
   - **Dependencies**: `osv-scanner --lockfile=pubspec.lock` + `flutter pub outdated`
   - **Secrets**: `gitleaks detect --source .` (hunt for hardcoded Firebase keys, API tokens in `firebase_options.dart`)
   - **SAST**: `semgrep --config=p/security-audit lib/`
   - **DAST**: `docker run -t owasp/zap2docker-stable zap-baseline.py -t https://your-app.com`
3. **OWASP Top 10 Manual Testing** — Broken access control, injection, XSS, IDOR, SSRF, crypto failures
4. **Security Headers** — HSTS, X-Frame-Options, X-Content-Type-Options, Permissions-Policy, Referrer-Policy (configure in `firebase.json` under `hosting.headers`)
5. **Framework-Specific Checks**:
   - **Flutter Web**: No hardcoded secrets in Dart, verify `Semantics` widgets don't leak data, Wasm CSP rules correct
   - **Firebase**: Test Security Rules via emulator (`firebase emulators:exec "npm test"`), verify API key restrictions in Google Cloud Console, check Firestore/Storage rules are NOT open (`if true`)
6. **Reporting** — Severity matrix (Critical/High/Medium/Low), remediation plan with SLAs

**Pre-Deployment Checklist:**
- [ ] All Critical/High vulnerabilities fixed
- [ ] Dependencies updated, no known CVEs
- [ ] No secrets in code (gitleaks passed)
- [ ] Security headers + CSP configured (see `csp-evaluator` skill)
- [ ] Firebase Security Rules tested in emulator
- [ ] HTTPS enforced, TLS 1.2+
- [ ] Error messages don't leak info (no stack traces in production)
- [ ] Logging/monitoring configured

**Tools Reference:**
| Tool | Purpose | Install |
|------|---------|---------|
| `osv-scanner` | Dependency scanning | `go install github.com/google/osv-scanner/v2@latest` |
| `gitleaks` | Secret detection | `brew install gitleaks` |
| `semgrep` | Static analysis | `pip install semgrep` |
| `OWASP ZAP` | Dynamic analysis | `docker pull owasp/zap2docker-stable` |
| `SSL Labs` | TLS testing | https://www.ssllabs.com/ssltest/ |
| `Security Headers` | Headers check | https://securityheaders.com/ |

**Related Skills**: `csp-evaluator` (for CSP details), `ai-seo` (ensure security doesn't block AI crawlers)
**Description**: Audit and validate Content Security Policy (CSP) configurations for web applications. Use when asked to "check my CSP", "review security headers", "audit content security policy", "fix CSP errors", "harden web security", or when deploying Flutter Web apps to production. Ensures CSP blocks XSS attacks while allowing legitimate app functionality.

**Overview**: Content Security Policy (CSP) is an HTTP header that tells browsers which sources of content are allowed to load and execute. A misconfigured CSP can either be too permissive (allows XSS attacks) or too restrictive (breaks legitimate app functionality). This skill helps find the balance.

**Process:**
1. **Extract Current CSP** — From HTML meta tag or HTTP response headers (check browser DevTools → Network → response headers, or `web/index.html` for `<meta http-equiv="Content-Security-Policy">`)
2. **Check for Dangerous Directives** — `unsafe-inline`, `unsafe-eval`, wildcard `*` sources, missing `object-src 'none'`, missing `base-uri 'self'`
3. **Validate Against App Needs** — Flutter Web requires `'unsafe-eval'` for `dart2js` bootstrapping and blob/data URIs for asset loading. Firebase services need specific allowlists
4. **Generate Remediated CSP** — Strictest policy that still works. Use `'strict-dynamic'` + nonce/hash for modern browsers, with `https: scheme` fallback and `'unsafe-inline'` only where required

**Flutter Web CSP Rules:**
- `script-src`: Must include `'unsafe-eval'` (required by dart2js), `'self'`, and `'strict-dynamic'` for modern browsers
- `worker-src`: Must include `blob:` (Flutter Web uses Web Workers via blob URLs)
- `img-src`: Must include `blob: data:` (Flutter renders frames to blob/data URIs)
- `style-src`: Must include `'unsafe-inline'` (Flutter injects dynamic styles)
- `connect-src`: Must include Firebase endpoints, `https:` if using remote APIs
- `frame-src`: Set to `'none'` unless using embedded content
- `base-uri`: Set to `'self'`
- `form-action`: Set to `'self'`
- `object-src`: Set to `'none'`

**Key Directives Reference:**
| Directive | Misconfiguration | Risk | Fix |
|-----------|------------------|------|-----|
| `script-src` | `*`, missing `'unsafe-eval'` for Flutter | XSS or broken app | Use `'self' 'unsafe-eval' 'strict-dynamic'` |
| `object-src` | Missing or `*` | Plugin-based XSS | Set to `'none'` |
| `base-uri` | Missing | Base URI injection | Set to `'self'` |
| `worker-src` | Missing or no `blob:` | Flutter workers fail | Add `blob:` |
| `img-src` | Missing `blob: data:` | Flutter renders blank | Add `blob: data:` |
| `style-src` | `*` or missing `'unsafe-inline'` | Broken styling | Use `'self' 'unsafe-inline'` |
| `default-src` | `*` | Overall too permissive | Be specific, avoid wildcards |
