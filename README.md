# Pause · throwaway iPhone prototype

**Question:** Can you go from pocket to cue quickly enough to take one breath before you answer?

The screen opens on “Let one breath out before you answer.” The three situations are optional; each tap shows a cue for you and a smaller line you can say out loud. Put the phone away whenever you’re ready. Leaving the app for the background resets the screen to the opening cue. The phrase rotation lives in memory; nothing is saved or sent.

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

The verdict is whether it bought you a beat before answering, not whether you felt calm. No tracking needed.
