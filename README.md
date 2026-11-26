# Wallpainter

**Stop the wall of text.** Wallpainter is an [Agent Skill](https://agentskills.io) (`skills/wallpainter/`) that you hand to a coding agent (Claude Code, Codex, Gemini CLI, Antigravity, Cursor, ...). It tells the agent to explain its work on a visual, local HTML board instead of in long chat messages.

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/bausi2k)

## The problem

Long agent sessions turn into scrollback soup:

- **One problem becomes three.** Sub-problems, dependencies and side paths are buried in linear text.
- **Decisions get lost.** Options are spread over paragraphs, and it is unclear what was decided and what is still open.
- **No overview.** Where are we on the path? What should happen next?

## What Wallpainter does

```
┌ Overview ─┬ T1 Login slow ─┬ T2 bcrypt ●1 ─┬ T3 Index ─┐
│                                                        │
│ [Structure | History]            │  Up next            │
│ ┌┄ ● T1 Login takes 4 s          │  1 D2 Migrate hash? │
│ ┆  ├─ ● T2 bcrypt cost   ready   │    blocks T2 deploy │
│ ┆  │   └─ ◆ D2 Migrate? decide   │  2 T3 Index         │
│ └┄►├─ ● T3 Index    waits for T2 │    waits for T2     │
│    └─ ○ T4 Sessions   dropped    │                     │
└────────────────────────────────────────────────────────┘
```

- **One board per project** at `.wallpainter/index.html`. It reloads by itself while the agent works.
- **Overview, structure view**: problem → sub-problems as a tree, open decisions as ◆ leaves, red "waits for" arcs, the current path in bold. Topics that can be worked on right now are marked *ready* (Mikado principle: leaves first). The ranked list of what to do or decide next sits beside it.
- **Overview, history view**: a git-style graph showing when topics branched off and merged back.
- **One tab per topic**: every sub-problem gets its own tab with a top-to-bottom timeline of steps: notes, Mermaid diagrams, side-by-side before/after comparisons, diffs and results.
- **Decisions with answer codes**: each option gets a short random code. You answer in chat by typing the code.
- **Close codes**: every topic has its own code. Typing it closes the problem.
- **Question codes**: a second code per topic lets you ask questions that are answered on the board.
- **Short chat**: the agent replies with at most 5 lines and points to the board. Hard limit: no bullet lists, tables or summaries in chat, and the closing message follows the same rule. At most 5 topics are open at once, and the chat shows at most 2 open decisions and one next step.

## Answering decisions

Every decision card shows codes. Clicking a code copies it.

| You type | Meaning |
|---|---|
| `5b8d` | Take option 5b8d. |
| `5b8d - but log every rehash` | Take it, with your amendment. |
| `2d6c - use argon2 instead` | Your own solution (every decision has an "own" code). |
| `5b8d, a3f9` | Answer several decisions at once. |

## Closing a topic

Every topic (problem) has its own close code. It is shown in the topic header and in the structure tree, and the agent's first chat line names it too.

| You type | Meaning |
|---|---|
| `c9e1` | Topic solved: closed as *done*. |
| `c9e1 - deploy ok` | Closed, with your note. |
| `c9e1 - not worth it` | Closed as *dropped*. |

Closing a topic also closes its sub-topics that are open or blocked; sub-topics that are being worked on (*active*) stay open and the agent names them. Its open decisions disappear, and topics that waited for it become *ready*.

## Starting a topic

The overview has a **＋ New topic** tag. Click it, type the title, send:

| You type | Meaning |
|---|---|
| `neu - Cache layer` | A new topic (`new - ` on English boards). |
| `neu T2 - Cache layer` | A new topic branched from `T2`. |

## Asking about a topic

Every topic also has a **question code**, shown in the topic header next to the close code (click to copy; the dash is included).

| You type | Meaning |
|---|---|
| `7d3a - Why cost 12?` | A question about that topic. |
| `7d3a S4 - Why this value?` | A question about one card (`S4`). |

Every card shows its ID as a small chip. Clicking it copies the prepared prefix (`7d3a S4 - `), you only type the question.

