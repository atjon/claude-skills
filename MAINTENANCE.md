# MAINTENANCE.md — Rules for Claude

**Audience: Claude Code.** If you are a Claude session touching skills on this
computer, read this whole file before doing anything. These constraints were set
by the user (atjon) on 2026-07-18 and apply to *every* Claude session on this
machine, forever, unless the user changes them.

## The standing rule

> Whenever you create, edit, rename, or delete a Claude Code skill anywhere on
> this computer, you MUST sync it into this repository and push to GitHub in the
> same session. No exceptions, no "I'll do it later."

This repo lives at `~/claude-skills` and mirrors every skill on the machine.

## Workflow: adding or editing a skill

1. **Create/edit the skill in its live location** (Claude Code reads from there,
   not from this repo):
   - Personal skill (usable in all projects): `~/.claude/skills/<skill-name>/SKILL.md`
   - Project skill (one project only): `<project>/.claude/skills/<skill-name>/SKILL.md`
2. **Pick a category** — what the skill is *used for* (e.g. `coding`,
   `learning`, `automation`). Reuse an existing category from `skills/` if one
   fits; only create a new one if nothing fits. Categories are kebab-case.
3. **Register it in `manifest.tsv`** (tab-separated:
   `skill-name<TAB>category<TAB>absolute-source-path`). One line per skill.
   Use `$HOME`-relative paths written as `~/...` so the manifest is portable.
4. **Run the sync script**: `~/claude-skills/scripts/sync-skills.sh`
   It copies every manifest entry into `skills/<category>/<skill-name>/`,
   commits, and pushes.
5. **If you added a new category**, update the Categories table in `README.md`
   *before* running the sync.

## Workflow: deleting a skill

1. Delete the live copy on disk.
2. Remove its line from `manifest.tsv`.
3. Run `sync-skills.sh` — it removes repo copies that are no longer in the
   manifest, commits, and pushes.

## Proactive skill creation

The user has a standing request (2026-07-18): when they ask for something
recurring — the same request more than once, or an obviously repeatable
task/question — do the task, then create a skill for it automatically:

1. Check `manifest.tsv` first; if a skill already covers it, use or improve
   that one instead of duplicating.
2. Otherwise create the skill, register it, and sync in the same session
   (normal workflow above).
3. Tell the user which skill was created and why, so they can veto it.

Detection is judgment-based, not automated: notice repetition within a session,
and record recurring request patterns in the project's Claude memory directory
so future sessions can spot the second occurrence.

## What counts as a skill for this repo

Only skills that exist as files on this machine: `~/.claude/skills/<name>/` and
`<project>/.claude/skills/<name>/`. Claude Code's **built-in** skills (dataviz,
loop, run, init, review, etc.) ship inside the app, appear in every project
automatically, and must NOT be added to the manifest — Anthropic maintains
those. Same for skills installed from plugin marketplaces: they're managed by
the plugin system, not this repo.

## Constraints (do not violate)

- **The manifest is the source of truth.** Never hand-copy files into `skills/`;
  always go through `manifest.tsv` + `sync-skills.sh` so repo and disk never
  drift.
- **One skill = one folder** containing at least `SKILL.md` with valid
  frontmatter (`name`, `description`).
- **Categories are by purpose, not technology.** "What do I use this for?" not
  "what language is it about?"
- **Keep the README's category table in sync** with the folders under `skills/`.
- **Never force-push.** If the push is rejected, pull --rebase and push again.
- **This repo is public.** Never let a skill containing secrets, tokens, or
  private personal data into the manifest. If a skill needs a secret, the skill
  reads it from the environment; the secret never enters this repo.
- **Commit messages**: `sync: add <skill> (<category>)`,
  `sync: update <skill>`, or `sync: remove <skill>`, plus the standard
  Claude co-author trailer.
- **If anything here seems outdated or blocking, ask the user** — do not
  silently change the rules in this file. Only update MAINTENANCE.md when the
  user approves a rule change.

## Why it's set up this way (context for future sessions)

- The user wants a permanent, reproducible, well-documented home for all skills
  so any future Claude session (or a fresh machine) can pick up where the last
  one left off.
- Skills stay in their live locations because that's where Claude Code loads
  them from; the repo is a synced mirror plus documentation.
- A persistent memory in Claude's memory directory points at this file, so
  future sessions know to come here. If you're reading this without such a
  memory, recreate it: a `feedback`-type memory saying "whenever you create or
  edit a skill, follow ~/claude-skills/MAINTENANCE.md".
