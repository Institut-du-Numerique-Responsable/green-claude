#!/usr/bin/env python3
"""Regression checks for public URLs and generated discovery metadata."""
import importlib.util
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
import xml.etree.ElementTree as ET

sys.dont_write_bytecode = True

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("discovery", ROOT / "scripts/sync-discovery.py")
discovery = importlib.util.module_from_spec(spec)
spec.loader.exec_module(discovery)


class DiscoveryTests(unittest.TestCase):
    def test_sitemap_routes_match_pages_source(self):
        generated = discovery.outputs()
        tree = ET.fromstring(generated[ROOT / "docs/sitemap.xml"])
        urls = [node.text for node in tree.findall("{*}url/{*}loc")]
        self.assertEqual(len(urls), len(set(urls)))
        self.assertIn(discovery.SITE + "languages/", urls)
        for url in urls:
            self.assertTrue(url.startswith(discovery.SITE))
            path = url.removeprefix(discovery.SITE)
            self.assertFalse(path.startswith("docs/"))
            self.assertNotIn("superpowers", path)
            source = "index.html" if path == "" else (
                path + "README.md" if path.endswith("/") else path.replace(".html", ".md")
            )
            self.assertTrue((ROOT / "docs" / source).is_file(), source)
        for rule in (ROOT / "skills/green-claude/rules/langages").glob("*.json"):
            self.assertIn(discovery.SITE + f"languages/{rule.stem}.html", urls)

    def test_metadata_is_consistent_and_has_no_unsourced_rating(self):
        generated = discovery.outputs()
        metadata = json.loads(generated[ROOT / "docs/ai.json"])
        plugin = json.loads((ROOT / ".claude-plugin/plugin.json").read_text())
        self.assertEqual(metadata["version"], plugin["version"])
        self.assertNotIn("aggregateRating", metadata)
        self.assertEqual(generated[ROOT / "docs/ai.json"], generated[ROOT / ".well-known/ai.json"])
        block = re.search(r'<script type="application/ld\+json">(.*?)</script>', generated[ROOT / "docs/index.html"], re.S)
        self.assertEqual(json.loads(block.group(1)), metadata)

    def test_check_detects_drift_without_writing(self):
        with tempfile.TemporaryDirectory() as folder:
            fixture = Path(folder)
            for name in [".claude-plugin", "skills/green-claude/rules", "docs/languages"]:
                shutil.copytree(ROOT / name, fixture / name)
            (fixture / "scripts").mkdir()
            (fixture / ".well-known").mkdir()
            for name in ["scripts/sync-discovery.py", "docs/index.html", "docs/security-audit.md", "docs/water-electricity-detection.md"]:
                shutil.copyfile(ROOT / name, fixture / name)
            command = [sys.executable, str(fixture / "scripts/sync-discovery.py")]
            subprocess.run(command, check=True, capture_output=True)
            subprocess.run(command + ["--check"], check=True, capture_output=True)
            page = fixture / "docs/ai.json"
            page.write_text('{"version":"wrong"}\n')
            result = subprocess.run(command + ["--check"], capture_output=True)
            self.assertEqual(result.returncode, 1)
            self.assertEqual(page.read_text(), '{"version":"wrong"}\n')
            subprocess.run(command, check=True, capture_output=True)
            subprocess.run(command + ["--check"], check=True, capture_output=True)


if __name__ == "__main__":
    unittest.main()
