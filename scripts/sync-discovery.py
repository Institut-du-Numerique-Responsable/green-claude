#!/usr/bin/env python3
"""Generate discovery assets from the plugin and rules; --check detects drift."""
import argparse
import json
import re
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[1]
SITE = "https://institut-du-numerique-responsable.github.io/green-claude/"


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def rule_count(data):
    return sum(len(category["rules"]) for category in data["categories"].values())


def outputs():
    plugin = read_json(ROOT / ".claude-plugin/plugin.json")
    rules = ROOT / "skills/green-claude/rules"
    languages = sorted((rules / "langages").glob("*.json"))
    eco = rule_count(read_json(rules / "ecoconception.json"))
    usage = rule_count(read_json(rules / "usage.json"))
    lang = sum(rule_count(read_json(path)) for path in languages)
    metadata = {
        "@context": "https://schema.org",
        "@type": "SoftwareSourceCode",
        "@id": SITE + "#software",
        "name": "Green Claude",
        "description": ("Skill open source pour Claude Code : règles d'éco-conception RGESN/GR491, audit déterministe et pratiques d'usage responsable. "
                        f"{eco + usage + lang} règles : {eco} transverses, {lang} pour {len(languages)} langages et frameworks, {usage} pratiques d'usage."),
        "version": plugin["version"],
        "url": SITE,
        "codeRepository": plugin["repository"],
        "license": "https://opensource.org/licenses/MIT",
        "author": {"@type": "Organization", "name": plugin["author"]["name"], "url": "https://institutnr.org"},
        "runtimePlatform": "Claude Code",
        "inLanguage": ["fr", "en"],
        "keywords": plugin["keywords"],
    }
    # SoftwareSourceCode inherits CreativeWork; use its description rather
    # than application ratings, compliance claims or an unverified release date.
    serialized = json.dumps(metadata, ensure_ascii=False, indent=2) + "\n"
    result = {
        ROOT / ".well-known/ai.json": serialized,
        ROOT / "docs/ai.json": serialized,
    }
    page = ROOT / "docs/index.html"
    html = page.read_text(encoding="utf-8")
    replacement = '<script type="application/ld+json">\n' + serialized.rstrip() + '\n  </script>'
    html, count = re.subn(r'<script type="application/ld\+json">.*?</script>', lambda _: replacement, html, count=1, flags=re.S)
    if count != 1:
        raise ValueError("Expected one JSON-LD block in docs/index.html")
    result[page] = html
    # GitHub Pages serves /docs as the site root. List only public documents,
    # excluding private planning files and machine-readable discovery assets.
    pages = [""]
    for name in ("water-electricity-detection", "security-audit"):
        if (ROOT / f"docs/{name}.md").is_file():
            pages.append(name + ".html")
    pages.append("languages/")
    for path in languages:
        if not (ROOT / "docs/languages" / (path.stem + ".md")).is_file():
            raise ValueError(f"Missing language documentation: {path.stem}")
        pages.append("languages/" + path.stem + ".html")
    result[ROOT / "docs/sitemap.xml"] = (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
        + "".join(f"  <url><loc>{escape(SITE + path)}</loc></url>\n" for path in pages)
        + "</urlset>\n"
    )
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    stale = []
    for path, content in outputs().items():
        if path.is_file() and path.read_text(encoding="utf-8") == content:
            continue
        stale.append(str(path.relative_to(ROOT)))
        if not args.check:
            path.write_text(content, encoding="utf-8")
    if args.check and stale:
        print("Discovery assets out of date: " + ", ".join(stale))
        return 1
    print("OK - discovery assets " + ("verified" if args.check else "synchronized"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
