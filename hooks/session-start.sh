#!/bin/sh
# Adds the short Wallpainter rule to every session. The full protocol stays in the skill.
cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "Wallpainter is installed. Before replying, check: will the reply exceed about 8 lines, contain a decision between options, or split into several sub-problems? If so, invoke the `wallpainter` skill FIRST (Skill tool) and put the analysis on the board; the chat gets at most 5 lines with answer codes. Short answers stay in chat."
  }
}
JSON
