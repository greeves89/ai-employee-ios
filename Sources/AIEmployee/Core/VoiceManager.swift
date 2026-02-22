import Foundation
import Speech
import AVFoundation
import SwiftUI

@MainActor
@Observable
final class VoiceManager {
    static let shared = VoiceManager()

    var isRecording: Bool = false
    var transcript: String = ""
    var isAvailable: Bool = false
    var permissionDenied: Bool = false

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    private init() {
        setupSpeechRecognizer()
        requestPermissions()
    }

    // MARK: - Setup

    private func setupSpeechRecognizer() {
        if let germanRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "de-DE")),
           germanRecognizer.isAvailable {
            speechRecognizer = germanRecognizer
        } else if let englishRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")) {
            speechRecognizer = englishRecognizer
        }
        isAvailable = speechRecognizer?.isAvailable ?? false
        speechRecognizer?.delegate = self as? SFSpeechRecognizerDelegate
    }

    private func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                switch status {
                case .authorized:
                    self?.checkMicrophonePermission()
                case .denied, .restricted:
                    self?.isAvailable = false
                    self?.permissionDenied = true
                case .notDetermined:
                    self?.isAvailable = false
                @unknown default:
                    self?.isAvailable = false
                }
            }
        }
    }

    private func checkMicrophonePermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                self?.isAvailable = granted
                if !granted {
                    self?.permissionDenied = true
                }
            }
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard isAvailable, !isRecording else { return }
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            isAvailable = false
            return
        }

        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("[VoiceManager] Audio session error: \(error)")
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }

        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("[VoiceManager] Audio engine start error: \(error)")
            stopRecording()
            return
        }

        isRecording = true
        transcript = ""

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.stopRecording()
                }
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)

        isRecording = false
    }

    // MARK: - Computed

    var finalTranscript: String {
        let result = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        transcript = ""
        return result
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension VoiceManager: SFSpeechRecognizerDelegate {
    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        Task { @MainActor in
            self.isAvailable = available
        }
    }
}
