#!/usr/bin/env python3
"""Export the reviewed current source without historical data or Git objects.

Usage: python3 tools/prepare-public-source.py /path/to/new-directory
The destination must not exist. No commits, remotes, or publication are created.
"""
from pathlib import Path
import shutil
import sys

ROOT = Path(__file__).resolve().parents[1]
FILES = (
    "DESCRIPTION", "NAMESPACE", "README.md", "NEWS.md", "COPYING",
    "ATTRIBUTION.md", "CONTRIBUTING.md", "RELEASE_CHECKLIST.md",
    "MODERNIZATION_NOTES.md", ".Rbuildignore", ".gitignore", "ggsubplot.Rproj",
)
TREES = ("R", "man", "data", "vignettes", "tests", "docs", "tools", ".github")


def main():
    if len(sys.argv) != 2:
        raise SystemExit(__doc__)
    dest = Path(sys.argv[1]).expanduser().resolve()
    if dest.exists():
        raise SystemExit("Destination exists; choose a new directory.")
    if dest == ROOT or ROOT.is_relative_to(dest):
        raise SystemExit("Destination must not contain the working repository.")
    # Refuse stale candidate snapshots and links rather than silently exporting.
    for tree in TREES:
        for path in (ROOT / tree).rglob("*"):
            if path.is_symlink() or ".new." in path.name:
                raise SystemExit(f"Resolve link or unaccepted snapshot first: {path}")
    dest.mkdir(parents=True)
    for name in FILES:
        shutil.copy2(ROOT / name, dest / name)
    for name in TREES:
        shutil.copytree(ROOT / name, dest / name,
                        ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    print(f"Exported current source to {dest}; no .git or .dev included.")


if __name__ == "__main__":
    main()
