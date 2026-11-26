# Pause · throwaway iPhone prototype

Pause opens on **“How are you feeling?”** Tap **Ask aloud** to ask your child, then listen for one answer. Pause offers three short lines you can choose from: a reflection, an offer of support, and an invitation to say more. Opening the app never speaks or starts the mic.

Tap **Quick reset** for “Let one breath out before you answer” and three optional situation cues. Leaving the app returns you to the check-in. Only the speech preferences are saved; phrase rotation and exchanges stay in memory, and child audio, transcripts, and replies never leave the device.

## Run on your iPhone

1. Open `PausePrototype.xcodeproj` in Xcode. If Xcode asks you to review its license or finish setup, do that first.
2. Connect and unlock an iPhone running iOS 26 or later. Select the **Pause** target, then in **Signing & Capabilities** choose your team (a Personal Team is fine). Change the bundle identifier if Xcode says it’s unavailable.
3. Select your iPhone as the run destination and press **Run**. If prompted, enable Developer Mode on the iPhone.

## Put it on the Lock Screen

Touch and hold the Lock Screen → **Customize** → **Lock Screen**. Remove one of the bottom controls and tap its empty slot. Pick **Open App**, select **Pause**, then tap **Done**. If your controls list offers **Shortcut** instead, first create a shortcut in the Shortcuts app with the single action **Open App → Pause**, then pick that shortcut for the control. The iPhone may require authentication to open the app.

[Apple’s Lock Screen customization guide](https://support.apple.com/guide/iphone/create-a-custom-lock-screen-iph4d0e6c351/ios)

## Try it

- Lock the phone and put it in your pocket. Wake it, activate the control, and tap **Quick reset**. Can you read the cue and put the phone away in time to help?
- Tap the situation you recognize most, and try the new line. Tap the same situation again to see another. Is reading the second line worth an extra tap?
- Lock the phone while showing a situation, then use the shortcut again. It should open to the check-in. **Quick reset** should start at the opening cue.

## Check the child exchange on your iPhone

Use a supported iPhone with Apple Intelligence enabled and its model and the US English on-device Speech assets already installed. Pause does not download assets during an exchange. Use an adult tester for this walkthrough. After granting microphone access, turn on airplane mode and turn Wi-Fi off to check the complete exchange offline.

1. Turn on Silent Mode and open Pause. It should show **How are you feeling?** without speaking or accessing the mic.
2. Tap **Ask aloud** and allow microphone access if prompted. Listen for **“How are you feeling?”** even in Silent Mode. Check that **Listening…** and the system microphone indicator appear only after the question finishes.
3. Say “I wanted another turn,” pausing mid-answer. **Hearing speech** should indicate speech without showing a transcript or ending the exchange during the pause. Tap **Done**. The mic should stop before three short reply options appear. Check that one reflects the answer, one offers support, and one invites you to say more. None should be spoken or guess why you said it. Tap **Back to check-in** and check that the replies are gone.
4. Try a different answer, such as “I miss my friend,” and let listening reach 30 seconds without tapping **Done**. Check that the mic stops and the reflection matches the new answer. On another attempt, say nothing and tap **Done**. Check that one **General suggestion** appears instead of personalized options.
5. In separate attempts, go to the Home Screen or lock the phone while **Finding replies…** is visible. Reopen and wait a few seconds; neither replies nor a fallback should appear. Repeat with replies visible and while the question is playing or the mic is active. Playback or recording should stop, and reopening should start at the check-in. **Cancel** should also clear an in-progress exchange.
6. Deny microphone access in Settings and repeat; the labeled suggestion should explain that microphone access was denied without asking or listening. Repeat with Apple Intelligence unavailable, VoiceOver running, or the US English speech-to-text model missing; check that the explanation identifies the blocker.

## Check speech model setup

For the setup UI tests, select an iPhone simulator in Xcode and run **Product → Test** on the **Pause** scheme. The simulator uses scripted Speech asset states; it does not download Apple’s assets or test audio.

For the real download, use a supported physical iPhone with Apple Intelligence ready and the required US English Speech assets **not** installed. Turn off opening speech and leave microphone access off if it was already granted. Use an adult tester.

1. Connect to Wi-Fi. Open Pause (including via the Lock Screen control): only the check-in should appear. Tap **Ask aloud** and confirm **General suggestion** offers **Download speech model** without a microphone prompt or spoken question.
2. Tap **Download speech model**. Check for the downloading state and then **Speech model ready.** with no question, microphone prompt, or system mic indicator. Check **Back to check-in** is available.
3. On another attempt with assets still missing, turn cellular data off before opening Pause. While the download is in progress, turn off the Wi-Fi hotspot or access point from another device so Pause stays in the foreground. If iOS reports a failure, restore Wi-Fi and tap **Retry download**. Check that the retry reaches **Speech model ready.** If iOS resumes on its own, this attempt did not exercise the failure state.
4. While a download is still in progress, tap **Back to check-in**, go to the Home Screen, or lock the phone. Pause should stay on or reopen to the check-in, not restore setup or start an exchange when the download completes. Repeat on a device with missing assets if needed.
5. Tap **Ask aloud** and grant mic access when prompted; end that exchange. Turn on airplane mode and make sure Wi-Fi is off. Reopen Pause and tap **Ask aloud** again. Confirm the question plays and **Listening…** picks up speech offline, then tap **Done**.

## Try a more natural voice

On your iPhone, go to **Settings → Accessibility → Read & Speak → Voices → English** (called **Spoken Content** on some iOS versions). Preview and download a **Premium** or **Enhanced** voice, then reopen Pause and tap **Ask aloud** to hear the difference.

Both the question and the optional opening cue prefer installed Premium voices, then Enhanced voices, with US English preferred within each tier. If neither is installed, Pause uses the standard voice. Playback works offline, and this voice download is separate from the speech-to-text model.

## Hear the opening cue in Silent Mode

In **Settings → Apps → Pause**, turn on both **Speak Opening Cue** and **Speak in Silent Mode**. Both switches are off by default. The override only applies to Pause's opening cue and may play through your iPhone speaker.

## Check opening speech on your iPhone

For a cold launch, swipe Pause away in the app switcher, then open it. Start with Silent Mode and VoiceOver off, and an audible volume on your usual audio route.

1. On a fresh install, check **Settings → Apps → Pause → Speak Opening Cue** is off. Open Pause and tap **Quick reset**. Both screens should be silent.
2. Turn the switch on and cold-launch. The check-in should still be silent. Tap **Quick reset** and listen for exactly one “Let one breath out before you answer.” Pause should not read the out-loud line or situation cues.
3. Repeat in airplane mode; the cue should work without downloading a voice. With Silent Mode on, check that the cue only speaks when **Speak in Silent Mode** is on. With the override on and music playing, check that the cue doesn’t pause or lower the music.
4. Enable VoiceOver and tap **Quick reset**. Only VoiceOver should speak. Select a situation and verify it announces both new lines.
5. In separate attempts, lock the phone, leave the app, open Control Center, tap **Back to check-in**, or select a situation as soon as the cue starts. The cue should stop without resuming. After leaving or locking, reopening should show the silent check-in.
6. Turn **Speak Opening Cue** off while leaving **Speak in Silent Mode** on. **Quick reset** should be silent.

After a few real uses, decide whether hearing the cue bought a beat before answering without another glance. If access took too long, fix that before tuning speech. No tracking needed.
