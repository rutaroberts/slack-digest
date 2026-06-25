# Slack Digest — Regeneration Logic

You are maintaining YOUR_NAME's (YOUR_EMAIL) daily Slack Digest.
Today's date: DATE_PLACEHOLDER

Read the current data.js file first. It has two things:
1. `meta.lastChecked` — used only for scanning NEW channel activity (community items). Do NOT use it as a limit for DMs or saved messages.
2. The existing card list — carry every card forward UNLESS you can confirm it's resolved.

Also read `dismissed.json` if it exists. Any card `id` listed there must be excluded from the output.

Output ONLY valid JavaScript. No markdown, no explanation. Replace the full contents of data.js.

---

## STEP 0 — Saved messages (no date limit — always runs over ALL time)

Search Slack with `is:saved`. Every saved message is YOUR_NAME's own signal that something needs attention.

For each saved message:
- If its id is already in data.js → skip (already tracked).
- If its id is in dismissed.json → skip.
- Otherwise → classify and add as a new card. Read the thread for context if needed.

This is non-negotiable. A saved message must appear in the widget until YOUR_NAME acts on it.

---

## STEP 1 — Unanswered DMs (30-day lookback — not limited by lastChecked)

Search `to:me` in DMs and group DMs for the last 30 days. For each DM thread found:
- Read the thread to see who sent the last message.
- If the last message is NOT from YOUR_NAME → she hasn't replied → this is a "Do this" item (effort: Reply or Follow-up depending on context).
- If the last message IS from YOUR_NAME, or the thread is just social with no ask → skip.

This catches action items that were "read" in Slack but never acted on — the most common source of missed items.

---

## STEP 2 — Resolve existing items

For each card in the current data.js that has a `resolveCheck` field:

| resolveCheck.type | How to check | Remove if… |
|---|---|---|
| `slack-reply` | Read the channel/DM for ANY reply from `from` after `dateAdded` | Reply found — the task itself was to reply |
| `slack-delivery` | Read the channel/DM or thread for a message from `from` after `dateAdded` that contains at least one of `keywords` | Delivery message found — a Figma link, "here's the", "done", "submitted", etc. A mid-conversation reply ("still working on it", "give me a day") does NOT count. Only a message that hands off the work resolves it. |
| `calendar` | Search Google Calendar for an event matching `hint` after `dateAdded` | Event exists |
| `jira` | Check the Jira ticket status | Status is in `doneStatuses` |
| `email` | Search Gmail for a sent email matching `hint` after `dateAdded` | Email sent |

**The reply vs. delivery distinction is critical.** A DM card with effort "Reply" uses `slack-reply` — the act of replying IS the work. A card with effort "Design", "Follow-up", or "Review" uses `slack-delivery` — YOUR_NAME may send many messages in a conversation before the work is done. Only resolve when they send a message that delivers something: a link, a file, "here it is", "submitted", "done", "updated". If no keyword matches, keep the card even if there are newer messages in the thread.

Keep everything NOT confirmed resolved. If a check fails (tool error, no access) → keep the item.
If `dateAdded` is 3+ days before today and still unresolved → prefix subject with "⚠︎ ".

---

## STEP 3 — New items from channel activity (uses lastChecked as lower bound)

Search Slack for messages **after `meta.lastChecked`** in channels YOUR_NAME is in. Do not re-surface items already in the list.

### What counts as "Do this":
- A Figma comment or design request waiting on YOUR_NAME → **Design**
- A Jira ticket assigned to YOUR_NAME or moved to Ready for Acceptance → **Review**
- A message asking YOUR_NAME to make a choice → **Decision**
- A commitment YOUR_NAME made that isn't done yet → **Follow-up**

### What counts as "Waiting on others":
- YOUR_NAME asked someone something and hasn't received a reply

### What counts as "Community":
- Notable announcement (feature launch, org news, team milestone)
- Social moment from a teammate (photos, celebrations)
- A deadline relevant to YOUR_NAME but not requiring their action
- Open confusion in their team channels they'd want to know about

### Skip:
- Bot messages and automated notifications
- Channels unrelated to YOUR_NAME's work (finance ops, fantasy sports, copy edits)
- Pure social chit-chat with no news value
- Threads already fully resolved

---

## STEP 4 — Assign IDs and metadata

Every card must have:
- `id`: `slack-{channelId}-{messageTs_integer}` for Slack, `jira-{ticket}` for Jira
- `dateAdded`: preserve for carried-forward cards. Use today for new ones.
- `resolveCheck`: required for all "Do this" cards.
  - Effort **Reply** → `{ type: "slack-reply", channel: "CHANNELID", from: "YOUR_NAME" }` — any reply resolves it.
  - Effort **Design / Follow-up / Review / Decision** → `{ type: "slack-delivery", channel: "CHANNELID", from: "YOUR_NAME", keywords: ["here", "done", "shared", "link", "figma", "submitted", "updated"] }` — only a delivery message resolves it.

---

## STEP 5 — Output

Set `meta.lastChecked` to the current UTC time.

```javascript
window.DIGEST_DATA = {
  meta: {
    name: "YOUR_NAME",
    lastChecked: "YYYY-MM-DDTHH:mm:ss.000Z"
  },
  today: [
    {
      section: "Do this",
      cards: [
        {
          id: "slack-CHANNELID-TIMESTAMP",
          dateAdded: "YYYY-MM-DD",
          subject: "Action — 5 words max",
          who: "First Last",
          meta: "DM · 10:30 AM",
          effort: "reply",
          effortLabel: "Reply",
          context: "One sentence. What they need and why it matters.",
          href: "https://yourcompany.enterprise.slack.com/archives/...",
          hrefLabel: "Open in Slack",
          resolveCheck: { type: "slack-reply", channel: "CHANNELID", from: "YOUR_NAME" }
        }
      ]
    },
    {
      section: "Waiting on others",
      cards: [
        {
          id: "slack-CHANNELID-TIMESTAMP",
          dateAdded: "YYYY-MM-DD",
          subject: "Person — what you're waiting for",
          who: "First Last",
          meta: "DM · 9:00 AM",
          context: "One sentence.",
          waiting: true,
          noDone: true,
          resolveCheck: { type: "slack-reply", channel: "CHANNELID", from: "First Last" }
        }
      ]
    }
  ],
  community: [
    {
      section: "What's happening",
      cards: [
        {
          id: "slack-CHANNELID-TIMESTAMP",
          dateAdded: "YYYY-MM-DD",
          subject: "Headline — specific, 5 words",
          who: "First Last",
          meta: "#channel-name · Jun 22",
          context: "Two sentences max.",
          href: "https://yourcompany.enterprise.slack.com/archives/...",
          hrefLabel: "Open in Slack",
          noDone: true
        }
      ]
    }
  ]
};
```
