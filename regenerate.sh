#!/bin/bash
# Regenerates data.js with live Slack/Linear data via claude CLI.
# Run manually or via the LaunchAgent (com.rutaroberts.slack-digest.plist).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/regenerate-prompt.md"
OUTPUT_FILE="$SCRIPT_DIR/data.js"
LOG_FILE="$SCRIPT_DIR/regenerate.log"
TMP_FILE="/tmp/digest-$$.js"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOG_FILE"; }

log "Starting Slack Digest regeneration"

# ── Load user settings ────────────────────────────────────
SETTINGS_FILE="$SCRIPT_DIR/settings.json"
USER_NAME="YOUR_NAME"
USER_EMAIL="YOUR_EMAIL"
DYNAMIC_TOOLS=""

if [[ -f "$SETTINGS_FILE" ]] && command -v python3 &>/dev/null; then
  USER_NAME=$(python3 -c "
import json, sys
try:
  d = json.load(open('$SETTINGS_FILE'))
  v = d.get('identity', {}).get('name', '').strip()
  print(v if v else 'YOUR_NAME')
except: print('YOUR_NAME')
" 2>/dev/null)

  USER_EMAIL=$(python3 -c "
import json, sys
try:
  d = json.load(open('$SETTINGS_FILE'))
  v = d.get('identity', {}).get('email', '').strip()
  print(v if v else 'YOUR_EMAIL')
except: print('YOUR_EMAIL')
" 2>/dev/null)

  DYNAMIC_TOOLS=$(python3 -c "
import json
TOOL_MAP = {
  'slack':  'mcp__slack__slack_search_public_and_private,mcp__slack__slack_search_public,mcp__slack__slack_read_channel,mcp__slack__slack_read_thread',
  'jira':   'mcp__atlassian__getJiraIssue,mcp__atlassian__searchJiraIssuesUsingJql',
  'gcal':   'mcp__google-calendar__calendar-events-list,mcp__google-calendar__calendar-freebusy-query',
  'gmail':  'mcp__google-mail__gmail-users-messages-list,mcp__google-mail__gmail-users-messages-get,mcp__google-mail__gmail-users-threads-list',
  'github': 'mcp__github__search_issues,mcp__github__get_pull_request,mcp__github__list_pull_requests,mcp__github__list_issues',
  'linear': 'mcp__linear__list_issues,mcp__linear__get_issue,mcp__linear__list_teams',
}
try:
  d = json.load(open('$SETTINGS_FILE'))
  enabled = [v for k, v in TOOL_MAP.items() if d.get('tools', {}).get(k, {}).get('enabled', False)]
  print(','.join(enabled) + ',Read,Edit,Write' if enabled else '')
except: print('')
" 2>/dev/null)
  log "Settings: name='$USER_NAME' tools=$(echo "$DYNAMIC_TOOLS" | tr ',' '\n' | grep -Eo 'mcp__[^_]+' | sort -u | tr '\n' ' ')"
fi

# ── Inject date, name, email into prompt ──────────────────
TODAY="$(date '+%A, %B %-d, %Y')"
PROMPT_TMP="/tmp/digest-prompt-$$.md"
python3 - "$PROMPT_FILE" "$TODAY" "$USER_NAME" "$USER_EMAIL" <<'PYEOF' > "$PROMPT_TMP"
import sys
content = open(sys.argv[1]).read()
content = content.replace('DATE_PLACEHOLDER', sys.argv[2])
content = content.replace('YOUR_NAME', sys.argv[3])
content = content.replace('YOUR_EMAIL', sys.argv[4])
sys.stdout.write(content)
PYEOF

# Find the claude CLI (common install locations)
CLAUDE_BIN=""
for candidate in \
    "$HOME/.claude/local/claude" \
    "$HOME/.local/bin/claude" \
    "/usr/local/bin/claude" \
    "/opt/homebrew/bin/claude" \
    "$(which claude 2>/dev/null || true)"; do
  if [[ -x "$candidate" ]]; then
    CLAUDE_BIN="$candidate"
    break
  fi
done

if [[ -z "$CLAUDE_BIN" ]]; then
  log "ERROR: claude CLI not found. Install it or add it to PATH."
  rm -f "$TMP_FILE" "$PROMPT_TMP"
  exit 1
fi

log "Using claude at: $CLAUDE_BIN"

# Build tool list: from settings if available, otherwise fall back to all four defaults
if [[ -n "$DYNAMIC_TOOLS" ]]; then
  TOOLS_ARG="$DYNAMIC_TOOLS"
else
  TOOLS_ARG="mcp__slack__slack_search_public_and_private,mcp__slack__slack_search_public,mcp__slack__slack_read_channel,mcp__slack__slack_read_thread,mcp__google-calendar__calendar-events-list,mcp__google-calendar__calendar-freebusy-query,mcp__google-mail__gmail-users-messages-list,mcp__google-mail__gmail-users-messages-get,mcp__google-mail__gmail-users-threads-list,mcp__atlassian__getJiraIssue,mcp__atlassian__searchJiraIssuesUsingJql,Read,Edit,Write"
fi

# Feed prompt via stdin — --allowedTools pre-approves MCPs so non-interactive session doesn't stall
"$CLAUDE_BIN" \
  --print \
  --allowedTools "$TOOLS_ARG" \
  --output-format text < "$PROMPT_TMP" > "$TMP_FILE" 2>> "$LOG_FILE"

rm -f "$PROMPT_TMP"

# Validation: Claude may write data.js directly via the Write tool (preferred),
# or print the JS to stdout. Check both — direct write wins.
if grep -q "window\.DIGEST_DATA" "$OUTPUT_FILE"; then
  log "SUCCESS — data.js updated (written directly by Claude)"
  rm -f "$TMP_FILE"
elif grep -q "window\.DIGEST_DATA" "$TMP_FILE"; then
  cp "$OUTPUT_FILE" "${OUTPUT_FILE}.bak"
  mv "$TMP_FILE" "$OUTPUT_FILE"
  log "SUCCESS — data.js updated (from stdout)"
else
  log "WARN — data.js not updated; keeping existing file"
  log "--- Claude output preview ---"
  head -5 "$TMP_FILE" >> "$LOG_FILE"
  rm -f "$TMP_FILE"
  exit 1
fi
