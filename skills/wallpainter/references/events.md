# Event log format

Read this when you are unsure about fields, kinds or ids. The one-line forms are in `SKILL.md`.

`state.js` is plain JavaScript: one `W({...})` call per event, in chronological order. Keys may be unquoted. For multi-line text use template literals (`` `...` ``) and escape `` ` `` and `${` inside them.

Append with one call per turn. `wp.sh append` checks the syntax (with `node` if present) and rejects codes that are already on the board, then appends; on an error nothing is written:

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
| `topic` | `id`, `title`, `close`, `qa`, `md?`, `from?` | New topic or tab. `close` is its close code and `qa` its question code (`codes.md`). `from` is the parent topic it branched off. |
| `step` | `id`, `in`, `kind`, `title`, plus kind fields, `md?` | One unit of explanation inside topic `in`. |
| `ask` | `id`, `in`, `q`, `md?`, `opts`, `own` | A decision. See `codes.md`. |
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
| `qa` | `q`, `a`, `ref?` | The user's question about a topic and your answer; `ref` is the card it is about (`codes.md`, Questions). |

`md` supports paragraphs, `- lists`, `1. lists`, `**bold**`, `` `code` ``, fenced code, `#` headings, `[text](url)` and `| pipe | tables |`.

## Example (one turn)

User: "Login takes 4 s, fix it."

```js
W({t:"topic", id:"T1", title:"Login takes 4 s", close:"f3a0", qa:"a8d5", md:"Target < 500 ms."})
W({t:"step", id:"S1", in:"T1", kind:"diagram", title:"Current flow", mermaid:`flowchart LR
  B[Browser] --> A[/login] --> H[bcrypt cost 14]
  A --> D[(users, no index on email)]`})
W({t:"step", id:"S2", in:"T1", kind:"note", title:"Profile (200 logins)", md:"| part | time |\n|---|---|\n| bcrypt | **2.9 s** |\n| user lookup | 0.9 s |\n| session write | 0.3 s |"})
W({t:"topic", id:"T2", title:"bcrypt cost", from:"T1", close:"c9e1", qa:"7d3a"})
W({t:"topic", id:"T3", title:"Index users.email", from:"T1", close:"b7d2", qa:"e46c"})
W({t:"dep", in:"T3", on:"T2", note:"measure after T2"})
W({t:"ask", id:"D1", in:"T2", q:"Lower bcrypt cost to?", opts:[{c:"a3f9", h:"12", pro:"~0.7 s, OWASP ok", rec:1},{c:"7c2e", h:"10", con:"below OWASP minimum"}], own:"e01d"})
W({t:"focus", in:"T2"})
W({t:"next", items:[{ref:"D1", why:"blocks T2 and T3"},{ref:"T3", why:"cheap win once T2 is merged"}]})
```

Chat:

```
WP · T1 analysed (close f3a0, ask a8d5), split into T2 bcrypt cost (c9e1/7d3a) and T3 index (b7d2/e46c) · 3/5 open
D1 bcrypt cost?  a3f9 12 (rec) | 7c2e 10 | e01d - own
Next: D1 → T3
```
