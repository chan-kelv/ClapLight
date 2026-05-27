# Contributing & Repo Setup

## First-time bootstrap

This repo includes a script that creates the GitHub repo (if not yet created), labels, milestones, and one issue per ticket in `docs/tickets/`.

### Prerequisites

```bash
# Install gh CLI
brew install gh         # macOS
# or: https://cli.github.com for other platforms

# Authenticate
gh auth login

# Install PyYAML
pip install pyyaml
```

### Run the bootstrap

```bash
cd /path/to/ClapLight
git init
git add .
git commit -m "Initial scaffolding"
python3 scripts/bootstrap-issues.sh
```

The script will:

1. Create a public repo named `ClapLight` under your GitHub user (if not already created), set `origin`, and push `main`
2. Create all labels (`epic/*`, `status/*`, `priority/*`, `estimate/*`)
3. Create milestones `v1` and `v2`
4. Create one issue per `docs/tickets/*.md` with labels and milestone applied from each file's frontmatter

It's idempotent — safe to re-run. Existing issues, labels, and milestones are detected and skipped.

If you want a different repo name or visibility, edit the constants at the top of `scripts/bootstrap-issues.sh`.

## Adding new tickets later

Either:

- **Create directly on GitHub** using the issue templates in `.github/ISSUE_TEMPLATE/`
- **Add a new ticket file** to `docs/tickets/<ID>.md` with the same frontmatter shape as the existing ones, then re-run the bootstrap script — only the new ones will get created

## Ticket frontmatter schema

```yaml
---
id: F-01                          # Unique identifier (epic-prefix + number)
title: "Project setup"            # Human-readable title (quoted)
epic: Foundation                  # Display name for the epic
epic_label: epic/foundation       # Label applied to the issue
milestone: v1                     # v1 or v2
priority: priority/high           # priority/high | priority/med | priority/low
estimate: estimate/S              # estimate/S | estimate/M | estimate/L
status: status/todo               # initial status label
---
```

The body is standard markdown. The bootstrap script uses the file's body verbatim as the issue body.
