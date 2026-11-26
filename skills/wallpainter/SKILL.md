---
name: wallpainter
description: Visual, token-lean communication protocol. Use it whenever a reply would exceed about 8 lines, contains a decision between options, splits into sub-problems, or compares alternatives. The analysis goes onto a local HTML board (.wallpainter/) and the chat gets at most 5 lines with answer codes.
license: PolyForm-Noncommercial-1.0.0
---

# Wallpainter — visual, token-lean conversation protocol for coding agents

Skill version: 3.0.0 · License: PolyForm Noncommercial 1.0.0 · https://github.com/bausi2k/wallpainter

> Files: this `SKILL.md` (the core), `references/` (read on demand), `scripts/wp.sh` and `assets/index.html` (copied into each project, never read into context). Setup: `references/setup.md`.

## 0. Rules at a glance

1. Never answer with a wall of text. Explanations, analyses, comparisons and decisions go to the **board**; the chat gets at most 5 lines (§7). **Hard limit:** no bullets, tables, headings or summaries in chat, ever.
2. The board is one append-only event log, `.wallpainter/state.js`. You only **append** events (§2). You never rewrite or re-read it whole.
3. Every decision has options with random 4-hex **answer codes** plus an **own** code (references/codes.md).
4. Every sub-problem that needs its own decisions or several steps gets its own **topic** (one tab), linked to its parent (§5). Every topic has a **close code** and a **question code**; the user closes the topic or asks about it by typing them (references/codes.md).
5. After each turn, you keep the **focus** (current path) and the ranked **next** list up to date (§6).

## 1. When to use the board

Use it when your reply would exceed ~8 lines, contains a decision with 2+ options, splits into sub-problems, or compares states or alternatives.

Short replies (a fact, a yes/no, a confirmation) stay in chat, as does everything after `wp off`. When unsure whether a reply fits in 5 lines, use the board: a long chat reply is never the fallback.

User commands (case-insensitive, anywhere in a message):

| Command | Effect |
|---|---|
| `wp off` / `wp on` | Pause or resume the protocol for this session. |
| `wp` | Reprint open decisions and the next list in chat (§7 format). |
| `wp open` | Open the board in the system browser (references/setup.md, step 4). |
| `wp new <title>` | Archive the board (rename `state.js` to `state-<YYYYMMDD-HHMM>.js`), then start a fresh one. |
| `focus T3` | Make T3 the current topic. |

## 2. Events (cheat sheet)

Append all events of a turn with one call; it checks syntax and duplicate codes. Fields, kinds and an example: `references/events.md`.

```sh
.wallpainter/wp.sh append <<'WP'
W({t:"topic", id:"T2", title:"…", from:"T1", close:"c9e1", qa:"7d3a", md:"…"})
W({t:"step", id:"S4", in:"T2", kind:"note|diagram|compare|code|result|qa", title:"…", md:"…"})
W({t:"ask", id:"D2", in:"T2", q:"…", opts:[{c:"5b8d", h:"…", pro:"…", con:"…", rec:1}, {c:"9f1a", h:"…"}], own:"2d6c"})
W({t:"answer", d:"D2", c:"5b8d", note:"…"})
W({t:"status", in:"T2", s:"done|dropped|active|blocked", by:"c9e1", note:"…"})
W({t:"dep", in:"T3", on:"T2"})  W({t:"focus", in:"T2"})  W({t:"next", items:[{ref:"D2", why:"…"}]})  W({t:"patch", id:"S4", md:"…"})
WP
```

Codes are random 4-hex strings from `.wallpainter/wp.sh code`. IDs: `T`, `D`, `S` plus a running number, never reused (`grep -o 'id:"T[0-9]*"' .wallpainter/state.js | tail -1` finds the last one).

## 3. Reference map

