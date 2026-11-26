#!/bin/sh
# Wallpainter helper. Usage:
#   wp.sh code   [state.js]   print a fresh 4-hex code that is not on the board yet
#   wp.sh append [state.js]   read events from stdin, check them, append them
# Default state file: .wallpainter/state.js (or state.js next to this script when run from inside .wallpainter).
# `append` writes nothing when the syntax is invalid (checked with node if available)
# or when a new code (c, own, close, qa) is already on the board or repeated in the batch.

cmd=$1
state=${2:-.wallpainter/state.js}

fail() {
  echo "wp.sh: $1" >&2
  exit 1
}

[ -f "$state" ] || fail "state file not found: $state"

# node from PATH, a common install location, or the newest nvm version (nvm is often a shell function)
find_node() {
  command -v node 2>/dev/null && return
  for n in /opt/homebrew/bin/node /usr/local/bin/node "$HOME"/.nvm/versions/node/*/bin/node; do
    [ -x "$n" ] && last=$n
  done
  [ -n "$last" ] && printf '%s\n' "$last"
}

# 4-hex code from the system random source; never digits only, so it cannot look like a number
new_code() {
  while :; do
    c=$(od -An -N2 -tx1 /dev/urandom | tr -d ' \n')
    case $c in *[a-f]*) ;; *) continue ;; esac
    grep -q "\"$c\"" "$state" || { printf '%s\n' "$c"; return; }
  done
}

# new codes of a batch: values of c, own, close, qa in every line that is not an answer or patch event
codes_of() {
  grep -v -E '"?t"?: ?"(answer|patch)"' "$1" |
    grep -o -E '(^|[^A-Za-z0-9_])"?(c|own|close|qa)"?: ?"[0-9a-f]{4}"' |
    grep -o -E '"[0-9a-f]{4}"' | tr -d '"'
}

case $cmd in
  code)
    new_code
    ;;
  append)
    dir=$(mktemp -d) || fail "cannot create a temporary directory"
    trap 'rm -rf "$dir"' EXIT
    cat > "$dir/new.js"
    [ -s "$dir/new.js" ] || fail "no events on stdin"

    codes_of "$dir/new.js" | sort > "$dir/codes.txt"
    dup=$(uniq -d "$dir/codes.txt" | head -1)
    [ -z "$dup" ] || fail "code \"$dup\" is used more than once in this batch"
    while read -r c; do
      [ -n "$c" ] || continue
      grep -q "\"$c\"" "$state" && fail "code \"$c\" is already on the board"
    done < "$dir/codes.txt"

    node_bin=$(find_node)
    if [ -n "$node_bin" ]; then
      { echo 'function W(){}'; cat "$dir/new.js"; } > "$dir/check.js"
      "$node_bin" --check "$dir/check.js" 2> "$dir/err.txt" || {
        sed -n '1,6p' "$dir/err.txt" >&2
        fail "syntax error, nothing written"
      }
    else
      echo "wp.sh: node not found, syntax not checked" >&2
    fi

    cat "$dir/new.js" >> "$state"
    printf 'ok: %s events appended\n' "$(grep -c '^W(' "$dir/new.js")"
    ;;
  *)
    fail "usage: wp.sh code|append [state.js]"
    ;;
esac
