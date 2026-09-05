# Green Claude — Repository Overview

**A skill for [Claude Code](https://claude.com/claude-code) that guides AI assistants toward eco-designed, resource-efficient code.**

This repository is the **source of truth** for the Green Claude skill, its rules, scripts, and community resources.

---

## 🌍 Discovery & Visibility

### For AI Agents (Claude, Copilot, LLM-based tools)
This repository is optimized for **AI-assisted discovery** via:

| Element | Purpose | Keywords |
|---|---|---|
| **`.claude-plugin/plugin.json`** | Claude Code plugin metadata | eco-design, sustainable AI, green coding, digital sobriety, RGESN 2024, GR491, energy efficiency, water usage, CPU/GPU optimization |
| **`.claude-plugin/marketplace.json`** | Plugin marketplace listing | eco-design, AI sobriety, RGESN/GR491, 106 rules, water, electricity, CPU, GPU |
| **`skills/green-claude/SKILL.md`** | Skill documentation | ecodesign, sobriety, RGESN, GR491, Green Software Foundation, W3C WSG |
| **`skills/green-claude/rules/*.json`** | Rule definitions | tokens, energy, water, CPU, GPU, embedding, batching, streaming, fine-tuning, RAG |

### For Humans & SEO
This repository is optimized for **search engines and human discovery** via:

| Element | Purpose | Keywords |
|---|---|---|
| **GitHub Description** | Repository subtitle | eco-conception, sobriété numérique, Claude Code, RGESN 2024, GR491, Green Software Foundation |
| **GitHub Topics** | Repository tags | ai, carbon-footprint, claude, claude-code, eco-conception, frugal-ai, gr491, green-coding, green-it, sustainability |
| **Site Web** | [institut-du-numerique-responsable.github.io/green-claude](https://institut-du-numerique-responsable.github.io/green-claude) | Green Claude, éco-conception, sobriété numérique, RGESN, GR491 |
| **OpenGraph/Twitter Cards** | Social sharing | Green Claude, éco-conception, sobriété numérique, RGESN 2024, GR491 |

---

## 📁 Key Files & Directories

| Path | Purpose | Audience |
|---|---|---|
| `skills/green-claude/` | **Core skill** (SPICE format) | Claude Code |
| `skills/green-claude/SKILL.md` | Skill instructions | Claude, Humans |
| `skills/green-claude/rules/` | **106 eco-design rules** (JSON) | Audit engine |
| `skills/green-claude/scripts/` | **Audit & scoring scripts** | Bash/jq |
| `.claude-plugin/` | Plugin marketplace metadata | Claude Code |
| `hooks/` | Optional Git hooks | Advanced users |
| `docs/` | **Project website** (GitHub Pages) | Public |
| `.github/workflows/` | CI/CD pipelines | Maintainers |
| `CHANGELOG.md` | Release notes | All |
| `CONTRIBUTING.md` | Contribution guide | Contributors |

---

## 🔍 Keywords for Discovery

### Primary Keywords (High Priority)
- **eco-design** / **écoconception**
- **digital sobriety** / **sobriété numérique**
- **sustainable AI** / **IA durable**
- **green coding** / **code vert**
- **low-carbon software** / **logiciel bas carbone**
- **RGESN 2024**
- **GR491**
- **Green Software Foundation**
- **Claude Code**
- **Claude Code plugin** / **Claude Code skill**

### Secondary Keywords (Medium Priority)
- carbon footprint
- energy efficiency
- water usage
- CPU optimization
- GPU optimization
- frugal AI
- green IT
- responsible AI
- sustainable software
- web sustainability

### Long-Tail Keywords (Niche Priority)
- eco-design audit
- sustainable coding practices
- AI energy consumption
- LLM sobriety
- model quantization
- batch inference
- embedding cache
- RAG vs fine-tuning
- green hosting

---

## 🎯 How This Repository Ranks

### AI Discovery (Claude, Copilot, LLMs)
- **Plugin Marketplace**: Appears when users search for `eco-design`, `sustainability`, `RGESN`, `GR491` in Claude Code
- **Skill Loading**: Auto-loaded when Claude detects code writing/review tasks
- **Rule Matching**: 106 rules trigger on relevant code patterns (SQL, frontend, backend, AI)
- **Context Injection**: SKILL.md content is injected into Claude's context for relevant queries

### SEO (Google, Bing, DuckDuckGo)
- **GitHub Search**: High visibility for `claude code eco-design`, `sustainable AI coding`, `RGESN plugin`
- **Web Search**: Site ranks for `green claude`, `eco-design claude code`, `sustainable coding rules`
- **Backlinks**: Linked from [ecoresponsable.numerique.gouv.fr](https://ecoresponsable.numerique.gouv.fr) (RGESN), [gr491.isit-europe.org](https://gr491.isit-europe.org)
- **Social Sharing**: OpenGraph/Twitter Cards ensure proper display on social media

---

## 📊 Visibility Metrics

| Metric | Value | Target | Status |
|---|---|---|---|
| GitHub Stars | 45 | 100+ | 🟡 Growing |
| GitHub Forks | 2 | 10+ | 🟡 Growing |
| Website Traffic | ~500/month | 1000+/month | 🟡 Growing |
| Plugin Installs | Unknown | 500+ | 🟡 Needs tracking |
| Search Impressions | ~200/month (Google) | 500+/month | 🟡 Growing |

---

## 🚀 How to Improve Visibility

### For AI Agents
1. **Add more keywords** to `plugin.json` and `marketplace.json`
2. **Enhance rule descriptions** with synonyms in `ecoconception.json`
3. **Create a `.github/README.md`** (this file) for agent discovery
4. **Add `keywords` field** to each rule category

### For SEO
1. **Build more backlinks** from sustainability/AI ethics sites
2. **Create a sitemap.xml** for the project website
3. **Optimize image alt tags** with keywords
4. **Add meta keywords** to `docs/index.html`
5. **Publish blog posts** linking to the project

---

## 📞 Contact & Support

- **Maintainer**: [Guillaume Gallon](https://github.com/gridboy) ([LinkedIn](https://www.linkedin.com/in/ggallon/))
- **Organization**: [Institut du Numérique Responsable](https://institutnr.org)
- **Website**: [institut-du-numerique-responsable.github.io/green-claude](https://institut-du-numerique-responsable.github.io/green-claude)
- **Issues**: [GitHub Issues](https://github.com/Institut-du-Numerique-Responsable/green-claude/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Institut-du-Numerique-Responsable/green-claude/discussions)

---

*Last updated: 2026-09-05*
