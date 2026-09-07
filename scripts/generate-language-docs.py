#!/usr/bin/env python3
"""
Generate language-specific documentation pages from rules/langages/*.json files.

Usage:
    python3 generate-language-docs.py [--output-dir=docs/languages]

Output:
    One markdown file per language in the specified directory, with:
    - Language name and description
    - Metadata (extensions, globs, count)
    - Rules grouped by category
    - Examples (bad/good) when available
"""

import json
import os
import sys
from pathlib import Path

# Default paths
RULES_DIR = "skills/green-claude/rules/langages"
OUTPUT_DIR = "docs/languages"


def load_language_rules(filepath):
    """Load and return the JSON data from a language rules file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def generate_markdown_content(lang_data, lang_name):
    """Generate markdown content for a single language."""
    metadata = lang_data.get("metadata", {})
    categories = lang_data.get("categories", {})
    
    name = metadata.get("name", lang_name)
    description = metadata.get("description", "")
    version = metadata.get("version", "1.0.0")
    extensions = metadata.get("extensions", [])
    globs = metadata.get("globs", "")
    count = metadata.get("count", 0)
    
    # Header
    content = [
        f"# {name}",
        "",
        f"**Version:** {version} | **Rules:** {count} | **Extensions:** {', '.join(extensions) if extensions else 'All'}",
        "",
        f"{description}",
        "",
        "---",
        "",
        "## Metadata",
        "",
        f"| Property | Value |",
        f"|---|---|",
        f"| **File** | `{RULES_DIR}/{lang_name}.json` |",
        f"| **Globs** | `{globs}` |",
        f"| **Extensions** | `{', '.join(extensions)}` |",
        f"| **Rule Count** | {count} |",
        "",
    ]
    
    # Categories and rules
    content.append("## Rules by Category")
    content.append("")
    
    for category_key, category_data in categories.items():
        category_name = category_data.get("name", category_key)
        category_desc = category_data.get("description", "")
        rules = category_data.get("rules", [])
        
        if not rules:
            continue
            
        content.append(f"### {category_name}")
        content.append("")
        if category_desc:
            content.append(f"{category_desc}")
            content.append("")
        
        content.append("| ID | Impact | Title | Recommendation |")
        content.append("|---|---|---|---|")
        
        for rule in rules:
            rule_id = rule.get("id", "")
            impact = rule.get("impact", "")
            title = rule.get("title", "")
            recommendation = rule.get("recommendation", "")
            
            # Escape pipes for markdown tables
            title_escaped = title.replace("|", "\\|")
            recommendation_escaped = recommendation.replace("|", "\\|")
            
            content.append(f"| {rule_id} | {impact} | {title_escaped} | {recommendation_escaped} |")
        
        content.append("")
        
        # Add examples if available
        for rule in rules:
            if "example" in rule:
                example = rule["example"]
                if "bad" in example and "good" in example:
                    content.append("<details>")
                    content.append(f"<summary>Example for {rule.get('id', '')}</summary>")
                    content.append("")
                    content.append(f"**Before:**")
                    content.append(f"```")
                    content.append(example.get("bad", ""))
                    content.append(f"```")
                    content.append("")
                    content.append(f"**After:**")
                    content.append(f"```")
                    content.append(example.get("good", ""))
                    content.append(f"```")
                    content.append("")
                    content.append("</details>")
                    content.append("")
    
    # Footer
    content.append("---")
    content.append("")
    content.append(f"[Back to all languages](./README.md) | [Main documentation](https://github.com/Institut-du-Numerique-Responsable/green-claude/blob/main/README.md)")
    
    return "\n".join(content)


def main():
    # Parse arguments
    output_dir = OUTPUT_DIR
    rules_dir = RULES_DIR
    
    for i, arg in enumerate(sys.argv[1:]):
        if arg.startswith("--output-dir="):
            output_dir = arg.split("=", 1)[1]
        elif arg.startswith("--rules-dir="):
            rules_dir = arg.split("=", 1)[1]
    
    # Ensure paths exist
    rules_path = Path(rules_dir)
    if not rules_path.exists():
        print(f"Error: Rules directory not found: {rules_dir}", file=sys.stderr)
        sys.exit(1)
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Get all language files
    lang_files = sorted(rules_path.glob("*.json"))
    
    if not lang_files:
        print(f"No language rule files found in {rules_dir}", file=sys.stderr)
        sys.exit(1)
    
    # Generate pages for each language
    for lang_file in lang_files:
        lang_name = lang_file.stem
        lang_data = load_language_rules(lang_file)
        markdown_content = generate_markdown_content(lang_data, lang_name)
        
        output_file = output_path / f"{lang_name}.md"
        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(markdown_content)
        
        print(f"Generated: {output_file}")
    
    # Generate index page
    index_content = [
        "# Language-Specific Eco-Design Rules",
        "",
        "This directory contains detailed documentation for each supported language.",
        "Each page lists all rules specific to that language, grouped by category.",
        "",
        "## Available Languages",
        "",
        "| Language | Rules | File |",
        "|---|---|---|",
    ]
    
    for lang_file in lang_files:
        lang_name = lang_file.stem
        lang_data = load_language_rules(lang_file)
        metadata = lang_data.get("metadata", {})
        count = metadata.get("count", 0)
        index_content.append(f"| [{lang_name}](./{lang_name}.md) | {count} | `{lang_name}.json` |")
    
    index_content.append("")
    index_content.append("## How to Use")
    index_content.append("")
    index_content.append("These pages are automatically generated from the rule files in `skills/green-claude/rules/langages/`.")
    index_content.append("To regenerate them, run:")
    index_content.append("")
    index_content.append("```bash")
    index_content.append("scripts/generate-language-docs.py")
    index_content.append("```")
    
    index_file = output_path / "README.md"
    with open(index_file, 'w', encoding='utf-8') as f:
        f.write("\n".join(index_content))
    
    print(f"Generated: {index_file}")
    print(f"\nTotal: {len(lang_files)} language documentation pages generated")


if __name__ == "__main__":
    main()
