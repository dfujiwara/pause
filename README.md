# Pause · throwaway iPhone prototype

**Question:** Can you go from pocket to cue quickly enough to take one breath before you answer?

The screen opens on “Let one breath out before you answer.” The three situations are optional; each tap shows a cue for you and a smaller line you can say out loud. Put the phone away whenever you’re ready. Leaving the app for the background resets the screen to the opening cue. Only the speech preferences are saved; phrase rotation stays in memory, and nothing is sent.

## Run on your iPhone

1. Open `PausePrototype.xcodeproj` in Xcode. If Xcode asks you to review its license or finish setup, do that first.
2. Connect and unlock an iPhone running iOS 26 or later. Select the **Pause** target, then in **Signing & Capabilities** choose your team (a Personal Team is fine). Change the bundle identifier if Xcode says it’s unavailable.
3. Select your iPhone as the run destination and press **Run**. If prompted, enable Developer Mode on the iPhone.

## Put it on the Lock Screen

Touch and hold the Lock Screen → **Customize** → **Lock Screen**. Remove one of the bottom controls and tap its empty slot. Pick **Open App**, select **Pause**, then tap **Done**. If your controls list offers **Shortcut** instead, first create a shortcut in the Shortcuts app with the single action **Open App → Pause**, then pick that shortcut for the control. The iPhone may require authentication to open the app.

