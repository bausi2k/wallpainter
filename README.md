# Wallpainter

**Stop the wall of text.** Wallpainter is a single instruction file (`wallpainter.skill`) that you hand to a coding agent (Claude Code, Codex, Gemini CLI, Antigravity, Cursor, ...). It tells the agent to explain its work on a visual, local HTML board instead of in long chat messages.

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/bausi2k)

## The problem

Long agent sessions turn into scrollback soup:

- **One problem becomes three.** Sub-problems, dependencies and side paths are buried in linear text.
- **Decisions get lost.** Options are spread over paragraphs, and it is unclear what was decided and what is still open.
- **No overview.** Where are we on the path? What should happen next?

## What Wallpainter does

```
┌ Overview ─┬ T1 Login slow ─┬ T2 bcrypt ●2 ─┬ T3 Index ─┐
│                                                        │
│  Path                            │  Up next            │
│  ●─────── T1 Login takes 4 s     │  1 D2 Migrate hash? │
│  ├──●     T2 bcrypt cost         │    blocks T2 deploy │
│  │  ◆     ? D1 Where to start    │  2 T3 Index         │
│  ├──┼──●  T3 Index users.email   │    waits for T2     │
│  │  │  ┆→ waits for T2           │                     │
│  │  ●     ✓ D1 → a3f9 cost 12    │  Open decisions     │
│  │  ◆     ? D2 Migrate hashes    │  D2 5b8d·9f1a·2d6c -│
└────────────────────────────────────────────────────────┘
```

- **One board per project** at `.wallpainter/index.html`. It reloads by itself while the agent works.
- **Overview**: a git-style graph of all topics (branches, merges, dependencies; the current path is highlighted), with the agent's ranked list of what to do or decide next beside it.
- **One tab per topic**: every sub-problem gets its own tab with a top-to-bottom timeline of steps: notes, Mermaid diagrams, side-by-side before/after comparisons, diffs and results.
- **Decisions with answer codes**: each option gets a short random code. You answer in chat by typing the code.
- **Short chat**: the agent replies with at most 5 lines and points to the board.

## Answering decisions

Every decision card shows codes. Clicking a code copies it.

| You type | Meaning |
|---|---|
| `5b8d` | Take option 5b8d. |
| `5b8d - but log every rehash` | Take it, with your amendment. |
| `2d6c - use argon2 instead` | Your own solution (every decision has an "own" code). |
| `5b8d, a3f9` | Answer several decisions at once. |

## Commands

| Command | Effect |
|---|---|
| `wp off` / `wp on` | Pause or resume the protocol. |
| `wp` | Reprint open decisions and the next list in chat. |
| `wp open` | Open the board in your browser. |
| `wp new <title>` | Archive the current board and start a new one. |
| `focus T3` | Switch the current topic. |

## Installation

1. Download the skill file once:

   ```bash
   mkdir -p ~/.wallpainter && curl -fsSL https://raw.githubusercontent.com/bausi2k/wallpainter/main/wallpainter.skill -o ~/.wallpainter/wallpainter.skill
   ```

2. Reference it in your agent's instruction file: `CLAUDE.md` (Claude Code), `AGENTS.md` (Codex and others) or `GEMINI.md` (Gemini CLI). Use the global file to enable it everywhere, or a project file for one repository:

   ```markdown
   ## Communication
   Follow the Wallpainter protocol in `~/.wallpainter/wallpainter.skill`.
   At session start, read it up to the line "## Appendix A" (never read the appendix):
   `sed -n '1,/^## Appendix A/p' ~/.wallpainter/wallpainter.skill`
   ```

On first use in a project, the agent creates `.wallpainter/`, extracts the viewer from the skill file with a shell command, adds `.wallpainter/` to `.gitignore` and opens the board.

> Avoid `@`-importing the whole file (for example `@~/.wallpainter/wallpainter.skill` in `CLAUDE.md`). That would load the ~490-line viewer into every session.

## Token efficiency

Wallpainter is designed to cost fewer tokens than a wall of text:

- **Data, not markup.** The agent appends compact events (`W({t:"step", ...})`) to `.wallpainter/state.js`. The viewer is written once by `awk`, without passing through the model.
- **Append-only.** The agent never re-reads or rewrites the board; it looks things up with `grep`.
- **Pictures over prose.** Mermaid diagrams, compare cards and diffs replace paragraphs.
- **Protocol only.** Only the protocol part (~210 lines) is loaded into context.

## How it works

```
.wallpainter/
├── index.html   # static viewer (from wallpainter.skill, Appendix A)
└── state.js     # append-only event log written by the agent
```

The viewer polls `state.js` every 2 seconds. It works from `file://` without a server or build step, and without dependencies except Mermaid, which loads from a CDN when the board contains a diagram. Offline, diagrams show their source text. It supports light and dark mode and is usable on phones.

The event format is documented in `wallpainter.skill`, section 4.

## Repository

| File | Purpose |
|---|---|
| `README.md` | This document. |
| `wallpainter.skill` | Instructions for the agent, with the embedded viewer. |
| `LICENSE` | PolyForm Noncommercial 1.0.0. |

## License

[PolyForm Noncommercial 1.0.0](LICENSE): free for personal, research, educational and other noncommercial use. Commercial use is not permitted.

[![Buy Me A Coffee](https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png)](https://www.buymeacoffee.com/bausi2k)
