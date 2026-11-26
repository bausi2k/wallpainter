# Setup (once per project)

Read this only when `.wallpainter/index.html` is missing or older than this skill.

Run it if `.wallpainter/index.html` is missing, or if its `data-wp-version` is older than the skill's version.

1. Copy the viewer and the helper script without loading them into context. `<skill-dir>` is the folder that contains `SKILL.md`:
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
   // Wallpainter event log - append only. Format: wallpainter references/events.md.
   W({t:"board", title:"<short goal>", lang:"<user language, e.g. de>"})
   ```
3. Add `.wallpainter/` to `.gitignore` (default). Say so in one chat line; if the user wants the board versioned, remove the entry.
4. Open the board once in the user's **system browser**: `open .wallpainter/index.html` on macOS, `xdg-open` on Linux, `start` on Windows. It reloads `state.js` every 2 s by itself.
   Never open it via `file://` in an embedded agent browser (for example a browser pane of your own app). Such panes often show static snapshots or `data:` copies that cannot reach `state.js`, so the board stays empty. If the user wants it inside such a pane, serve it locally and open `http://localhost:8766`:
   ```sh
   python3 -m http.server 8766 --bind 127.0.0.1 --directory .wallpainter
   ```
