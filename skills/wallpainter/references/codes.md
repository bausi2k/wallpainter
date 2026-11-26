# Decisions, answer codes, questions, new and close topics

Read this when you create a decision or when the user's message contains a code.

```js
W({t:"ask", id:"D2", in:"T2", q:"How do we migrate existing hashes?", md:"optional context", opts:[
  {c:"5b8d", h:"Rehash on login", md:"optional detail", pro:["no downtime","no batch job"], con:"inactive users keep old cost", rec:1},
  {c:"9f1a", h:"Batch job", con:"impossible without plaintext"}
], own:"2d6c"})
```

- All codes (option, own and close codes) are **4 random lowercase hex characters**, unique on the board. They are not sequential and not derived from the text. Get unused codes with `.wallpainter/wp.sh code`; `wp.sh append` rejects a code that is already on the board.
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
- Create it like any topic (§5): own `close` and `qa` codes, a first `note` step with what you understood, `focus` on it and `next`. If the title is empty or unclear, ask back in one line.
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
