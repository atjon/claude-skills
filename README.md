# claude-skills

A version-controlled collection of every [Claude Code skill](https://code.claude.com/docs/en/skills)
created on this computer, organized by what the skill is used for.

This repository is **managed by Claude Code itself**. Whenever Claude creates or
edits a skill on this machine, it syncs the skill here and pushes. The rules
Claude must follow live in [MAINTENANCE.md](MAINTENANCE.md) — read that file
before changing anything in this repo.

## Layout

```
claude-skills/
├── README.md            ← you are here (for humans)
├── MAINTENANCE.md       ← rules + workflow for Claude (read first!)
├── manifest.tsv         ← source-of-truth list: where each skill lives on disk,
│                          its category, and its scope (personal or project)
├── scripts/
│   └── sync-skills.sh   ← copies skills from the machine into this repo,
│                          commits, and pushes
└── skills/
    └── <category>/          ← one folder per purpose (see "Categories" below)
        └── <skill-name>/    ← the skill itself
            ├── SKILL.md     ← every skill has this file
            └── ...          ← any supporting files the skill needs
```

## Categories

Categories describe **what the skill is used for**, not what technology it touches.
They are created on demand — this index must be kept up to date when a category
is added or removed:

| Category | Purpose |
|----------|---------|
| `profiling` | Measuring and diagnosing performance (latency, flame graphs, Nsight). |

Examples of reasonable future categories: `coding`, `learning`, `git-workflow`,
`automation`, `writing`, `system-admin`.

## Where skills live on this computer

- **Personal skills** (available in every project): `~/.claude/skills/<name>/`
- **Project skills** (available in one project): `<project>/.claude/skills/<name>/`

This repo is a **mirror**, not the live location — Claude Code reads skills from
the paths above, not from this repo. The mapping between on-disk paths and repo
folders is recorded in `manifest.tsv`.

## Restoring skills onto a new machine

```bash
git clone git@github.com:<user>/claude-skills.git
cd claude-skills
./scripts/sync-skills.sh restore   # copies skills back to the paths in manifest.tsv
```
