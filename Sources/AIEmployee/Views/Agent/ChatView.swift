import SwiftUI

struct ChatView: View {
    let agent: Agent
    @State private var viewModel: ChatViewModel
    @State private var voiceManager = VoiceManager.shared
    @State private var scrollProxy: ScrollViewProxy? = nil

    init(agent: Agent) {
        self.agent = agent
        self._viewModel = State(initialValue: ChatViewModel(agent: agent))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.isLoading && viewModel.messages.isEmpty {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.appAccent))
                                .padding(40)
                        }

                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .padding(.bottom, 4)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
                .onAppear {
                    scrollProxy = proxy
                    scrollToBottom(proxy: proxy)
                }
            }

            // Voice Transcript (shown while recording)
            if voiceManager.isRecording && !voiceManager.transcript.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appError)
                    Text(voiceManager.transcript)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(3)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appError.opacity(0.1))
                .overlay(
                    Rectangle()
                        .fill(Color.appError)
                        .frame(width: 3),
                    alignment: .leading
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Error Message
            if let error = viewModel.errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(Color.appError)
                        .font(.system(size: 14))
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.appError)
                    Spacer()
                    Button {
                        viewModel.clearError()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.appError.opacity(0.1))
            }

            // Input Bar
            InputBar(viewModel: viewModel, voiceManager: voiceManager)
        }
        .task {
            await viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .animation(.easeInOut(duration: 0.2), value: voiceManager.isRecording)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastId = viewModel.messages.last?.id {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser { Spacer(minLength: 40) }

            if !message.isUser {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1e293b"))
                        .frame(width: 30, height: 30)
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appAccent)
                }
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.isTypingIndicator {
                    TypingIndicator()
                } else {
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(message.bubbleColor)
                        .clipShape(.rect(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: message.isUser ? 18 : 4,
                            bottomTrailingRadius: message.isUser ? 4 : 18,
                            topTrailingRadius: 18
                        ))
                        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                }

                if !message.formattedTime.isEmpty {
                    Text(message.formattedTime)
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                ZStack {
                    Circle()
                        .fill(Color(hex: "1e40af"))
                        .frame(width: 30, height: 30)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            }

            if !message.isUser { Spacer(minLength: 40) }
        }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var phase: Int = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.appTextSecondary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase == index ? 1.3 : 0.8)
                    .animation(
                        .easeInOut(duration: 0.4).repeatForever().delay(Double(index) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(in: .rect(cornerRadius: 18))
        .onAppear {
            phase = 0
            withAnimation {
                phase = 2
            }
        }
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Bindable var viewModel: ChatViewModel
    @Bindable var voiceManager: VoiceManager
    @State private var pulseAnimation = false

    var body: some View {
        HStack(spacing: 10) {
            // Text Input
            TextField("Nachricht...", text: $viewModel.inputText, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .glassEffect(in: .rect(cornerRadius: 22))
                .lineLimit(4)

            // Voice Button
            if voiceManager.isAvailable {
                Button {
                    if voiceManager.isRecording {
                        let transcript = voiceManager.finalTranscript
                        voiceManager.stopRecording()
                        if !transcript.isEmpty {
                            Task {
                                await viewModel.sendVoiceMessage(transcript)
                            }
                        }
                    } else {
                        voiceManager.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .frame(width: 44, height: 44)
                            .glassEffect(in: .circle)
                            .scaleEffect(pulseAnimation && voiceManager.isRecording ? 1.15 : 1.0)
                            .animation(
                                voiceManager.isRecording
                                    ? Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                                    : .default,
                                value: pulseAnimation
                            )

                        Image(systemName: voiceManager.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(voiceManager.isRecording ? Color.appError : Color.appTextSecondary)
                    }
                }
                .onChange(of: voiceManager.isRecording) { _, isRecording in
                    pulseAnimation = isRecording
                }
            }

            // Send Button
            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending
                                ? Color.appAccent.opacity(0.3)
                                : Color.appAccent
                        )
                        .frame(width: 44, height: 44)

                    if viewModel.isSending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.7)
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .fill(Color.appBorder)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
