import AVFoundation
import FoundationModels
import Observation
import Speech
import UIKit

@MainActor @Observable
final class ChildExchange {
    enum Phase: Equatable {
        case reset, preparing, asking, listening, finishing
        case suggestion(Blocker?)
    }

    enum Blocker: Error {
        case voiceOver, appleIntelligenceUnsupported, appleIntelligenceUnavailable
        case missingSpeechModel, speechModelDownloading, microphoneDenied, unknown
    }

    static let questionText = "How are you feeling?"

    private(set) var phase: Phase = .reset
    private(set) var hearsSpeech = false
    @ObservationIgnored private var exchange: Task<Void, Never>?
    @ObservationIgnored private var deadline: Task<Void, Never>?
    @ObservationIgnored private var question: SpokenQuestion?
    @ObservationIgnored private var answer: LocalAnswer?
    @ObservationIgnored private var ownsAudioSession = false
    @ObservationIgnored private var sceneIsActive = false
    @ObservationIgnored private var activation: CheckedContinuation<Void, Never>?

    func sceneDidActivate() {
        sceneIsActive = true
        resumeAfterActivation()
    }

    func sceneDidBecomeInactive() {
        sceneIsActive = false
        interruptAudio()
    }

    func start() {
        guard phase == .reset, sceneIsActive else { return }
        phase = .preparing
        exchange = Task { await run() }
    }

    func finishListening() {
        guard phase == .listening else { return }
        answer?.stopInput()
        deadline?.cancel()
        deadline = nil
        hearsSpeech = false
        phase = .finishing
    }

    func cancel() {
        exchange?.cancel()
        resumeAfterActivation()
        clearAudio()
        phase = .reset
    }

    func interruptAudio() {
        switch phase {
        case .asking, .listening, .finishing: cancel()
        // A microphone permission alert can temporarily make the scene inactive.
        case .reset, .preparing, .suggestion: break
        }
    }

    private func run() async {
        let blocker: Blocker?
        do {
            try await askAndListen()
            blocker = nil
        } catch let known as Blocker {
            blocker = known
        } catch {
            blocker = phase == .listening || phase == .finishing ? nil : .unknown
        }
        guard !Task.isCancelled else { return }
        clearAudio()
        phase = .suggestion(blocker)
    }

    private func askAndListen() async throws {
        try checkVoiceOver()
        switch SystemLanguageModel.default.availability {
        case .available: break
        case .unavailable(.deviceNotEligible): throw Blocker.appleIntelligenceUnsupported
        case .unavailable: throw Blocker.appleIntelligenceUnavailable
        @unknown default: throw Blocker.unknown
        }
        guard SpeechTranscriber.isAvailable,
              let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
            throw Blocker.unknown
        }

        try Task.checkCancellation()
        let answer = LocalAnswer(locale: locale)
        self.answer = answer
        let format = try await answer.prepare()
        try Task.checkCancellation()
        try checkVoiceOver()
        guard await AVAudioApplication.requestRecordPermission() else { throw Blocker.microphoneDenied }
        try Task.checkCancellation()
        while !sceneIsActive {
            await withCheckedContinuation { activation = $0 }
            try Task.checkCancellation()
        }

        try checkVoiceOver()
        let session = AVAudioSession.sharedInstance()
        ownsAudioSession = true
        try session.setCategory(.playback, options: .mixWithOthers)
        try session.setActive(true)
        let question = SpokenQuestion()
        self.question = question
        phase = .asking
        guard await question.play() else { throw Blocker.unknown }
        try Task.checkCancellation()

        try session.setCategory(.playAndRecord, options: [.defaultToSpeaker, .mixWithOthers])
        try checkVoiceOver()
        try answer.startInput(format: format) { [weak self, weak answer] in
            guard let self, let answer, self.answer === answer, phase == .listening else { return }
            cancel()
        }
        phase = .listening
        deadline = Task {
            do { try await Task.sleep(for: .seconds(30)) } catch { return }
            finishListening()
        }
        try await answer.analyze { [weak self] detected in
            guard let self, phase == .listening else { return }
            hearsSpeech = detected
        }
    }

    private func checkVoiceOver() throws {
        if UIAccessibility.isVoiceOverRunning { throw Blocker.voiceOver }
    }

    private func resumeAfterActivation() {
        activation?.resume()
        activation = nil
    }

    private func clearAudio() {
        deadline?.cancel()
        deadline = nil
        question?.stop()
        question = nil
        answer?.cancel()
        answer = nil
        if ownsAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            ownsAudioSession = false
        }
        hearsSpeech = false
        exchange = nil
    }
}

