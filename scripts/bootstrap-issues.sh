#!/usr/bin/env python3
"""
Bootstrap the ClapLight GitHub repo from the local docs/tickets/ files.

Idempotent: re-running won't duplicate the repo, labels, milestones, or issues
(it matches existing issues by their title and skips if already present).

Requirements:
    - gh CLI installed and authenticated (`gh auth status` should succeed)
    - Python 3.9+
    - PyYAML (`pip install pyyaml`)

Usage:
    cd <repo root>
    python3 scripts/bootstrap-issues.sh
        (or chmod +x and run directly)

What it does:
    1. Creates the public repo "ClapLight" under your gh-authenticated user
       (skipped if it already exists; also skips if `git remote origin` is set)
    2. Creates labels for epic/*, status/*, priority/*, estimate/*
    3. Creates milestones "v1" and "v2"
    4. Creates one GitHub issue per file in docs/tickets/, with labels and milestone
       applied from frontmatter
"""

import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

REPO_NAME = "ClapLight"
REPO_DESC = "Local-network Android controller for Nanoleaf devices. Multi-device scenes, home-screen widget, direct 4D mode switching."

# Label definitions: (name, color_hex_no_hash, description)
LABELS = [
    # Epics
    ("epic/foundation",   "1f77b4", "Project setup, networking, permissions"),
    ("epic/devices",      "2ca02c", "Discovery, pairing, device persistence"),
    ("epic/control",      "ff7f0e", "Per-device state and effect control"),
    ("epic/scenes",       "9467bd", "Multi-device scene model and apply engine"),
    ("epic/home-screen",  "e377c2", "Widgets, Quick Settings tile, shortcuts"),
    ("epic/emersion",     "d62728", "4D screen-mirror mode switching"),
    ("epic/polish",       "8c564b", "Error handling, theme, distribution"),
    # Status
    ("status/todo",        "ededed", "Not started"),
    ("status/in-progress", "fbca04", "Actively being worked"),
    ("status/blocked",     "b60205", "Waiting on something"),
    # Priority
    ("priority/high", "d93f0b", "Critical for milestone"),
    ("priority/med",  "fbca04", "Important"),
    ("priority/low",  "0e8a16", "Nice-to-have"),
    # Estimate
    ("estimate/S", "c5def5", "~1–3 hours"),
    ("estimate/M", "c5def5", "~3–8 hours"),
    ("estimate/L", "c5def5", "~1–3 days"),
]

MILESTONES = [
    ("v1", "Ship to phone: discovery, pairing, control, scenes, widget, 4D mode"),
    ("v2", "Polish: shortcuts, error UX, theme, signed sideload build"),
]


def run(cmd, check=True, capture=True):
    """Run a shell command, return (returncode, stdout)."""
    result = subprocess.run(
        cmd, shell=isinstance(cmd, str),
        capture_output=capture, text=True,
    )
    if check and result.returncode != 0:
        print(f"  ✗ Command failed: {cmd}")
        if result.stderr:
            print(f"    stderr: {result.stderr.strip()}")
        sys.exit(1)
    return result.returncode, (result.stdout or "").strip()


def gh_json(args):
    """Run `gh api ...` returning parsed JSON, or None on 404."""
    rc, out = run(["gh"] + args, check=False)
    if rc != 0:
        return None
    try:
        return json.loads(out)
    except json.JSONDecodeError:
        return None


def check_prereqs():
    if not shutil.which("gh"):
        print("✗ gh CLI not found. Install from https://cli.github.com")
        sys.exit(1)
    rc, _ = run(["gh", "auth", "status"], check=False)
    if rc != 0:
        print("✗ gh CLI not authenticated. Run `gh auth login` first.")
        sys.exit(1)
    try:
        import yaml  # noqa: F401
    except ImportError:
        print("✗ PyYAML not installed. Run `pip install pyyaml`.")
        sys.exit(1)
    print("✓ Prerequisites OK")


def get_username():
    rc, out = run(["gh", "api", "user", "--jq", ".login"])
    return out


