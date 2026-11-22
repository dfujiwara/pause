# Pause · throwaway iPhone prototype

**Question:** Can you go from pocket to cue quickly enough to take one breath before you answer?

The screen opens on “Let one breath out before you answer.” The three situations are optional; each tap shows a cue for you and a smaller line you can say out loud. Put the phone away whenever you’re ready. Leaving the app for the background resets the screen to the opening cue. Only the speech preference is saved; phrase rotation stays in memory, and nothing is sent.

## Run on your iPhone

1. Open `PausePrototype.xcodeproj` in Xcode. If Xcode asks you to review its license or finish setup, do that first.
2. Connect and unlock an iPhone running iOS 18 or later. Select the **Pause** target, then in **Signing & Capabilities** choose your team (a Personal Team is fine). Change the bundle identifier if Xcode says it’s unavailable.
3. Select your iPhone as the run destination and press **Run**. If prompted, enable Developer Mode on the iPhone.

## Put it on the Lock Screen

Touch and hold the Lock Screen → **Customize** → **Lock Screen**. Remove one of the bottom controls and tap its empty slot. Pick **Open App**, select **Pause**, then tap **Done**. If your controls list offers **Shortcut** instead, first create a shortcut in the Shortcuts app with the single action **Open App → Pause**, then pick that shortcut for the control. The iPhone may require authentication to open the app.

[Apple’s Lock Screen customization guide](https://support.apple.com/guide/iphone/create-a-custom-lock-screen-iph4d0e6c351/ios)

## Try it

- Lock the phone and put it in your pocket. Wake it, activate the control, read the opening line, and put it away. Did you need more effort or time than you’d realistically have?
- Open it again, tap the situation you recognize most, and try the new line. Tap the same situation again to see another. Is reading the second line worth an extra tap?
- Lock the phone while showing a situation, then use the shortcut again. Does it go straight to the opening cue?

## Check opening speech on your iPhone

For a cold launch, swipe Pause away in the app switcher, then open it. Start with Silent Mode and VoiceOver off, and an audible volume on your usual audio route.

1. On a fresh install, check **Settings → Apps → Pause → Speak Opening Cue** is off. Cold-launch Pause: it should be silent, and the opening pair and three situation buttons should be usable immediately.
2. Turn the switch on and cold-launch. Listen for exactly one “Let one breath out before you answer.” The “Hang on. Give me a second.” line and situation cues should never be spoken by Pause. Cold-launch again and confirm the switch still has effect.
3. Repeat the cold launch in airplane mode with Wi-Fi off; the cue should work without downloading a voice. Turn Silent Mode on and repeat: the screen should work without speech. Turn Silent Mode off and repeat with music already playing: the cue should use the current route without pausing or lowering the music.
4. With the switch still on, enable VoiceOver and cold-launch. Only VoiceOver should speak; use it to select a situation and verify it announces both new lines. Turn VoiceOver off before the next check.
5. In separate launches, lock the phone, leave for the Home Screen, or tap a situation as soon as the cue starts. Each action should stop the cue, with no resumption and no speech for the situation.
6. Turn the switch off, then cold-launch twice. Both launches should be silent; confirm the switch stays off.

The verdict is whether it bought you a beat before answering, not whether you felt calm. No tracking needed.
