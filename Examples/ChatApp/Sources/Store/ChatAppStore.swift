/*
 * MIT License
 *
 * Copyright (c) 2025 Perfect Aduh
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

import AGUIAgentSDK
import AGUICore
import Foundation

// MARK: - ChatAppStore

/// Central store that drives the entire chat UI.
///
/// All `@Published` mutations run on the main actor. The streaming
/// `Task` suspends the main actor only during network waits, so UI
/// updates remain snappy.
@MainActor
final class ChatAppStore: ObservableObject {

    // MARK: - Published state

    @Published private(set) var state: ChatUIState = .init()
    @Published private(set) var agents: [AgentConfig] = []
    @Published var formMode: AgentFormMode?
    @Published var draft: AgentDraft = .init()
    @Published var repositoryError: String?

    // MARK: - Private state

    private var agent: StatefulAgUiAgent?
    private var streamingTask: Task<Void, Never>?
    /// messageId → index in `state.messages` for O(1) delta updates.
    private var streamingMessageIndices: [String: Int] = [:]
    /// Cancels itself after the dismissal delay fires.
    private var ephemeralDismissTask: Task<Void, Never>?

    // MARK: - Persistence

    private let defaults: UserDefaults
    private static let agentsKey = "chatapp.agents"
    private static let activeAgentIdKey = "chatapp.activeAgentId"

    var selectedAgentId: String? { state.activeAgent?.id }

    // MARK: - Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        agents = Self.loadAgents(from: defaults)
        if let id = defaults.string(forKey: Self.activeAgentIdKey),
           let config = agents.first(where: { $0.id == id }) {
            buildAgent(from: config)
        }
    }

    // MARK: - Chat actions

    func sendMessage(_ text: String) {
        guard let agent else { return }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Cancel any in-flight stream.
        streamingTask?.cancel()
        streamingMessageIndices.removeAll()

        let userMsg = DisplayMessage(role: .user, content: trimmed, timestamp: .now)
        state.messages.append(userMsg)
        state.isLoading = true

        streamingTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.state.isLoading = false
                self.state.ephemeralMessage = nil
                self.finishStreamingMessages()
            }
            do {
                let stream = try await agent.chat(message: trimmed)
                for try await event in stream {
                    self.processEvent(event)
                }
            } catch is CancellationError {
                // User cancelled — no error shown.
            } catch {
                self.state.error = error.localizedDescription
            }
        }
    }

    func cancelStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
    }

    func dismissError() {
        state.error = nil
    }

    // MARK: - Agent management

    func setActiveAgent(id: String?) {
        guard id != state.activeAgent?.id else { return }
        cancelStreaming()
        streamingMessageIndices.removeAll()

        if let id, let config = agents.first(where: { $0.id == id }) {
            buildAgent(from: config)
        } else {
            agent = nil
            state = ChatUIState()
        }
        saveActiveAgentId(id)
    }

    func presentCreateAgent() {
        draft = AgentDraft()
        formMode = .create
    }

    func presentEditAgent(_ config: AgentConfig) {
        draft = AgentDraft(from: config)
        formMode = .edit(config)
    }

    func dismissAgentForm() {
        formMode = nil
    }

    func saveAgent() {
        guard let mode = formMode, draft.isValid else { return }

        switch mode {
        case .create:
            let config = draft.toAgentConfig()
            agents.append(config)
            persistAgents()
            formMode = nil
            setActiveAgent(id: config.id)

        case .edit(let existing):
            let config = draft.toAgentConfig(existingId: existing.id)
            if let idx = agents.firstIndex(where: { $0.id == existing.id }) {
                agents[idx] = config
                persistAgents()
            }
            formMode = nil
            if config.id == state.activeAgent?.id {
                buildAgent(from: config)
            }
        }
    }

    func deleteAgent(id: String) {
        agents.removeAll { $0.id == id }
        persistAgents()

        if state.activeAgent?.id == id {
            cancelStreaming()
            if let next = agents.first {
                buildAgent(from: next)
                saveActiveAgentId(next.id)
            } else {
                agent = nil
                state = ChatUIState()
                saveActiveAgentId(nil)
            }
        }
    }

    // MARK: - Event processing

    /// Processes a single AG-UI event and updates `state` accordingly.
    ///
    /// `internal` so tests can inject events directly without a live agent.
    func processEvent(_ event: any AGUIEvent) {
        switch event {

        // MARK: Text messages (streaming assembly)

        case let e as TextMessageStartEvent:
            let msg = DisplayMessage(
                id: e.messageId,
                role: .assistant,
                content: "",
                timestamp: .now,
                isStreaming: true
            )
            streamingMessageIndices[e.messageId] = state.messages.count
            state.messages.append(msg)

        case let e as TextMessageContentEvent:
            if let idx = streamingMessageIndices[e.messageId] {
                state.messages[idx].content += e.delta
            }

        case let e as TextMessageEndEvent:
            if let idx = streamingMessageIndices[e.messageId] {
                state.messages[idx].isStreaming = false
                streamingMessageIndices.removeValue(forKey: e.messageId)
            }

        // MARK: Tool calls (ephemeral banner)

        case let e as ToolCallStartEvent:
            showEphemeral(DisplayMessage(
                id: e.toolCallId,
                role: .toolCall(name: e.toolCallName),
                content: "Calling \(e.toolCallName)…",
                timestamp: .now
            ))

        case is ToolCallEndEvent:
            scheduleEphemeralDismissal()

        // MARK: Steps (ephemeral banner)

        case let e as StepStartedEvent:
            showEphemeral(DisplayMessage(
                id: UUID().uuidString,
                role: .stepInfo(name: e.stepName),
                content: e.stepName,
                timestamp: .now
            ))

        case is StepFinishedEvent:
            state.ephemeralMessage = nil

        // MARK: Run lifecycle

        case let e as RunErrorEvent:
            state.error = e.error.message

        // MARK: Messages snapshot (authoritative history replacement)

        case let e as MessagesSnapshotEvent:
            rebuildMessages(from: e)

        // MARK: Custom events (e.g. change_background tool)

        case let e as CustomEvent:
            handleCustomEvent(e)

        default:
            break
        }
    }

    // MARK: - Testing support

    /// Resets state and configures an active agent for unit tests.
    func setupForTesting(agent config: AgentConfig) {
        state = ChatUIState(isConnected: true, activeAgent: config)
        streamingMessageIndices = [:]
    }

    // MARK: - Private helpers

    private func buildAgent(from config: AgentConfig) {
        do {
            let agentConfig = try config.toStatefulAgentConfig()
            agent = StatefulAgUiAgent(configuration: agentConfig)
            state = ChatUIState(isConnected: true, activeAgent: config)
        } catch {
            state.error = error.localizedDescription
        }
    }

    private func finishStreamingMessages() {
        for idx in state.messages.indices where state.messages[idx].isStreaming {
            state.messages[idx].isStreaming = false
        }
        streamingMessageIndices.removeAll()
    }

    private func showEphemeral(_ message: DisplayMessage) {
        ephemeralDismissTask?.cancel()
        state.ephemeralMessage = message
    }

    private func scheduleEphemeralDismissal() {
        ephemeralDismissTask?.cancel()
        ephemeralDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.state.ephemeralMessage = nil
        }
    }

    private func rebuildMessages(from event: MessagesSnapshotEvent) {
        guard let rawArray = try? event.parsedMessages() as? [[String: Any]] else { return }
        let rebuilt = rawArray.compactMap { displayMessage(from: $0) }
        state.messages = rebuilt
        streamingMessageIndices.removeAll()
    }

    private func displayMessage(from dict: [String: Any]) -> DisplayMessage? {
        guard
            let id = dict["id"] as? String,
            let role = dict["role"] as? String
        else { return nil }

        let content = dict["content"] as? String ?? ""

        let displayRole: DisplayMessageRole
        switch role {
        case "user": displayRole = .user
        case "assistant": displayRole = .assistant
        case "system": displayRole = .system
        default: return nil  // skip tool/activity messages in the display list
        }
        return DisplayMessage(id: id, role: displayRole, content: content, timestamp: .now)
    }

    private func handleCustomEvent(_ event: CustomEvent) {
        guard event.customType == "change_background",
              let payload = try? event.parsedData() as? [String: Any],
              let hex = payload["hex"] as? String ?? payload["color"] as? String
        else { return }
        state.backgroundHex = hex
    }

    // MARK: - Persistence helpers

    private static func loadAgents(from defaults: UserDefaults) -> [AgentConfig] {
        guard
            let data = defaults.data(forKey: agentsKey),
            let decoded = try? JSONDecoder().decode([AgentConfig].self, from: data)
        else { return [] }
        return decoded
    }

    private func persistAgents() {
        if let encoded = try? JSONEncoder().encode(agents) {
            defaults.set(encoded, forKey: Self.agentsKey)
        }
    }

    private func saveActiveAgentId(_ id: String?) {
        defaults.set(id, forKey: Self.activeAgentIdKey)
    }
}
