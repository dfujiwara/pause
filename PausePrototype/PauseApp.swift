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
    @State private var childExchange = ChildExchange()

    var body: some View {
        Group {
            switch childExchange.phase {
            case .reset: resetContent
            case .suggestion: generalSuggestion
            case .preparing, .asking, .listening, .finishing: childExchangeStatus
            }
        }
        .frame(maxWidth: 460)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                childExchange.sceneDidActivate()
                guard shouldAttemptOpeningSpeech else { return }
                shouldAttemptOpeningSpeech = false
                speakOpeningCueIfEnabled()
            case .inactive:
                stopOpeningSpeech()
                childExchange.sceneDidBecomeInactive()
            case .background:
                stopOpeningSpeech()
                // Only a background transition makes the next activation a new open.
                shouldAttemptOpeningSpeech = true
                childExchange.sceneDidBecomeInactive()
                childExchange.cancel()
                situation = nil
                cue = .opening
                scrollPosition.scrollTo(edge: .top)
            @unknown default:
                stopOpeningSpeech()
                childExchange.cancel()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            if notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt == AVAudioSession.InterruptionType.began.rawValue {
                childExchange.interruptAudio()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)) { _ in
            if UIAccessibility.isVoiceOverRunning {
                stopOpeningSpeech()
                childExchange.interruptAudio()
            }
        }
    }

    private var resetContent: some View {
        ViewThatFits(in: .vertical) {
            VStack(spacing: 0) {
                ScrollView {
                    cueContent
                        .padding(.vertical, 32)
                }
                .scrollPosition($scrollPosition)
                // Reserve room for a readable viewport, regardless of cue length.
                .frame(minHeight: 120, idealHeight: 120, maxHeight: .infinity)

                situationOptions
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 24)
            }

            // On short screens or at very large text sizes, let everything scroll.
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    cueContent
                    situationOptions
                }
                .padding(.vertical, 32)
            }
            .scrollPosition($scrollPosition)
        }
    }

    private var childExchangeStatus: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(childExchangeStatusTitle)
                    .font(.title2)
                    .accessibilityAddTraits(.isHeader)
                if childExchange.phase == .listening {
                    Label("Hearing speech", systemImage: "waveform")
                        .opacity(childExchange.hearsSpeech ? 1 : 0)
                        .accessibilityHidden(!childExchange.hearsSpeech)
                    Button("Done", action: childExchange.finishListening)
                        .buttonStyle(.borderedProminent)
                }
                Button("Cancel", action: childExchange.cancel)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 32)
        }
    }

    private var childExchangeStatusTitle: String {
        switch childExchange.phase {
        case .asking: ChildExchange.questionText
        case .listening: "Listening…"
        case .finishing: "Finishing…"
        case .reset, .preparing, .suggestion: "Getting ready…"
        }
    }

    private var generalSuggestion: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("General suggestion")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("This line isn’t based on your child’s answer.")
                    .foregroundStyle(.secondary)
                Text("“I’m here. You can tell me when you’re ready.”")
                    .font(.title2)
                Button("Back to reset", action: childExchange.cancel)
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 32)
        }
    }

    private var cueContent: some View {
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

            VStack(alignment: .leading, spacing: 4) {
                Button("Ask how they’re feeling") {
                    stopOpeningSpeech()
                    childExchange.start()
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Asks aloud, then listens when voice exchange is available.")
                Text("Asks aloud, then listens")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var situationOptions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Divider()
                .padding(.bottom, 6)

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
                        Image(systemName: "checkmark")
                            .opacity(situation == option ? 1 : 0)
                            .accessibilityHidden(true)
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

    private func speakOpeningCueIfEnabled() {
        let preferences = UserDefaults.standard
        guard preferences.bool(forKey: "speakOpeningCue"),
              !UIAccessibility.isVoiceOverRunning,
              let voice = openingCueVoice() else { return }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            if preferences.bool(forKey: "speakInSilentMode") {
                try audioSession.setCategory(.playback, mode: .default, options: .mixWithOthers)
            } else {
                try audioSession.setCategory(.ambient)
            }
        } catch {
            return
        }

        let synthesizer = openingSpeech ?? AVSpeechSynthesizer()
        openingSpeech = synthesizer
        let utterance = AVSpeechUtterance(string: Cue.opening.inward)
        utterance.voice = voice
        synthesizer.speak(utterance)
    }

    private func openingCueVoice() -> AVSpeechSynthesisVoice? {
        let englishVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            Locale.Language(identifier: $0.language).languageCode?.identifier == "en"
                && !$0.voiceTraits.contains(.isPersonalVoice)
        }

        for quality in [AVSpeechSynthesisVoiceQuality.premium, .enhanced] {
            let voices = englishVoices.filter { $0.quality == quality }
            if let voice = voices.first(where: { $0.language == "en-US" }) ?? voices.first {
                return voice
            }
        }

        if let voice = AVSpeechSynthesisVoice(language: "en-US"),
           !voice.voiceTraits.contains(.isPersonalVoice) {
            return voice
        }
        return englishVoices.first
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
