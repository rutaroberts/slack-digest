// Brief — example data file.
// Copy this to data.js and edit, OR let regenerate.sh generate data.js from live sources.
// data.js is gitignored — this example is the committed reference.
window.DIGEST_DATA = {
  meta: {
    name: "Your Name",
    lastChecked: "2026-06-23T09:00:00.000Z"
  },
  today: [
    {
      section: "Your move",
      cards: [
        {
          id: "slack-DABC123456-1780000001",
          dateAdded: "2026-06-23",
          subject: "Alex is waiting on the design review date",
          who: "Alex Kim",
          meta: "DM · 9:14 AM",
          effort: "reply",
          effortLabel: "Reply",
          context: "Alex has a conflict Wednesday. She wants to move the review to Thursday. One word from you closes it.",
          href: "https://yourcompany.enterprise.slack.com/archives/DABC123456/p1780000001",
          hrefLabel: "Go to thread",
          resolveCheck: { type: "slack-reply", channel: "DABC123456", from: "Your Name" }
        },
        {
          id: "slack-DABC789012-1780000002",
          dateAdded: "2026-06-20",
          subject: "⚠︎ The onboarding spec has open comments",
          who: "Jordan Lee",
          meta: "DM · Jun 20",
          effort: "design",
          effortLabel: "Design",
          context: "Jordan needs the spec before Thursday's sync. The last Figma link had comments that are still unanswered.",
          href: "https://yourcompany.enterprise.slack.com/archives/DABC789012/p1780000002",
          hrefLabel: "Go to thread",
          resolveCheck: { type: "slack-delivery", channel: "DABC789012", from: "Your Name", keywords: ["figma", "updated", "here", "done", "shared", "link"] }
        }
      ]
    },
    {
      section: "Their turn",
      cards: [
        {
          id: "slack-DABC345678-1780000003",
          dateAdded: "2026-06-23",
          subject: "Sam hasn't confirmed the launch date",
          who: "Sam Rivera",
          meta: "DM · 8:30 AM",
          context: "You asked. Nothing back yet.",
          waiting: true,
          noDone: true,
          resolveCheck: { type: "slack-reply", channel: "DABC345678", from: "Sam Rivera" }
        }
      ]
    }
  ],
  community: [
    {
      section: "Around you",
      cards: [
        {
          id: "slack-CABC111222-1780000004",
          dateAdded: "2026-06-23",
          subject: "Q2 retro notes are live",
          who: "Taylor Nguyen",
          meta: "#team-all · 10:05 AM",
          context: "Taylor posted the action items. Three go to design.",
          href: "https://yourcompany.enterprise.slack.com/archives/CABC111222/p1780000004",
          hrefLabel: "Open in Slack",
          noDone: true
        }
      ]
    }
  ]
};
