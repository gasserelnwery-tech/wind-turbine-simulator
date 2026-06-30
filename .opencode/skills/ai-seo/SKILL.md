---
name: ai-seo
description: Optimize the app to be discoverable, extractable, and citable by AI search engines (Google AI Overviews, ChatGPT, Perplexity, Claude). AI SEO focuses on getting cited as a source, not just ranked.
---

# AI SEO & AI Visibility

## Critical Implementation Rules for Flutter Web
- **The Flutter Canvas Problem**: Flutter Web renders UI to `<canvas>`, invisible to AI crawlers.
  - ALWAYS use `Semantics` widgets for critical text, headings, data, and interactive elements.
  - Ensure `web/index.html` contains rich, semantic HTML fallback content or comprehensive meta descriptions.
- **Machine-Readable Files** (in `web/`):
  - `robots.txt`: MUST explicitly ALLOW AI crawlers (`GPTBot`, `ChatGPT-User`, `PerplexityBot`, `ClaudeBot`, `Google-Extended`).
  - `llms.txt`: Root-level file explaining the simulator's purpose, physics models, and usage for AI agents.
- **Meta & Structured Data** (`web/index.html`):
  - Comprehensive `<meta>` tags (description, OG, Twitter, canonical).
  - JSON-LD Schema markup (e.g., `SoftwareApplication`, `EducationalApplication`, `FAQPage`).
- **Content Extractability**:
  - Self-contained blocks (40-60 words per key answer).
  - Semantic HTML headings or Flutter `Semantics` headers (H1, H2, H3).
  - Statistics, citations (IEC 61400), authoritative context.
- **What NOT to do**: Do not hide critical info behind un-rendered JS states. Write clear, structured, human-first content.
