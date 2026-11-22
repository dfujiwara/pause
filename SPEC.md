# Pause: an in-the-moment reset for dads

## Problem Statement

When I notice myself getting frustrated with my kids, I have only a moment to change how I respond. My phone is usually in my pocket, but finding an app, explaining what happened, or working through an exercise would take too long. I need something that helps me slow down without taking my attention away from my kids for longer than necessary. Success is taking a beat before answering, not getting rid of the frustration.

## Solution

Pause is a private, single-screen iPhone app I can open from a Lock Screen control. It immediately shows a familiar opening cue: **“Let one breath out before you answer.”** Underneath is an optional line I can say aloud: “Hang on. Give me a second.” I can put the phone away right there. If I need a more specific reminder, one tap on a situation gives me a short cue for myself and a smaller line I can say aloud. The situation-specific lines rotate from a prewritten set bundled with the app.

## User Stories

1. As a dad who notices frustration building, I want to open Pause from the Lock Screen, so that I don’t have to hunt for it before I respond.
2. As a dad using Pause for the first time, I want the opening cue before any setup inside the app, so that I can try it immediately.
3. As a dad who has used Pause before, I want the same opening cue each time, so that it becomes familiar enough to remember without my phone.
4. As a dad with only a second to look down, I want the inward cue to be the most prominent text, so that I know what to do at a glance.
5. As a dad who needs a second to collect myself, I want an optional line to say aloud, so that I don’t have to improvise.
6. As a dad who only needs one breath, I want to put the phone away at any point, so that I can get back to my kids without dismissing a prompt or finishing an exercise.
7. As a dad who has already asked three times, I want a cue matched to that situation, so that I can hold a limit without getting louder.
8. As a dad who’s running late, I want a cue matched to that situation, so that I can focus on the next thing instead of rushing everyone at once.
9. As a dad who’s being pulled in several directions, I want a cue matched to that situation, so that I can respond to one thing at a time.
10. As a dad who needs a situation-specific cue, I want to choose it with one tap on the same screen, so that I don’t have to navigate a menu or explain what happened.
11. As a dad who comes back to the same situation, I want more than one line available, so that the cue doesn’t become something I tune out.
12. As a dad who locked the phone after a reset, I want the opening cue the next time I use Pause, so that I’m not dropped into the last situation.
13. As a dad with no connection, I want all cues to work offline, so that I never wait on a network in the moment.
14. As a dad using this privately, I want no app account, incident history, or usage tracking, so that using Pause doesn’t become a record of difficult moments.
15. As a dad in a noisy room or a quiet public place, I want the reset to work without sound, so that I don’t need to hear audio or draw attention.
16. As a dad who uses larger text, I want to be able to read the cue and reach all three situation buttons, so that the screen still works at my preferred text size.
17. As a dad who uses VoiceOver, I want to find the situation buttons and hear the new cue when I select one, so that I don’t have to search for what changed.

## Implementation Decisions

- Ship a native, single-screen SwiftUI app for iPhone on iOS 18 or later. Use the system’s configurable Lock Screen control to open Pause directly or run a Shortcuts **Open App** action. Document setup and let iOS handle any required authentication; the cue lives inside the app, not on the Lock Screen itself.
- Keep the opening cue and its smaller out-loud line fixed. Place the three optional situation buttons below them in the order shown above. There is no required choice, timer, audio, or completion state.
- A situation tap replaces both lines together on the same screen. Keep the situation buttons available, indicate which situation is active, and bring the new cue into view. Bundle three short cue pairs per situation to start; keep the wording practical and nonjudgmental. Rotate within each situation without an immediate repeat; the initial cue in a cycle need not be fixed.
- Start at the opening cue on cold launch and after the app returns from the background. Clear the selected situation and restore the top of the screen. Rotation can continue in memory while the app process is alive; no persistence is required across launches.
- Keep all content and selection on-device. No service, API, model, storage schema, app sign-in, or analytics. AI-assisted drafting of the bundled copy is fine; the app itself makes no generation requests.
- Support Dynamic Type and VoiceOver using native text and buttons. The inward cue is the primary heading; announce updated lines after a situation tap without adding app-controlled audio.

## Testing Decisions

- **Proposed seam for confirmation:** Exercise the Reset screen through the launched iOS app, using rendered text, situation button taps, and system background/reopen actions. Use one app-level UI seam for the whole reset flow; don’t expose cue storage or SwiftUI state solely for testing. The Lock Screen entry point is checked manually on a physical iPhone because iOS owns the control and authentication.
- Test observable behavior: launch reveals the exact opening cue and its optional out-loud line with no prerequisite action; any situation tap shows the corresponding pair; a second tap on the same situation changes the pair; switching situations updates both lines; backgrounding and reopening returns to the opening cue. Do not pin the random starting phrase or inspect rotation indices.
- Verify the app still works with connectivity disabled. At larger Dynamic Type sizes, check that the cue is readable and all buttons remain reachable. With VoiceOver, check that the controls are usable and a new pair is announced after a tap.
- Use the prototype’s existing manual walkthrough as prior art; there is no automated test target yet. Use the simulator for screen behavior where practical. On an iPhone, test the actual pocket → wake → control → cue → phone away flow, including locking the phone while a situation cue is showing and reopening from the control. Record whether this takes more effort than is realistic in the moment, not a fabricated latency target.
- Validate usefulness after a few real uses: did it buy a pause before answering, even if the frustration was still there? Ask for a qualitative verdict outside the app rather than building a feedback or tracking feature.

## Out of Scope

- Repairing things after snapping, general parenting advice, guided meditation, timed breathing, or a routine to complete.
- Journaling, reminders, scores, streaks, accounts, syncing, and analytics.
- Custom phrase editing, free-text situation entry, runtime AI (including on-device AI), and sending details about the kids off-device.
- Additional Lock Screen integrations or public distribution. Try the app on the owner’s phone first.

## Further Notes

The throwaway prototype already embodies the screen, cue rotation, and background reset. Device-level Lock Screen behavior and in-the-moment usefulness are still unverified. If it takes too long to reach the opening cue, address access before adding content. If access works but the lines grow stale, try a larger prewritten set before reconsidering on-device AI.