The agent answers on the board as a question/answer card in that topic's timeline and replies in chat with one line. A question changes neither status nor focus.

## Commands

| Command | Effect |
|---|---|
| `wp off` / `wp on` | Pause or resume the protocol. |
| `wp` | Reprint open decisions and the next list in chat. |
| `wp open` | Open the board in your browser. |
| `wp new <title>` | Archive the current board and start a new one. |
| `focus T3` | Switch the current topic. |

## Installation

Wallpainter is a folder: `SKILL.md` (the protocol), `scripts/wp.sh` (a helper that validates and appends events) and `assets/index.html` (the viewer). Pick one of four ways:

| | 1. Instruction file | 2. Claude Code skill | 3. Antigravity skill | 4. Claude Code plugin |
|---|---|---|---|---|
| Works with | any agent | Claude Code | Google Antigravity | Claude Code |
| Protocol in context | every session | only when a board is needed | only when a board is needed | only when a board is needed |
| You add | folder + block in `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` | folder + one-line rule in `CLAUDE.md` | folder + one-line rule | one command, no `CLAUDE.md` edit |

All commands pin a release (`v2.7.0`), so changes in this repository never reach your sessions unannounced. To update, run the download again with the newest [tag](https://github.com/bausi2k/wallpainter/tags).

### 1. Instruction file (any agent)

```bash
D=~/.wallpainter; U=https://raw.githubusercontent.com/bausi2k/wallpainter/v2.7.0/skills/wallpainter; for f in SKILL.md scripts/wp.sh assets/index.html; do mkdir -p $D/$(dirname $f) && curl -fsSL $U/$f -o $D/$f; done
```

```markdown
## Communication (Wallpainter)
Follow the Wallpainter protocol in `~/.wallpainter/SKILL.md`; read it at session start.
```

Without a download, point the block at the URLs instead and load them with `curl` (not a web-fetch tool, which may summarise the file): `https://raw.githubusercontent.com/bausi2k/wallpainter/v2.7.0/skills/wallpainter/SKILL.md` and `https://raw.githubusercontent.com/bausi2k/wallpainter/v2.7.0/skills/wallpainter/assets/index.html`.

### 2. Claude Code skill

```bash
D=~/.claude/skills/wallpainter; U=https://raw.githubusercontent.com/bausi2k/wallpainter/v2.7.0/skills/wallpainter; for f in SKILL.md scripts/wp.sh assets/index.html; do mkdir -p $D/$(dirname $f) && curl -fsSL $U/$f -o $D/$f; done
```

Skills load on demand, but Wallpainter is a way of communicating, so add a one-line rule to `~/.claude/CLAUDE.md`:

```markdown
## Communication (Wallpainter)
For any reply longer than ~8 lines, with a decision between options, or with several sub-problems: use the `wallpainter` skill (board instead of chat).
```

### 3. Google Antigravity skill (not tested yet)

Copy the folder into Antigravity's skills directory: per project `.agents/skills/wallpainter/`, or the global skills folder named in the [Antigravity docs](https://antigravity.google/docs/skills). Then add the same one-line rule as an Antigravity rule (for example `.agents/rules/wallpainter.md`).

```bash
D=.agents/skills/wallpainter; U=https://raw.githubusercontent.com/bausi2k/wallpainter/v2.7.0/skills/wallpainter; for f in SKILL.md scripts/wp.sh assets/index.html; do mkdir -p $D/$(dirname $f) && curl -fsSL $U/$f -o $D/$f; done
```

### 4. Claude Code plugin

```text
/plugin marketplace add bausi2k/wallpainter
/plugin install wallpainter@wallpainter
```

On Claude Code 2.1.275 or later one command does both: `/plugin install wallpainter --marketplace bausi2k/wallpainter`.

The plugin ships the skill and a `SessionStart` hook that adds the short rule to every session, so no `CLAUDE.md` edit is needed. Remove the one-line rule from way 2 if you used it before. Update with `/plugin update wallpainter`; the next session loads the new version.

### What happens next

On first use in a project, the agent creates `.wallpainter/`, copies the viewer there, adds `.wallpainter/` to `.gitignore` and opens the board in your system browser.

### Updating a skill folder (ways 2 and 3)

Version 2.7.0 added `scripts/wp.sh`: run the download command again (it fetches all files) with the newest [tag](https://github.com/bausi2k/wallpainter/tags), then type `/wallpainter` in your session so the agent re-reads `SKILL.md`. The agent also copies a newer viewer into the project (`data-wp-version`).

### Upgrading from 1.x

Version 2.0.0 replaced the single file `wallpainter.skill` with the skill folder. Download the folder with one of the commands above, and in your instruction file replace `wallpainter.skill` with `SKILL.md` (way 1) or with the one-line rule (way 2). Existing boards keep working. Installations pinned to `v1.3.x` keep working too.

## Availability

Wallpainter is public, but nothing installs it for you: every user has to install it themselves with one of the four ways above. For Claude Code that is two commands (way 4).

- **Where:** this repository is the plugin and its own marketplace. It is not listed in an official plugin directory.
- **License:** [PolyForm Noncommercial 1.0.0](LICENSE). Personal, research and educational use is fine; commercial use is not permitted.
- **Not verified:** a real plugin install from GitHub in a clean environment (the manifests pass `claude plugin validate .`), and the skill in Cursor, Codex, Gemini CLI and Antigravity.
- **Updates:** nothing updates silently. Plugin users run `/plugin update wallpainter`; skill-folder and instruction-file users download the newest [tag](https://github.com/bausi2k/wallpainter/tags).

## Token efficiency

Wallpainter is designed to cost fewer tokens than a wall of text:

- **Data, not markup.** The agent appends compact events (`W({t:"step", ...})`) to `.wallpainter/state.js`. The viewer is copied once with `cp`, without passing through the model.
- **Append-only.** The agent never re-reads or rewrites the board; it looks things up with `grep`.
- **Pictures over prose.** Mermaid diagrams, compare cards and diffs replace paragraphs.
- **One call per turn.** `wp.sh append` checks syntax and duplicate codes and appends, replacing separate `grep` and `node --check` calls.
- **Protocol on demand.** As a skill (ways 2 to 4), only its name and description sit in the context until a board is needed. Through an instruction file (way 1), the protocol (about 16,500 characters) is loaded every session.

A measured note: splitting the protocol into a core plus reference files did not lower the total tokens (the agents read all parts in a new project), so the protocol stays a single file.

## How it works

```
.wallpainter/
├── index.html   # static viewer (copied from skills/wallpainter/assets/index.html)
├── wp.sh        # helper: fresh codes, validated append (copied from skills/wallpainter/scripts/wp.sh)
└── state.js     # append-only event log written by the agent
```

The viewer polls `state.js` every 2 seconds. It works from `file://` without a server or build step, and without dependencies except Mermaid, which loads from a CDN when the board contains a diagram. Offline, diagrams show their source text. It is usable on phones.

**Hiding tabs**: every topic tab (except the overview and tabs with an open decision) has a × that hides it from the tab bar without ending the topic. "Hidden (n)" shows hidden tabs again, and opening a topic from the tree or a link unhides it. This is stored per browser only; the agent and other browsers still see every tab.

**Light and dark mode**: the board follows your system setting. The `◐` button in the header cycles through Auto, Light and Dark; the browser remembers your choice.

The event format is documented in `skills/wallpainter/SKILL.md`, section 4.

## Repository

| File | Purpose |
|---|---|
| `README.md` | This document. |
| `skills/wallpainter/SKILL.md` | The protocol for the agent (Agent Skills format). |
| `skills/wallpainter/scripts/wp.sh` | Helper: fresh codes, validated append. |
| `skills/wallpainter/assets/index.html` | The board viewer, copied into each project. |
| `LICENSE` | PolyForm Noncommercial 1.0.0. |

## License

[PolyForm Noncommercial 1.0.0](LICENSE): free for personal, research, educational and other noncommercial use. Commercial use is not permitted.

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/bausi2k)
