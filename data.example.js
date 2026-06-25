// Slack Digest — example data file.
// Copy this to data.js and edit, OR let regenerate.sh generate data.js from live sources.
// data.js is gitignored — this example is the committed reference.
window.DIGEST_DATA = {
  meta: {
    name: "Your Name",
    lastChecked: "2026-06-23T09:00:00.000Z"
  },
  today: [
    {
      section: "Do this",
      cards: [
        {
          id: "slack-DABC123456-1780000001",
          dateAdded: "2026-06-23",
          subject: "Reply to Alex — timeline for design review",
          who: "Alex Kim",
          meta: "DM · 9:14 AM",
          effort: "reply",
          effortLabel: "Reply",
          context: "Alex asked if the design review can move to Thursday — they have a conflict on Wednesday. Needs a yes/no today.",
          href: "https://yourcompany.enterprise.slack.com/archives/DABC123456/p1780000001",
          hrefLabel: "Open DM",
          resolveCheck: { type: "slack-reply", channel: "DABC123456", from: "Your Name" }
        },
        {
          id: "slack-DABC789012-1780000002",
          dateAdded: "2026-06-20",
          subject: "⚠︎ Update the onboarding flow spec",
          who: "Jordan Lee",
          meta: "DM · Jun 20",
          effort: "design",
          effortLabel: "Design",
          context: "Jordan needs the updated spec before the eng sync Thursday. Last message was a Figma link with comments to address.",
          href: "https://yourcompany.enterprise.slack.com/archives/DABC789012/p1780000002",
          hrefLabel: "Open DM",
          resolveCheck: { type: "slack-delivery", channel: "DABC789012", from: "Your Name", keywords: ["figma", "updated", "here", "done", "shared", "link"] }
        }
      ]
    },
    {
      section: "Waiting on others",
      cards: [
        {
          id: "slack-DABC345678-1780000003",
          dateAdded: "2026-06-23",
          subject: "Sam — confirmation on launch date",
          who: "Sam Rivera",
          meta: "DM · 8:30 AM",
          context: "You asked Sam to confirm the launch date. No reply yet.",
          waiting: true,
          noDone: true,
          resolveCheck: { type: "slack-reply", channel: "DABC345678", from: "Sam Rivera" }
        }
      ]
    }
  ],
  community: [
    {
      section: "What's happening",
      cards: [
        {
          id: "slack-CABC111222-1780000004",
          dateAdded: "2026-06-23",
          subject: "Q2 retro notes are posted",
          who: "Taylor Nguyen",
          meta: "#team-all · 10:05 AM",
          context: "Taylor shared the retro action items doc. Three items assigned to the design team.",
          href: "https://yourcompany.enterprise.slack.com/archives/CABC111222/p1780000004",
          hrefLabel: "Open in Slack",
          noDone: true
        }
      ]
    }
  ]
};
