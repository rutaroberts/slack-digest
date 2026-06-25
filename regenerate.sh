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

# Inject today's date into the prompt and write to a temp file
TODAY="$(date '+%A, %B %-d, %Y')"
PROMPT_TMP="/tmp/digest-prompt-$$.md"
sed "s/DATE_PLACEHOLDER/$TODAY/" "$PROMPT_FILE" > "$PROMPT_TMP"

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

# Feed prompt via stdin — cleanest way to pass multiline markdown.
# --allowedTools pre-approves the MCPs so the non-interactive session doesn't stall.
"$CLAUDE_BIN" \
  --print \
  --allowedTools \
    "mcp__slack__slack_search_public_and_private,\
mcp__slack__slack_search_public,\
mcp__slack__slack_read_channel,\
mcp__slack__slack_read_thread,\
mcp__google-calendar__calendar-events-list,\
mcp__google-calendar__calendar-freebusy-query,\
mcp__google-mail__gmail-users-messages-list,\
mcp__google-mail__gmail-users-messages-get,\
mcp__google-mail__gmail-users-threads-list,\
mcp__atlassian__getJiraIssue,\
mcp__atlassian__searchJiraIssuesUsingJql,\
Read,Edit,Write" \
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
