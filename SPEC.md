# Pause: an in-the-moment reset for dads

## Problem Statement

When I notice myself getting frustrated with my kids, I have only a moment to change how I respond. My phone is usually in my pocket, but finding an app, explaining what happened, or working through an exercise would take too long. I need something that helps me slow down without taking my attention away from my kids for longer than necessary. Success is taking a beat before answering, not getting rid of the frustration. Sometimes, once I’ve taken that beat, I also want help hearing my child out and finding a first line to say back.

## Solution

Pause is a private, single-screen iPhone app I can open from a Lock Screen control. It immediately shows a familiar opening cue: **“Let one breath out before you answer.”** Underneath is an optional line I can say aloud: “Hang on. Give me a second.” I can put the phone away right there. If I need a more specific reminder, one tap on a situation gives me a short cue for myself and a smaller line I can say aloud. The situation-specific lines rotate from a prewritten set bundled with the app. If I enable **Speak Opening Cue** in iOS Settings, Pause can read the inward opening cue aloud so I don't have to look down again after opening it. Opening speech is off by default.

If my child is willing to answer, I can tap **Ask how they’re feeling**. Pause asks “How are you feeling?” aloud, then listens for one answer. When I tap **Done** or listening reaches 30 seconds, Pause stops listening and shows me one short line I can say back. The app does not speak that line. The normal launch, including from the Lock Screen, never starts the question or turns on the mic.

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
18. As a dad who wants to keep my eyes on my kids, I want to opt in to hearing the opening cue when I open Pause, so that I can take a beat without reading the screen.
19. As a dad whose child is willing to answer, I want Pause to ask how they’re feeling in its own voice, so that the question doesn’t come from me.
20. As a dad listening to my child, I want to see when the phone is picking up speech and decide when the answer is done, so that a pause doesn’t cut them off.
21. As a dad who’s heard my child’s answer, I want one short line I can say back, so that I can acknowledge what they said without having to find the words on the spot.

## Implementation Decisions

- Ship a native, single-screen SwiftUI app for iPhone on iOS 26 or later. Use the system’s configurable Lock Screen control to open Pause directly or run a Shortcuts **Open App** action. Document setup and let iOS handle any required authentication; the cue lives inside the app, not on the Lock Screen itself.
- Keep the opening cue and its smaller out-loud line fixed. Pin the three optional situation buttons to the bottom of the screen so they stay in place as the cue changes. If there isn’t enough room for both the cue and pinned buttons, let the whole screen scroll. The reset never requires a choice, a timer, sound, or a completion step.
- A situation tap replaces both lines together on the same screen. Keep the situation buttons available, indicate which situation is active, and bring the new cue into view. Bundle three short cue pairs per situation to start; keep the wording practical and nonjudgmental. Rotate within each situation without an immediate repeat; the initial cue in a cycle need not be fixed.
- Start at the opening cue on cold launch and after the app returns from the background. Clear the selected situation and restore the top of the screen. Rotation can continue in memory while the app process is alive; no persistence is required across launches.
- Put default-off **Speak Opening Cue** and **Speak in Silent Mode** switches in **Settings → Apps → Pause**. The Silent Mode override only applies when opening speech is enabled. Keep setup off the reset screen. Store only these preferences locally; don't save cue selections, playback events, or usage history.
- When enabled, speak only “Let one breath out before you answer.” once on a cold launch and once on the first activation after returning from the background, regardless of entry path. Don't replay after an inactive-only interruption. Don't speak the out-loud line or situation cues. Cut off ongoing speech when Pause becomes inactive (including when the phone locks or the user leaves) or when the user selects a situation. Don't resume a cut-off cue.
- Use Apple’s on-device speech synthesis with an available English system voice. Prefer installed Premium voices, then Enhanced voices, then the standard system voice. Prefer US English within each quality tier. Don't require a download or a connection. Use the normal audio route (the speaker is allowed), respect Silent Mode unless explicitly opted out, and mix without pausing or lowering other audio. If speech is unavailable, keep showing the cue without delay.
- Keep bundled cues and situation selection on-device. The child exchange is the only feature that uses a runtime model. No app service, cloud inference, account, or analytics.
- Add **Ask how they’re feeling** to the reset screen with the text **Asks aloud, then listens**. Start only on a deliberate tap, after the child is willing to answer. Check microphone permission and local transcription and model availability before starting. Play the fixed question even in Silent Mode, independently of the opening-cue settings. Start listening automatically only after the question finishes successfully. If it can’t play, leave the mic off.
- Transcribe on-device with Apple’s Speech framework. Show **Listening…**, a **Hearing speech** indicator when speech is detected, and **Done** and **Cancel**. Don’t show a transcript or end listening on silence. **Done** or the 30-second cap stops the mic and finalizes the answer. **Cancel** discards the exchange and returns to the reset without requesting a reply.
- After listening ends, pass only the finalized transcript to Apple’s on-device Foundation Models framework. Show one short, natural line Dad can say aloud that acknowledges what the child said. Don’t guess feelings or motives, diagnose, or give parenting instructions. If there’s no usable answer, no suitable reply, or a required capability is unavailable (including denied mic access, missing local speech assets, or Apple Intelligence being off or not ready), show **“I’m here. You can tell me when you’re ready.”** labeled **General suggestion**. Never fall back to cloud processing.
- Keep audio, transcripts, and replies in memory only; don’t save, log, or send them off-device. Leave the mic off after one exchange. Offer **Back to reset** on the reply screen but require no completion step. Leaving or locking the app stops any question or recording, abandons any pending reply, and clears the exchange so the next open starts fresh.
- Support Dynamic Type and VoiceOver using native text and buttons. The inward cue is the primary heading; use the existing accessibility announcement for both updated lines after a situation tap. Skip app-controlled speech while VoiceOver is running so the voices don't compete.

