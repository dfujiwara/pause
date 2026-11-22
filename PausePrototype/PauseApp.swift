import AVFoundation
import SwiftUI

// Throwaway device prototype: can you get from pocket to pause before you answer?
@main
struct PauseApp: App {
    var body: some Scene {
        WindowGroup {
            ResetScreen()
        }
    }
}

private struct ResetScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var cueSize: CGFloat = 36
    @State private var situation: Situation?
    @State private var cue = Cue.opening
    @State private var nextIndex: [Situation: Int] = [:]
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var openingSpeech: AVSpeechSynthesizer?
    @State private var shouldAttemptOpeningSpeech = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pause")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(cue.inward)
                        .font(.system(size: cueSize, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("You can say")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("“\(cue.outLoud)”")
                        .font(.title3)
                }
                .accessibilityElement(children: .combine)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("More cues (optional)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(Situation.allCases) { option in
                        Button {
                            showCue(for: option)
                        } label: {
                            HStack {
                                Text(option.rawValue)
                                    .font(.body.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 12)
                                if situation == option {
                                    Image(systemName: "checkmark")
                                        .accessibilityHidden(true)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(minHeight: 52)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            if situation == option {
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(.primary.opacity(0.45), lineWidth: 1)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }
                        .accessibilityAddTraits(situation == option ? .isSelected : [])
                    }
                }
            }
            .frame(maxWidth: 460, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity)
        }
        .scrollPosition($scrollPosition)
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                guard shouldAttemptOpeningSpeech else { return }
                shouldAttemptOpeningSpeech = false
                speakOpeningCueIfEnabled()
            case .inactive:
                stopOpeningSpeech()
            case .background:
                stopOpeningSpeech()
                // Only a background transition makes the next activation a new open.
                shouldAttemptOpeningSpeech = true
                situation = nil
                cue = .opening
                scrollPosition.scrollTo(edge: .top)
            @unknown default:
                stopOpeningSpeech()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            if UIAccessibility.isVoiceOverRunning {
                stopOpeningSpeech()
            }
        }
    }

    private func speakOpeningCueIfEnabled() {
        guard UserDefaults.standard.bool(forKey: "speakOpeningCue"),
              !UIAccessibility.isVoiceOverRunning,
              let voice = AVSpeechSynthesisVoice(language: "en-US")
                ?? AVSpeechSynthesisVoice.speechVoices().first(where: {
                    Locale.Language(identifier: $0.language).languageCode?.identifier == "en"
                        && !$0.voiceTraits.contains(.isPersonalVoice)
                }) else { return }

        // Use the app's audio session so speech mixes and respects Silent Mode.
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
        } catch {
            return
        }

        let synthesizer = openingSpeech ?? AVSpeechSynthesizer()
        openingSpeech = synthesizer
        let utterance = AVSpeechUtterance(string: Cue.opening.inward)
        utterance.voice = voice
        synthesizer.speak(utterance)
    }

    private func stopOpeningSpeech() {
        // Stop even if audio hasn't started; this also clears queued utterances.
        openingSpeech?.stopSpeaking(at: .immediate)
    }

    private func showCue(for option: Situation) {
        stopOpeningSpeech()
        let cues = option.cues
        let index = nextIndex[option] ?? Int.random(in: cues.indices)
        let newCue = cues[index]
        nextIndex[option] = (index + 1) % cues.count
        situation = option
        cue = newCue
        scrollPosition.scrollTo(edge: .top)
        AccessibilityNotification.Announcement("\(newCue.inward) You can say: \(newCue.outLoud)").post()
    }
}

private struct Cue {
    let inward: String
    let outLoud: String

    static let opening = Cue(
        inward: "Let one breath out before you answer.",
        outLoud: "Hang on. Give me a second."
    )
}

private enum Situation: String, CaseIterable, Identifiable {
    case repeated = "I’ve asked three times"
    case late = "We’re running late"
    case overwhelmed = "Everyone needs me at once"

    var id: Self { self }

    var cues: [Cue] {
        switch self {
        case .repeated:
            [
                Cue(inward: "You can hold the limit without getting louder.", outLoud: "Let me say that again, more slowly."),
                Cue(inward: "Take a breath. Then give one clear instruction.", outLoud: "Let’s do just this part first."),
                Cue(inward: "You don’t have to fill the silence. Give it a beat.", outLoud: "I’ll give you a moment to get started.")
            ]
        case .late:
            [
                Cue(inward: "Pause. What’s the one thing that needs to happen next?", outLoud: "Let’s just do the next thing."),
                Cue(inward: "You can move quickly and still speak slowly.", outLoud: "One thing first. I’ll help."),
                Cue(inward: "Breathe out. Leave the rest for later.", outLoud: "We can figure out the rest on the way.")
            ]
        case .overwhelmed:
            [
                Cue(inward: "One breath. Then one thing at a time.", outLoud: "I hear you. One at a time."),
                Cue(inward: "You don’t have to answer everyone at once.", outLoud: "Give me a second to listen."),
                Cue(inward: "Drop your shoulders. Pick one thing to respond to.", outLoud: "I’m going to help with one thing first.")
            ]
        }
    }
}