@MainActor
private final class SpokenQuestion: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private var playback: CheckedContinuation<Bool, Never>?

    func play() async -> Bool {
        guard let voice = AVSpeechSynthesisVoice(language: "en-US") else { return false }
        let utterance = AVSpeechUtterance(string: ChildExchange.questionText)
        utterance.voice = voice
        synthesizer.delegate = self
        // Missing or failed system voices do not always report completion.
        let timeout = Task {
            do { try await Task.sleep(for: .seconds(8)) } catch { return }
            stop()
        }
        defer { timeout.cancel() }
        return await withCheckedContinuation { continuation in
            playback = continuation
            synthesizer.speak(utterance)
        }
    }

    func stop() {
        complete(success: false)
        synthesizer.stopSpeaking(at: .immediate)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.complete(success: true) }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.complete(success: false) }
    }

    private func complete(success: Bool) {
        playback?.resume(returning: success)
        playback = nil
    }
}

@MainActor
private final class LocalAnswer {
    private let transcriber: SpeechTranscriber
    private let detector = SpeechDetector(detectionOptions: .init(sensitivityLevel: .medium), reportResults: true)
    private let engine = AVAudioEngine()
    private lazy var analyzer = SpeechAnalyzer(modules: modules)
    private var modules: [any SpeechModule] { [transcriber, detector] }
    private let input = AsyncThrowingStream<AnalyzerInput, Error>.makeStream()
    private var hasInputTap = false
    private var configurationObserver: (any NSObjectProtocol)?

    init(locale: Locale) {
        transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
    }

    func prepare() async throws -> AVAudioFormat {
        // Do not download models or start audio capture as part of an exchange.
        switch await AssetInventory.status(forModules: modules) {
        case .installed: break
        case .supported: throw ChildExchange.Blocker.missingSpeechModel
        case .downloading: throw ChildExchange.Blocker.speechModelDownloading
        case .unsupported: throw ChildExchange.Blocker.unknown
        @unknown default: throw ChildExchange.Blocker.unknown
        }
        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: modules) else {
            throw ChildExchange.Blocker.unknown
        }
        try await analyzer.prepareToAnalyze(in: format)
        return format
    }

    func startInput(format: AVAudioFormat, onInterruption: @escaping @MainActor @Sendable () -> Void) throws {
        let node = engine.inputNode
        let sourceFormat = node.outputFormat(forBus: 0)
        guard sourceFormat.sampleRate > 0, sourceFormat.channelCount > 0,
              let converter = AVAudioConverter(from: sourceFormat, to: format) else { throw InputError.format }
        node.installTap(onBus: 0, bufferSize: 1024, format: sourceFormat, block: Self.audioTap(converter: converter, format: format, sink: input.continuation))
        hasInputTap = true
        try engine.start()
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil
        ) { _ in
            Task { @MainActor in onInterruption() }
        }
    }

    nonisolated private static func audioTap(
        converter: AVAudioConverter,
        format: AVAudioFormat,
        sink: AsyncThrowingStream<AnalyzerInput, Error>.Continuation
    ) -> AVAudioNodeTapBlock {
        let ratio = format.sampleRate / converter.inputFormat.sampleRate
        return { buffer, _ in
            let capacity = AVAudioFrameCount(ceil(Double(buffer.frameLength) * ratio)) + 32
            guard let converted = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
                sink.finish(throwing: InputError.format)
                return
            }
            var suppliedBuffer = false
            var error: NSError?
            let status = converter.convert(to: converted, error: &error) { _, inputStatus in
                inputStatus.pointee = suppliedBuffer ? .noDataNow : .haveData
                defer { suppliedBuffer = true }
                return suppliedBuffer ? nil : buffer
            }
            if status == .error {
                sink.finish(throwing: error ?? InputError.format as NSError)
            } else if converted.frameLength > 0 {
                sink.yield(AnalyzerInput(buffer: converted))
            }
        }
    }

    func stopInput() {
        if let configurationObserver {
            NotificationCenter.default.removeObserver(configurationObserver)
            self.configurationObserver = nil
        }
        if hasInputTap {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        input.continuation.finish()
    }

    func analyze(onSpeech: @escaping @MainActor (Bool) -> Void) async throws {
        async let detection: Void = reportSpeech(onSpeech)
        async let transcript: Void = consumeTranscript()
        do {
            let lastSample = try await analyzer.analyzeSequence(input.stream)
            try Task.checkCancellation()
            if let lastSample {
                try await analyzer.finalizeAndFinish(through: lastSample)
            } else {
                await analyzer.cancelAndFinishNow()
            }
            _ = try await (detection, transcript)
        } catch {
            stopInput()
            await analyzer.cancelAndFinishNow()
            throw error
        }
    }

    func cancel() {
        stopInput()
        let analyzer = analyzer
        Task { await analyzer.cancelAndFinishNow() }
    }

    private func reportSpeech(_ onSpeech: @MainActor (Bool) -> Void) async throws {
        for try await result in detector.results {
            onSpeech(result.speechDetected)
        }
    }

    private func consumeTranscript() async throws {
        // Finalize recognition, but discard the text in this slice.
        for try await _ in transcriber.results {}
    }

    private enum InputError: Error { case format }
}