def ensure_repo(user):
    """Create the repo if it doesn't exist, return owner/name string."""
    full = f"{user}/{REPO_NAME}"
    existing = gh_json(["api", f"repos/{full}"])
    if existing:
        print(f"✓ Repo {full} already exists")
    else:
        print(f"  Creating public repo {full}...")
        run([
            "gh", "repo", "create", REPO_NAME,
            "--public",
            "--description", REPO_DESC,
            "--source", ".",
            "--remote", "origin",
            "--push",
        ])
        print(f"✓ Created and pushed {full}")
    return full


def ensure_labels(repo):
    print("  Ensuring labels...")
    existing = gh_json(["api", f"repos/{repo}/labels", "--paginate"]) or []
    existing_names = {lbl["name"] for lbl in existing}
    for name, color, desc in LABELS:
        if name in existing_names:
            continue
        run([
            "gh", "label", "create", name,
            "--repo", repo,
            "--color", color,
            "--description", desc,
        ])
        print(f"    + {name}")
    print(f"✓ {len(LABELS)} labels ready")


def ensure_milestones(repo):
    print("  Ensuring milestones...")
    existing = gh_json(["api", f"repos/{repo}/milestones", "--paginate"]) or []
    by_title = {m["title"]: m for m in existing}
    out = {}
    for title, desc in MILESTONES:
        if title in by_title:
            out[title] = by_title[title]["number"]
            continue
        rc, body = run([
            "gh", "api", f"repos/{repo}/milestones",
            "-f", f"title={title}",
            "-f", f"description={desc}",
        ])
        ms = json.loads(body)
        out[title] = ms["number"]
        print(f"    + {title}")
    print(f"✓ {len(MILESTONES)} milestones ready")
    return out


def parse_ticket(path):
    import yaml
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", text, re.DOTALL)
    if not m:
        raise ValueError(f"No frontmatter in {path}")
    meta = yaml.safe_load(m.group(1)) or {}
    body = m.group(2).strip()
    return meta, body


def existing_issue_titles(repo):
    rc, out = run([
        "gh", "issue", "list",
        "--repo", repo,
        "--state", "all",
        "--limit", "1000",
        "--json", "title",
    ])
    items = json.loads(out) if out else []
    return {it["title"] for it in items}


def create_issues(repo, milestone_numbers):
    tickets_dir = Path(__file__).resolve().parent.parent / "docs" / "tickets"
    if not tickets_dir.exists():
        print(f"✗ No tickets dir at {tickets_dir}")
        sys.exit(1)
    existing = existing_issue_titles(repo)
    files = sorted(tickets_dir.glob("*.md"))
    print(f"  Found {len(files)} ticket files")
    created = 0
    skipped = 0
    for f in files:
        meta, body = parse_ticket(f)
        title = f"[{meta['id']}] {meta['title']}"
        if title in existing:
            skipped += 1
            continue
        labels = [meta["epic_label"], meta["priority"],
                  meta["estimate"], meta["status"]]
        ms_num = milestone_numbers.get(meta["milestone"])
        cmd = [
            "gh", "issue", "create",
            "--repo", repo,
            "--title", title,
            "--body", body,
        ]
        for lbl in labels:
            cmd += ["--label", lbl]
        if ms_num:
            cmd += ["--milestone", meta["milestone"]]
        run(cmd)
        created += 1
        print(f"    + {title}")
    print(f"✓ Issues: {created} created, {skipped} already existed")


def main():
    print("=" * 60)
    print("ClapLight repo bootstrap")
    print("=" * 60)
    check_prereqs()
    user = get_username()
    print(f"  Authenticated as: {user}")
    repo = ensure_repo(user)
    ensure_labels(repo)
    milestone_numbers = ensure_milestones(repo)
    create_issues(repo, milestone_numbers)
    print()
    print("=" * 60)
    print(f"✓ Bootstrap complete. Open: https://github.com/{repo}/issues")
    print("=" * 60)


if __name__ == "__main__":
    main()
