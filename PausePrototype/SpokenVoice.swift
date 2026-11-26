import AVFoundation
import Foundation

enum SpokenVoice {
    static func preferredEnglish() -> AVSpeechSynthesisVoice? {
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
}
