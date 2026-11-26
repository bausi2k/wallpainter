---
name: wallpainter
description: Visual, token-lean communication protocol. Use it whenever a reply would exceed about 8 lines, contains a decision between options, splits into sub-problems, or compares alternatives. The analysis goes onto a local HTML board (.wallpainter/) and the chat gets at most 5 lines with answer codes.
license: PolyForm-Noncommercial-1.0.0
---

# Wallpainter — visual, token-lean conversation protocol for coding agents

Skill version: 2.8.1 · License: PolyForm Noncommercial 1.0.0 · https://github.com/bausi2k/wallpainter

> Files: this `SKILL.md` (the protocol), `scripts/wp.sh` (helper) and `assets/index.html` (the viewer). Copy both into each project with the command in §3; never read them into context.
> Chat is linear, problems are a graph: the board is a local HTML page with a topic tree, one tab per topic and your ranked next steps. You write data events, never markup.

## 0. Rules at a glance

1. Never answer with a wall of text. Explanations, analyses, comparisons and decisions go to the **board**; the chat gets at most 5 lines (§9). **Hard limit:** no bullets, tables, headings or summaries in chat, ever.
2. The board is one append-only event log, `.wallpainter/state.js`. You only **append** events (§4). You never rewrite or re-read it whole.
3. Every decision has options with random 4-hex **answer codes**, plus an **own** code for the user's own solution (§6).
4. Every sub-problem that needs its own decisions or several steps gets its own **topic** (one tab), linked to its parent (§7). Every topic has a **close code** and a **question code**; the user closes the topic or asks about it by typing them (§6).
5. After each turn, you keep the **focus** (current path) and the ranked **next** list up to date (§8).

## 2. When to use the board

Use it when your reply would exceed ~8 lines, contains a decision with 2+ options, splits into sub-problems, or compares states or alternatives.

Answer in chat as usual when the reply is short (a fact, a yes/no, a one-line confirmation) or the user typed `wp off`.

When unsure whether the reply fits in 5 lines, use the board: a long chat reply is never the fallback.

User commands (case-insensitive, anywhere in a message):

| Command | Effect |
|---|---|
| `wp off` / `wp on` | Pause or resume the protocol for this session. |
| `wp` | Reprint open decisions and the next list in chat (§9 format). |
| `wp open` | Open the board in the system browser (§3, step 4). |
| `wp new <title>` | Archive the board (rename `state.js` to `state-<YYYYMMDD-HHMM>.js`), then start a fresh one. |
| `focus T3` | Make T3 the current topic. |
| `wp version` | Run `.wallpainter/wp.sh version <skill-dir>`; report installed vs. newest in one line and show the printed update command. Never run the update yourself; the user runs it, then types `/wallpainter`. |

## 3. Setup (once per project)

Run only if `.wallpainter/index.html` is missing, or if its `data-wp-version` is older than this skill's version.

1. Copy the viewer without loading it into context. `<skill-dir>` is the folder that contains this `SKILL.md`:
   ```sh
   mkdir -p .wallpainter
   cp <skill-dir>/assets/index.html .wallpainter/index.html
   cp <skill-dir>/scripts/wp.sh .wallpainter/wp.sh
   # or, if you loaded this skill from a URL:
   curl -fsSL <raw-url>/skills/wallpainter/assets/index.html -o .wallpainter/index.html
   curl -fsSL <raw-url>/skills/wallpainter/scripts/wp.sh -o .wallpainter/wp.sh
   ```
   Without shell access, copy `assets/index.html` unchanged and append events with your edit tool instead of `wp.sh`.
2. Create `.wallpainter/state.js`:
   ```js
   // Wallpainter event log - append only. Format: wallpainter SKILL.md section 4.
   W({t:"board", title:"<short goal>", lang:"<user language, e.g. de>"})
   ```
3. Add `.wallpainter/` to `.gitignore` (default). Say so in one chat line; if the user wants the board versioned, remove the entry.
4. Open the board once in the user's **system browser**: `open .wallpainter/index.html` on macOS, `xdg-open` on Linux, `start` on Windows. It reloads `state.js` every 2 s by itself.
   Never open it via `file://` in an embedded agent browser (for example a browser pane of your own app). Such panes often show static snapshots or `data:` copies that cannot reach `state.js`, so the board stays empty. If the user wants it inside such a pane, serve it locally and open `http://localhost:8766`:
   ```sh
   python3 -m http.server 8766 --bind 127.0.0.1 --directory .wallpainter
   ```