- First use in a project, or the board's viewer is older than this skill: read `references/setup.md`.
- You create a decision, or the user's message has a code (answer, close, question) or starts with `neu - `: read `references/codes.md`.
- Unsure about a field, a step kind or the syntax: read `references/events.md`.

## 4. Token budget (mandatory)

- **Append only.** Never re-read `state.js` whole; use `grep`. Never rewrite `index.html`.
- **One idea per step.** `md` at most ~12 lines. Titles at most 6 words. Option labels at most 5 words. Each pro/con at most 8 words.
- **Pictures over prose.** Prefer `diagram`, `compare` or a table to a paragraph.
- **No duplication.** Never repeat board content in chat. Don't restate earlier steps; link them (`see S4`).
- **Batch.** One `wp.sh append` per turn.

## 5. Topics, branching, dependencies

- **Branch** (new `topic` with `from`) when a sub-problem needs its own decision(s) or several steps **and** can be worked or decided separately. A detail belongs in a step, not a branch.
- **Limit: at most 5 open topics at once.** Record a new sub-problem as a step first; promote it to a topic only when it needs its own decision or several steps. Before the 6th open topic, ask in one line which open topic to close or drop; do not open it before the answer.
- Set `status` `active` while working on a topic, `blocked` plus a `dep` when it waits for another topic, `done` when it is resolved (shown as a merge into its parent), and `dropped` (with `note`) when it is abandoned.
- `T1` is the root problem and stays open until the whole task is done. Add a `result` step before setting a topic `done`.

## 6. Focus and priority

- Emit `focus` whenever the work moves to another topic.
- Emit `next` at the end of every turn in which priorities changed. List 3–7 items (topics or decisions), most important first, each with a `why` of at most 10 words.
- Rank by: decisions that block other work first (the user's time is the bottleneck), then work that unblocks topics, then risk, then effort. Drop answered or closed items at the next update.
- The viewer marks a topic *ready* when it is open, waits for no open topic and has no open sub-topics. A `blocked` status backed by `dep` events ends when those topics close; `blocked` without a `dep` is an external blocker. Use `dep` and `status` precisely.

## 7. Chat reply format

After updating the board, reply in the user's language with **at most 5 lines**. A line is one short sentence or one template line; wrapped long text counts as several lines.

```
WP · T2 bcrypt cost (new, from T1 · close c9e1 · ask 7d3a) · +3 steps · 4/5 open
D2 Migrate hashes?  5b8d Rehash on login (rec) | 9f1a Batch job | 2d6c - own
Next: D2 → T3
```

- Line 1: the topic you worked on, its close code, what changed, and the number of open topics against the limit (`4/5 open`, §5).
- Lines 2–3: open decisions, each with its codes and short labels, so the user can answer without opening the board. Show at most 2 open decisions; the rest stay on the board (`+3 more on the board`).
- Last line: one Next entry. The ranked list stays on the board.
- **No second question:** if your environment adds its own next-step box or question, do not add another question in the text; the decisions and the Next entry above are the only prompts.
- Allowed on top, only when needed: one extra sentence for a single fact, and one short code block with a command the user must run or an error they must see.

**Hard rules**

- No bullet lists, tables, headings, bold-label paragraphs or "summary of findings" in chat. Findings, numbers and recommendations go to a board step; chat only points to it (`→ S12`).
- The same applies to the **closing message** of a task and to summaries produced by tools or the app (plan, wrap-up, recap): they follow this section too. Never write a report after the board update.
- **Self-check before sending:** count the lines. Is any sentence not needed to answer, decide or act? Is any content missing from the board? If so, move it to a step and cut it from the reply.

## 8. Every turn: checklist

1. Parse codes in the user's message: append `answer` events for answer codes, `status` events (with cascade) for close codes, and `qa` steps for question codes.
2. Do the work; add steps, topics, decisions, status changes, deps, `focus` and `next` as needed.
3. Write all events of the turn with one `.wallpainter/wp.sh append` call (it validates).
4. Reply in chat per §7.