## Testing Decisions

- **Proposed seam for confirmation:** Exercise the Reset screen through the launched iOS app, using rendered text, situation button taps, and system background/reopen actions. Use one app-level UI seam for the whole reset flow; don’t expose cue storage or SwiftUI state solely for testing. The Lock Screen entry point is checked manually on a physical iPhone because iOS owns the control and authentication.
- Test observable behavior: launch reveals the exact opening cue and its optional out-loud line with no prerequisite action; any situation tap shows the corresponding pair; a second tap on the same situation changes the pair; switching situations updates both lines; backgrounding and reopening returns to the opening cue. Do not pin the random starting phrase or inspect rotation indices.
- Verify the app still works with connectivity disabled. Tap through cues of different lengths and confirm the pinned buttons don't move. At larger Dynamic Type sizes, check that the cue is readable and all buttons remain reachable. With VoiceOver, check that the controls are usable and a new pair is announced after a tap.
- Use the prototype’s existing manual walkthrough as prior art; there is no automated test target yet. Use the simulator for screen behavior where practical. On an iPhone, test the actual pocket → wake → control → cue → phone away flow, including locking the phone while a situation cue is showing and reopening from the control. Record whether this takes more effort than is realistic in the moment, not a fabricated latency target.
- On a physical iPhone, verify that speech is off by default, the switch survives relaunch, and switching it off restores silent opens. With speech enabled, check a cold launch and a return from the background, including via the Lock Screen control. Verify that only the inward opening cue plays, once per open, and that an inactive-only interruption doesn't replay it. Check Silent Mode with and without the override, verify the override alone never enables speech, and check airplane mode and playback alongside other audio. Verify that locking, leaving, or choosing a situation cuts off speech without resuming it, and that VoiceOver still reads the screen and announces situation changes without competing app speech.
- On a physical iPhone, verify that only the new button starts the exchange, the question plays in Silent Mode regardless of the opening-cue settings, and the mic stays off until the question finishes. Check the listening and speech indicators without a transcript, a pause mid-answer, **Done**, the 30-second cap, and **Cancel**. Verify that one reply appears on screen without being spoken, the mic stays off afterward, and **Back to reset**, leaving, or locking clears the exchange. Check leaving or locking while asking, listening, and generating so no reply appears on return. With prepared on-device assets, check the flow in airplane mode. Also check denied mic access, unavailable local capabilities, and no usable answer; each should show the labeled fallback without cloud processing.
- Validate usefulness after a few real uses: did Pause buy a beat before answering, even if the frustration was still there? Keep speech only if hearing the cue helps buy that beat without another glance in the real Lock Screen flow. Ask for a qualitative verdict outside the app rather than building a feedback or tracking feature.

## Out of Scope

- Repairing things after snapping, general parenting advice, guided meditation, timed breathing, or a routine to complete.
- Journaling, reminders, scores, streaks, accounts, syncing, and analytics.
- Custom phrase editing, free-text situation entry, AI-generated reset cues, multi-turn conversation, and sending details about the kids off-device.
- An in-app voice picker, in-app voice downloads, and recorded audio.
- Additional Lock Screen integrations or public distribution. Try the app on the owner’s phone first.

## Further Notes

The throwaway prototype already embodies the screen, cue rotation, and background reset. Device-level Lock Screen behavior and in-the-moment usefulness are still unverified. If it takes too long to reach the opening cue, address access before tuning the voice or adding content. If access works but the reset lines grow stale, try a larger prewritten set. The child exchange is a separate use of on-device AI, not a replacement for the reset.
