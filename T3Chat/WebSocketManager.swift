import Foundation
import Observation
import SwiftUI

@Observable final class WebSocketManager {
  private var webSocketTask: URLSessionWebSocketTask?
  private var isConnected = false
  private var reconnectTimer: Timer?
  private let url = URL(string: "wss://api.sync.t3.chat/api/1.24.7-alpha.2/sync")!

  var threads: [ConversationThread] = []
  var messages: [ConversationMessage] = []
  var error: String?
  var isConnecting = false

  func connect() async {
    guard !isConnected && !isConnecting else { return }
    isConnecting = true

    webSocketTask = URLSession.shared.webSocketTask(with: url)
    webSocketTask?.resume()

    let authMessage = URLSessionWebSocketTask.Message.string(
      """
      {
          "type": "Authenticate",
          "baseVersion": 0,
          "tokenType": "User",
          "value": "\(ApplicationState.authToken)"
      }
      """)

    do {
      try await webSocketTask?.send(authMessage)
      isConnected = true
      isConnecting = false

      await sendThreadQuery()
      await receiveMessages()
    } catch {
      print("[T3Chat] Failed to connect: \(error.localizedDescription)")
      self.error = "Failed to connect: \(error.localizedDescription)"
      isConnected = false
      isConnecting = false
      scheduleReconnect()
    }
  }

  private func sendThreadQuery() async {
    print("[T3Chat] Sending thread query")
    let queryMessage = URLSessionWebSocketTask.Message.string(
      """
      {
          "type": "ModifyQuerySet", 
          "baseVersion": 0,
          "newVersion": 1,
          "modifications": [
              {
                  "type": "Add",
                  "queryId": 0,
                  "udfPath": "threads:get",
                  "args": [{"sessionId": "\(UUID().uuidString)"}]
              }
          ]
      }
      """)

    do {
      try await webSocketTask?.send(queryMessage)
      print("[T3Chat] Successfully sent thread query")
    } catch {
      print("[T3Chat] Failed to send thread query: \(error.localizedDescription)")
      self.error = "Failed to send thread query: \(error.localizedDescription)"
    }
  }

  private func receiveMessages() async {
    guard let webSocketTask = webSocketTask else { return }

    do {
      let message = try await webSocketTask.receive()

      switch message {
      case .string(let text):
        print("[T3Chat] Received message: \(text)")
        do {
          let t3HistoryResponse = try JSONDecoder().decode(
            T3HistoryResponse.self, from: text.data(using: .utf8)!)
          print("[T3Chat] Received history response: \(t3HistoryResponse)")
          await processHistoryResponse(t3HistoryResponse)
        } catch {
          print("[T3Chat] Failed to parse message: \(error.localizedDescription)")
          self.error = "Failed to parse message: \(error.localizedDescription)"
        }

      case .data(let data):
        print("[T3Chat] Received binary data: \(data)")

      @unknown default:
        break
      }

      await receiveMessages()

    } catch {
      print("[T3Chat] WebSocket receive error: \(error.localizedDescription)")
      self.error = "WebSocket receive error: \(error.localizedDescription)"
      isConnected = false
      scheduleReconnect()
    }
  }

  private func processHistoryResponse(_ response: T3HistoryResponse) async {
    print("[T3Chat] Processing history response")
    guard let modifications = response.modifications else {
      return
    }

    for modification in modifications {
      for threadValue in modification.value {
        if let threadId = threadValue.threadId,
          let title = threadValue.title
        {
          let thread = ConversationThread(
            id: threadId,
            model: threadValue.model ?? "gemini-2.5-flash",
            title: title,
            status: threadValue.generationStatus ?? "completed",
            created_at: ISO8601DateFormatter().string(
              from: Date(timeIntervalSince1970: threadValue.createdAt ?? 0)),
            updated_at: threadValue.updatedAt.map {
              ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: $0))
            },
            last_message_at: threadValue.lastMessageAt.map {
              ISO8601DateFormatter().string(from: Date(timeIntervalSince1970: $0))
            },
            user_edited_title: threadValue.userSetTitle
          )

          if !threads.contains(where: { $0.id == thread.id }) {
            threads.append(thread)
          }
        }
      }
    }
  }

  private func scheduleReconnect() {
    reconnectTimer?.invalidate()
    reconnectTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
      Task {
        await self?.connect()
      }
    }
  }

  func disconnect() {
    webSocketTask?.cancel(with: .goingAway, reason: nil)
    webSocketTask = nil
    isConnected = false
    reconnectTimer?.invalidate()
    reconnectTimer = nil
  }

  deinit {
    disconnect()
  }
}