[Apple’s Lock Screen customization guide](https://support.apple.com/guide/iphone/create-a-custom-lock-screen-iph4d0e6c351/ios)

## Try it

- Lock the phone and put it in your pocket. Wake it, activate the control, read the opening line, and put it away. Did you need more effort or time than you’d realistically have?
- Open it again, tap the situation you recognize most, and try the new line. Tap the same situation again to see another. Is reading the second line worth an extra tap?
- Lock the phone while showing a situation, then use the shortcut again. Does it go straight to the opening cue?

## Check the spoken question and listening on your iPhone

Use a supported iPhone with Apple Intelligence enabled and its model and the US English on-device Speech assets already installed. Pause does not download assets during an exchange. Use an adult tester for this walkthrough.

1. Turn off opening speech, turn on Silent Mode, and open Pause. It should show the usual opening cue and three situation buttons without asking anything or accessing the mic.
2. Tap **Ask how they’re feeling** and allow microphone access if prompted. Listen for **“How are you feeling?”** even in Silent Mode. Check that **Listening…** and the system microphone indicator appear only after the question finishes.
3. Speak, pause, then speak again. Check that **Hearing speech** indicates speech without showing a transcript and that pausing doesn't end the exchange. Tap **Done**; the mic should stop and the labeled **General suggestion** should appear. The suggestion is not yet personalized. Try again without tapping **Done**; the mic should stop after 30 seconds.
4. Repeat with **Cancel**, locking the phone, and leaving for the Home Screen while the question is playing or the mic is active. Playback or recording should stop. Reopen Pause and check the exchange has been cleared.
5. Deny microphone access in Settings and repeat; the labeled suggestion should explain that microphone access was denied without asking or listening. Repeat with Apple Intelligence unavailable, VoiceOver running, or the US English speech-to-text model missing; check that the explanation identifies the blocker. **Back to reset**, leaving, or locking should clear the suggestion and its explanation.

## Check speech model setup

For the setup UI tests, select an iPhone simulator in Xcode and run **Product → Test** on the **Pause** scheme. The simulator uses scripted Speech asset states; it does not download Apple’s assets or test audio.

For the real download, use a supported physical iPhone with Apple Intelligence ready and the required US English Speech assets **not** installed. Turn off opening speech and leave microphone access off if it was already granted. Use an adult tester.

1. Connect to Wi-Fi. Open Pause (including via the Lock Screen control): only the reset should appear. Tap **Ask how they’re feeling** and confirm **General suggestion** offers **Download speech model** without a microphone prompt or spoken question.
2. Tap **Download speech model**. Check for the downloading state and then **Speech model ready.** with no question, microphone prompt, or system mic indicator. Check **Back to reset** is available.
3. On another attempt with assets still missing, turn cellular data off before opening Pause. While the download is in progress, turn off the Wi-Fi hotspot or access point from another device so Pause stays in the foreground. If iOS reports a failure, restore Wi-Fi and tap **Retry download**. Check that the retry reaches **Speech model ready.** If iOS resumes on its own, this attempt did not exercise the failure state.
4. While a download is still in progress, tap **Back to reset**, go to the Home Screen, or lock the phone. Pause should stay on or reopen to reset, not restore setup or start an exchange when the download completes. Repeat on a device with missing assets if needed.
5. From reset, tap **Ask how they’re feeling** and grant mic access when prompted; end that exchange. Turn on airplane mode and make sure Wi-Fi is off. Reopen Pause and tap **Ask how they’re feeling** again. Confirm the question plays and **Listening…** picks up speech offline, then tap **Done**.

## Try a more natural voice

In **Settings → Accessibility → Read & Speak → Voices → English** (called **Spoken Content** on some iOS versions), preview and download a **Premium** or **Enhanced** voice. Reopen Pause. It automatically prefers installed Premium voices, then Enhanced voices, and still works offline with the standard voice if neither is installed.

## Hear the opening cue in Silent Mode

In **Settings → Apps → Pause**, turn on both **Speak Opening Cue** and **Speak in Silent Mode**. Both switches are off by default. The override only applies to Pause's opening cue and may play through your iPhone speaker.

## Check opening speech on your iPhone

For a cold launch, swipe Pause away in the app switcher, then open it. Start with Silent Mode and VoiceOver off, and an audible volume on your usual audio route.

1. On a fresh install, check **Settings → Apps → Pause → Speak Opening Cue** is off. Cold-launch Pause: it should be silent, and the opening pair and three situation buttons should be usable immediately.
2. Turn the switch on and cold-launch. Listen for exactly one “Let one breath out before you answer.” The “Hang on. Give me a second.” line and situation cues should never be spoken by Pause. Cold-launch again and confirm the switch still has effect.
3. Repeat the cold launch in airplane mode with Wi-Fi off; the cue should work without downloading a voice. Turn Silent Mode on and repeat with **Speak in Silent Mode** off: the screen should work without speech. Turn **Speak in Silent Mode** on and repeat: the cue should play once. With the override still on, repeat with music already playing: the cue should use the current route without pausing or lowering the music.
4. With the switch still on, enable VoiceOver and cold-launch. Only VoiceOver should speak; use it to select a situation and verify it announces both new lines. Turn VoiceOver off before the next check.
5. In separate launches, lock the phone, leave for the Home Screen, or tap a situation as soon as the cue starts. Each action should stop the cue, with no resumption and no speech for the situation.
6. Turn **Speak Opening Cue** off, leaving **Speak in Silent Mode** on, then cold-launch twice. Both launches should be silent. Turn the override off again after the check.

## Check reopening from your pocket on your iPhone

The owner should run this on the physical iPhone with the Lock Screen control configured above. The simulator doesn't verify the actual pocket flow or iPhone audio behavior.

1. Turn **Speak Opening Cue** on, with Silent Mode and VoiceOver off. Open Pause, lock the phone, and pocket it. Wake it, activate the Lock Screen control, and authenticate if needed. Listen for the inward opening cue once, then put the phone away without another glance. Was it quick enough to buy a beat?
2. In Pause, select any situation, then lock the phone while that pair is showing. Reopen from the Lock Screen control: the opening pair should be at the top, no situation should be selected, and only the inward opening cue should play once.
3. Repeat the reset by leaving for the Home Screen and reopening via the icon, then by leaving for another app and returning via the app switcher. Don't swipe Pause away. Each return should restore the opening pair and speak once. Try opening and dismissing Control Center while the cue is speaking without leaving Pause: the cue should stop, not resume or replay. Locking or leaving during speech should also cut off the old cue; a new open should start a fresh cue, not continue the old one. Tapping a situation should cut off the cue without starting any new speech.
4. Repeat a reopen in airplane mode, with Silent Mode on, with other audio playing, and with VoiceOver on, one condition at a time. Expect the same behavior as on cold launch. Finally, turn **Speak Opening Cue** off and return to Pause without force-quitting; the opening pair should be silent.

After a few real uses, decide whether hearing the cue bought a beat before answering without another glance. If access took too long, fix that before tuning speech. No tracking needed.
