import AVFoundation
import SwiftUI

// Throwaway device prototype: can you get from pocket to pause before you answer?
@main
struct PauseApp: App {
    var body: some Scene {
        WindowGroup {
            PauseScreen()
        }
    }
}

private struct PauseScreen: View {
    private enum Destination: Hashable {
        case quickReset, exchange
    }

    @Environment(\.scenePhase) private var scenePhase
    @ScaledMetric(relativeTo: .largeTitle) private var cueSize: CGFloat = 36
    @State private var situation: Situation?
    @State private var cue = Cue.opening
    @State private var nextIndex: [Situation: Int] = [:]
    @State private var scrollPosition = ScrollPosition(edge: .top)
    @State private var openingSpeech: AVSpeechSynthesizer?
    @State private var showsReset = false
    @State private var childExchange = ChildExchange()

    private var destination: Destination? {
        if showsReset { return .quickReset }
        return childExchange.phase == .reset ? nil : .exchange
    }

    var body: some View {
        NavigationStack {
            ScreenContent { checkInContent }
                .navigationTitle("Check-in")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(item: Binding(get: { destination }, set: { newDestination in
                    // A completed system pop (button or gesture) dismisses the whole flow.
                    if newDestination == nil { returnToCheckIn() }
                })) { destination in
                    switch destination {
                    case .quickReset:
                        ScreenContent { resetContent }
                            .navigationTitle("Quick reset")
                    case .exchange:
                        ScreenContent { exchangeContent }
                            .navigationTitle("Ask aloud")
                    }
                }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active:
                childExchange.sceneDidActivate()

            case .inactive:
                stopOpeningSpeech()
                childExchange.sceneDidBecomeInactive()
            default: // Background or a future scene phase.
                childExchange.sceneDidBecomeInactive()
                returnToCheckIn()
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

    @ViewBuilder
    private var exchangeContent: some View {
        switch childExchange.phase {
        case .reply(let reply) where scenePhase == .active:
            exchangeResult(title: "You can say", lines: reply.lines) {}
        case .reset, .reply: EmptyView()
        case .suggestion(let blocker): generalSuggestion(blocker: blocker)
        case .preparing: childExchangeStatus(title: "Getting ready…")
        case .asking: childExchangeStatus(title: ChildExchange.questionText)
        case .listening: childExchangeStatus(title: "Listening…")
        case .finishing: childExchangeStatus(title: "Finishing…")
        case .generating: childExchangeStatus(title: "Finding replies…")
        }
    }

    private var checkInContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text(ChildExchange.questionText)
                    .font(.system(size: cueSize, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        askAloudButton
                        quickResetButton
                    }
                    .fixedSize(horizontal: true, vertical: false)

                    VStack(spacing: 24) {
                        askAloudButton
                        quickResetButton
                    }
                }
            }
            .controlSize(.large)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .defaultScrollAnchor(.center, for: .alignment)
    }

    private var askAloudButton: some View {
        Button("Ask aloud", action: childExchange.start)
            .buttonStyle(.borderedProminent)
    }

    private var quickResetButton: some View {
        Button("Quick reset") {
            showsReset = true
            speakOpeningCueIfEnabled()
        }
        .buttonStyle(.bordered)
    }

    private func returnToCheckIn() {
        childExchange.cancel()
        stopOpeningSpeech()
        showsReset = false
        situation = nil
        cue = .opening
        scrollPosition = ScrollPosition(edge: .top)
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

    private func childExchangeStatus(title: String) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.title2)
                    .accessibilityAddTraits(.isHeader)
                if childExchange.phase == .listening {
                    Label("Hearing speech", systemImage: "waveform")
                        .opacity(childExchange.hearsSpeech ? 1 : 0)
                        .accessibilityHidden(!childExchange.hearsSpeech)
                    Button("Done", action: childExchange.finishListening)
                        .buttonStyle(.borderedProminent)
                }
                Button("Cancel", action: returnToCheckIn)
                    .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 32)
        }
    }

    private func generalSuggestion(blocker: ChildExchange.Blocker?) -> some View {
        exchangeResult(
            title: "General suggestion",
            lines: ["I’m here. You can tell me when you’re ready."],
            note: "This line isn’t based on your child’s answer."
        ) {
            if blocker == .missingSpeechModel {
                speechModelSetup
            } else if let blocker {
                Text(exchangeBlockerMessage(blocker))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func exchangeResult<Details: View>(
        title: LocalizedStringKey,
        lines: [String],
        note: LocalizedStringKey? = nil,
        @ViewBuilder details: () -> Details
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if let note {
                    Text(note)
                        .foregroundStyle(.secondary)
                }
                ForEach(lines, id: \.self) { line in
                    Text("“\(line)”")
                        .font(.title2)
                        .privacySensitive()
                }
                details()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 32)
        }
    }

    @ViewBuilder
    private var speechModelSetup: some View {
        switch childExchange.speechModelSetup {
        case .canDownload:
            Text(exchangeBlockerMessage(.missingSpeechModel))
                .foregroundStyle(.secondary)
            Button("Download speech model", action: childExchange.downloadSpeechModel)
                .buttonStyle(.borderedProminent)
        case .downloading:
            ProgressView("Downloading US English speech-to-text model…")
        case .ready:
            Text("Speech model ready.")
                .font(.headline)
            Text("Go back to check-in and tap Ask aloud when you’re ready.")
                .foregroundStyle(.secondary)
        case .failed:
            Text("Couldn’t download the speech model. Check your connection and try again.")
                .foregroundStyle(.secondary)
            Button("Retry download", action: childExchange.downloadSpeechModel)
                .buttonStyle(.borderedProminent)
        }
    }

    private func exchangeBlockerMessage(_ blocker: ChildExchange.Blocker) -> String {
        switch blocker {
        case .voiceOver:
            "Pause doesn’t ask aloud or listen while VoiceOver is on."
        case .appleIntelligenceUnsupported:
            "This iPhone doesn’t support Apple Intelligence."
        case .appleIntelligenceUnavailable:
            "Apple Intelligence is off or isn’t ready on this iPhone. Check Settings → Apple Intelligence & Siri if available."
        case .missingSpeechModel:
            "The US English speech-to-text model isn’t installed. Hearing the opening cue doesn’t mean listening is set up."
        case .speechModelDownloading:
            "The US English speech-to-text model is downloading. Wait for it to finish, then try again."
        case .microphoneDenied:
            "Pause doesn’t have microphone access. You can allow it in Settings → Privacy & Security → Microphone."
        case .unknown:
            "Pause couldn’t complete the spoken exchange. You can go back to check-in and try again."
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
              let voice = SpokenVoice.preferredEnglish() else { return }

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

private struct ScreenContent<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .frame(maxWidth: 460)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