## 4. Event log format

`state.js` is plain JavaScript: one `W({...})` call per event, in chronological order. Keys may be unquoted. For multi-line text use template literals (`` `...` ``) and escape `` ` `` and `${` inside them.

Append with one call per turn. `wp.sh append` checks the syntax (with `node` if present) and rejects a code that is already on the board or repeated in the batch; on an error nothing is written:

```sh
.wallpainter/wp.sh append <<'WP'
W({t:"step", id:"S7", in:"T2", kind:"note", title:"...", md:`...`})
W({t:"next", items:[{ref:"D3", why:"..."}]})
WP
```

`.wallpainter/wp.sh code` prints a fresh unused 4-hex code. Without shell access, append the lines to the end of the file with your edit tool and keep codes unique yourself.

### IDs

- Topics `T1, T2, ...`; decisions `D1, D2, ...`; steps `S1, S2, ...`. Sequential per board, never reused.
- If you lost track (for example after context compaction), find the last one: `grep -o 'id:"T[0-9]*"' .wallpainter/state.js | tail -1`.
- Recover the board skeleton cheaply: `grep -E 't:"(topic|ask|answer|status|dep|focus|next)"' .wallpainter/state.js`.
- `T1`, `D2`, `S3` written in any text field become clickable links in the viewer.

### Event reference

| `t` | Fields | Meaning |
|---|---|---|
| `board` | `title`, `lang` (`de`, `en`, ...) | Board title and UI language. First line. |
| `topic` | `id`, `title`, `close`, `qa`, `md?`, `from?` | New topic or tab. `close` is its close code and `qa` its question code (§6). `from` is the parent topic it branched off. |
| `step` | `id`, `in`, `kind`, `title`, plus kind fields, `md?` | One unit of explanation inside topic `in`. |
| `ask` | `id`, `in`, `q`, `md?`, `opts`, `own` | A decision. See §6. |
| `answer` | `d`, `c`, `note?` | The user's answer to decision `d`: code `c` and their own text in `note`. |
| `status` | `in`, `s`, `by?`, `note?` | `s`: `open`, `active`, `blocked`, `done`, `dropped`. `done` and `dropped` close the branch. `by` is the close code the user typed. |
| `dep` | `in`, `on`, `note?` | Topic `in` depends on, or waits for, topic `on`. |
| `focus` | `in` | Current topic. The viewer highlights its path from the root. |
| `next` | `items:[{ref, why}]` | Your ranked to-do list for the overview. Replaces the previous list. |
| `patch` | `id`, fields... | Correct an earlier topic, step or decision by id. Never edit old lines. |

Step kinds:

| `kind` | Extra fields | Use for |
|---|---|---|
| `note` | `md` | Short explanation. This is the default. |
| `diagram` | `mermaid` | Flows, architecture, sequences (Mermaid syntax). The cheapest way to show structure. |
| `compare` | `a:{h, md}`, `b:{h, md}` | Left/right: current vs. target state, option A vs. B. |
| `code` | `code`, `lang` | Snippets. `lang:"diff"` colours `+` and `-` lines. |
| `result` | `md` | Outcome or conclusion of a topic (highlighted). |
| `qa` | `q`, `a`, `ref?` | The user's question about a topic and your answer; `ref` is the card it is about (§6, Questions). |

`md` supports paragraphs, `- lists`, `1. lists`, `**bold**`, `` `code` ``, fenced code, `#` headings, `[text](url)` and `| pipe | tables |`.

## 5. Token budget (mandatory)

- **Append only.** Never re-read `state.js` whole; use `grep`. Never rewrite `index.html`.
- **One idea per step.** `md` at most ~12 lines. Titles at most 6 words. Option labels at most 5 words. Each pro/con at most 8 words.
- **Pictures over prose.** Prefer `diagram`, `compare` or a table to a paragraph.
- **No duplication.** Never repeat board content in chat; link earlier steps (`see S4`).
- **Batch.** One `wp.sh append` per turn.

## 6. Decisions, answer codes and close codes

```js
W({t:"ask", id:"D2", in:"T2", q:"How do we migrate existing hashes?", md:"optional context", opts:[
  {c:"5b8d", h:"Rehash on login", md:"optional detail", pro:["no downtime","no batch job"], con:"inactive users keep old cost", rec:1},
  {c:"9f1a", h:"Batch job", con:"impossible without plaintext"}
], own:"2d6c"})
```

- All codes (option, own and close codes) are **4 random lowercase hex characters**, unique on the board. They are not sequential and not derived from the text. Get unused codes with `.wallpainter/wp.sh code`. **Never type codes by hand**: `wp.sh append` rejects anything that is not exactly 4 lowercase hex characters. The own code must differ from the option codes of the same decision.
- Every `ask` has 2–4 `opts` and one `own` code. Mark at most one option `rec:1` (your recommendation).
- Ask only what the user must decide. Don't turn something you can decide yourself into an `ask`; record it as a `note`.
- **Reading answers.** The user replies in chat with codes, separated by commas or newlines:
  - `5b8d`: choose this option.
  - `5b8d - but log every rehash`: choose it with an amendment.
  - `2d6c - use argon2 instead`: their own solution (the `own` code).
  - A topic's close code: close that topic (see below).
  - Free text without a code: map it to the decision if that is unambiguous; otherwise ask back in one line.
  - An unknown code: ask back in one line. Never guess.
- Record each answer immediately: `W({t:"answer", d:"D2", c:"5b8d", note:"but log every rehash"})`. Then act on it. Never ask the same question again.

### Questions

Every `topic` also carries `qa:"<code>"`, a second code (different from `close`) for questions:

- `7d3a - Why cost 12?`: a question about that topic. Without text after the code, ask back in one line.
- `7d3a S4 - Why this value?`: a question about one card. The id (`S4`, `D2`, ...) sits between code and dash; the viewer's ID chip on each card copies this prefix. Answer as below with `ref:"S4"`, and answer about that card, not the whole topic.
- Answer on the board, not in chat: append `W({t:"step", id:"S20", in:"T2", kind:"qa", title:"Question", q:"Why cost 12?", ref:"S4", a:"<answer in md>"})` (`ref` only when the question named a card) to that topic, with a diagram or code block in `a` if it helps.
- Chat gets one line: `WP · answer in T2 → S20`, plus at most one sentence if the answer is a single fact.
- A question changes neither status, focus nor `next`. Only if the answer reveals a new problem, open a new topic or decision.
- Questions about a decision are possible too: put them in the decision's topic and name the decision (`D2`) in `q`.

### New topics

The overview shows a **New topic** tag; clicking it copies `neu - ` (`new - ` if the board language is not German). A user message that starts with this keyword and ` - ` starts a topic:

- `neu - Cache layer`: new root-level topic `Cache layer`, branched from `T1`.
- `neu T2 - Cache layer`: new topic branched from `T2`.
- Create it like any topic (§7): own `close` and `qa` codes, a first `note` step with what you understood, `focus` on it and `next`. If the title is empty or unclear, ask back in one line.
- Free text like "new topic: …" works too, but the keyword form is the unambiguous one.

### Close codes

Every `topic` carries `close:"<code>"`, so the user can end a problem at any time:

- `c9e1`: close the topic as `done`.
- `c9e1 - <text>`: close it with that note. Use `dropped` instead of `done` if the text says to abandon or discard it.
- Record it: `W({t:"status", in:"T2", s:"done", by:"c9e1", note:"deploy ok"})`.
- **Cascade**: close every sub-topic with status `open` or `blocked` as well, with the same `s` and `note:"closed with T2"`, but no `by`. Open decisions inside closed topics need no answer anymore.
- **Active sub-topics stay open.** A sub-topic with status `active` is being worked on, so closing its parent must not close it. Name them in the chat line (`T3 stays open (active)`); the user closes them with their own code.
- **Afterwards**:
  - Topics that waited for the closed one are free again; continue with them.
  - If the closed topic had the focus, set `focus` to its parent.
  - Update `next`.
- Closing the root topic (`T1`) ends the board's task. Reply with a one-line summary.
- Close a topic yourself only when its result is verified (for example, tests pass). Otherwise add a `result` step and let the user close it by code.

## 7. Topics, branching, dependencies

- **Branch** (new `topic` with `from`) when a sub-problem needs its own decision(s) or several steps **and** can be worked or decided separately; a detail is a step.
- **Limit: at most 5 open topics at once.** Record a new sub-problem as a step first; promote it to a topic only when it needs its own decision or several steps. Before the 6th open topic, ask in one line which open topic to close or drop; do not open it before the answer.
- Set `status` `active` while working on a topic, `blocked` plus a `dep` when it waits for another topic, `done` when it is resolved (shown as a merge into its parent), and `dropped` (with `note`) when it is abandoned.
- The first topic (`T1`) is the root problem and stays open until the whole task is done.
- Close a topic with a `result` step before setting `done`.

## 8. Focus and priority

- Emit `focus` whenever the work moves to another topic.
- Emit `next` at the end of every turn in which priorities changed. List 3–7 items (topics or decisions), most important first, each with a `why` of at most 10 words.
- Rank by:
  1. decisions that block other work, because the user's time is the bottleneck;
  2. work that unblocks other topics;
  3. risk;
  4. effort.
- The viewer greys out items that are answered or closed. Remove them at the next update.
- The viewer marks a topic *ready* when it is open, waits for no open topic and has no open sub-topics (Mikado principle: work the leaves first). A `blocked` status backed by `dep` events ends when those topics close; `blocked` without a `dep` means an external blocker and stays until you change the status. Use `dep` and `status` precisely so this stays correct.

## 9. Chat reply format

After updating the board, reply in the user's language with **at most 5 lines**. A line is one short sentence or one template line; wrapped long text counts as several lines.

```
WP · T2 bcrypt cost (new, from T1 · close c9e1 · ask 7d3a) · +3 steps · 4/5 open
D2 Migrate hashes?  5b8d Rehash on login (rec) | 9f1a Batch job | 2d6c - own
Next: D2 → T3
```

- Line 1: the topic you worked on, its close code, what changed, and the number of open topics against the limit (`4/5 open`, §7).
- Lines 2–3: open decisions, each with its codes and short labels, so the user can answer without opening the board. Show at most 2 open decisions; the rest stay on the board (`+3 more on the board`).
- Last line: one Next entry. The ranked list stays on the board.
- **No second question:** if your environment adds its own next-step box or question, do not add another question in the text; the decisions and the Next entry above are the only prompts.
- Allowed on top, only when needed: one extra sentence for a single fact, and one short code block with a command the user must run or an error they must see.

**Hard rules**

- No bullet lists, tables, headings, bold-label paragraphs or "summary of findings" in chat. Findings, numbers and recommendations go to a board step; chat only points to it (`→ S12`).
- The same applies to the **closing message** of a task and to summaries produced by tools or the app (plan, wrap-up, recap): they follow this section too. Never write a report after the board update.
- **Self-check before sending:** count the lines. Is any sentence not needed to answer, decide or act? Is any content missing from the board? If so, move it to a step and cut it from the reply.

## 10. Every turn: checklist

1. Parse codes in the user's message: append `answer` events for answer codes, `status` events (with cascade) for close codes, and `qa` steps for question codes.
2. Do the work; add steps, topics, decisions, status changes, deps, `focus` and `next` as needed.
3. Write all events of the turn with one `.wallpainter/wp.sh append` call (it validates).
4. Reply in chat per §9.

## 11. Example (one turn)

User: "Login takes 4 s, fix it." You append a root topic with a diagram and a profile table, two sub-topics (T2 bcrypt cost, T3 index, `dep` T3 on T2), a decision `D1` with codes, `focus` and `next`, in one `wp.sh append`. Chat:

```
WP · T1 analysed (close f3a0, ask a8d5), split into T2 bcrypt cost (c9e1/7d3a) and T3 index (b7d2/e46c) · 3/5 open
D1 bcrypt cost?  a3f9 12 (rec) | 7c2e 10 | e01d - own
Next: D1 → T3
```
