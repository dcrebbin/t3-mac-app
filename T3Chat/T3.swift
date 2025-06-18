import SwiftUI

struct T3Version: Codable {
  let querySet: Int
  let identity: Int
  let ts: String
}

struct T3ThreadValue: Codable {
  let _creationTime: Double?
  let _id: String?
  let branchParent: String?
  let createdAt: Double?
  let generationStatus: String?
  let lastMessageAt: Double?
  let model: String?
  let pinned: Bool?
  let threadId: String?
  let title: String?
  let updatedAt: Double?
  let userId: String?
  let userSetTitle: Bool?
  let visibility: String?
}

struct T3QueryModification: Codable {
  let type: String
  let queryId: Int
  let value: [T3ThreadValue]
  let logLines: [String]
  let journal: String?
}

struct T3HistoryResponse: Codable {
  let type: String
  let startVersion: T3Version?
  let endVersion: T3Version?
  let modifications: [T3QueryModification]?
}

struct T3 {

  //   func getConversationThreads(from histories: [ConversationHistory]) -> (
  //     threads: [ConversationThread], messages: [ConversationMessage]
  //   )? {
  //     var retrievedThreads: [ConversationThread] = []
  //     var retrievedMessages: [ConversationMessage] = []

  //     for history in histories {
  //       switch history.json {
  //       case .dict(let dict):
  //         for (_, value) in dict {
  //           for array in value {
  //             for item in array {

  //               print("Attempting \(item)")
  //               if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
  //                 let thread = try? JSONDecoder().decode(ConversationThread.self, from: jsonData)
  //               {
  //                 retrievedThreads.append(thread)
  //               }

  //               if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
  //                 let message = try? JSONDecoder().decode(ConversationMessage.self, from: jsonData)
  //               {
  //                 retrievedMessages.append(message)
  //               }

  //             }

  //           }
  //         }

  //       case .array(let array):
  //         // Process array case
  //         for item in array {
  //           // Handle nested AnyCodable arrays
  //           if let nestedArray = item.value as? [AnyCodable] {
  //             for nestedItem in nestedArray {

  //               // Handle array case with "messages" or "threads" as first element
  //               if let nestedValueArray = nestedItem.value as? [T3_Chat.AnyCodable],
  //                 let firstElement = nestedValueArray.first?.value as? [String: AnyCodable]
  //               {

  //                 if let messages = firstElement["messages"]?.value as? [T3_Chat.AnyCodable] {
  //                   for message in messages {
  //                     if let messageData = message.value as? [String: AnyCodable] {
  //                       print("messageData: \(messageData)")
  //                       do {
  //                         // Convert AnyCodable values to plain JSON-compatible values
  //                         var jsonCompatibleData: [String: Any] = [:]
  //                         for (key, value) in messageData {
  //                           if let anyValue = value.value as? String {
  //                             jsonCompatibleData[key] = anyValue
  //                           } else if let anyValue = value.value as? Bool {
  //                             jsonCompatibleData[key] = anyValue
  //                           } else if let anyValue = value.value as? Int {
  //                             jsonCompatibleData[key] = anyValue
  //                           } else if let anyValue = value.value as? Double {
  //                             jsonCompatibleData[key] = anyValue
  //                           }
  //                         }

  //                         let jsonData = try JSONSerialization.data(
  //                           withJSONObject: jsonCompatibleData)
  //                         let retrievedMessage = try JSONDecoder().decode(
  //                           ConversationMessage.self, from: jsonData)
  //                         retrievedMessages.append(retrievedMessage)
  //                       } catch {
  //                         print("Error processing message data: \(error)")
  //                         print("Failed message data: \(messageData)")
  //                       }
  //                     }
  //                   }
  //                 }

  //                 if let threads = firstElement["threads"]?.value as? [T3_Chat.AnyCodable] {
  //                   for thread in threads {
  //                     if let threadData = thread.value as? [String: AnyCodable] {
  //                       print("threadData: \(threadData)")
  //                       do {
  //                         // Convert AnyCodable values to plain JSON-compatible values
  //                         var jsonCompatibleData: [String: Any] = [:]
  //                         for (key, value) in threadData {
  //                           if let anyValue = value.value as? String {
  //                             jsonCompatibleData[key] = anyValue
  //                           } else if let anyValue = value.value as? Bool {
  //                             jsonCompatibleData[key] = anyValue
  //                           } else if let anyValue = value.value as? Int {
  //                             jsonCompatibleData[key] = anyValue
  //                           } else if let anyValue = value.value as? Double {
  //                             jsonCompatibleData[key] = anyValue
  //                           }
  //                         }

  //                         let jsonData = try JSONSerialization.data(
  //                           withJSONObject: jsonCompatibleData)
  //                         let retrievedThread = try JSONDecoder().decode(
  //                           ConversationThread.self, from: jsonData)
  //                         retrievedThreads.append(retrievedThread)
  //                       } catch {
  //                         print("Error processing thread data: \(error)")
  //                         print("Failed thread data: \(threadData)")
  //                       }
  //                     }
  //                   }
  //                 }
  //               }
  //             }
  //           }
  //         }
  //       }
  //     }

  //     print("Found \(retrievedThreads.count) threads and \(retrievedMessages.count) messages")
  //     return (retrievedThreads.isEmpty && retrievedMessages.isEmpty)
  //       ? nil : (retrievedThreads, retrievedMessages)
  //   }

  static func retrieveChatHistory() async -> (
    threads: [ConversationThread], messages: [ConversationMessage]
  )? {
    if ApplicationState.authToken == "" {
      return nil
    }

    let url = URL(string: "wss://api.sync.t3.chat/api/1.24.7-alpha.2/sync")!

    let dummyHistory = """
          {"type":"Transition","startVersion":{"querySet":0,"identity":1,"ts":"YaUJw1AMShg="},"endVersion":{"querySet":1,"identity":1,"ts":"YaUJw1AMShg="},"modifications":[{"type":"QueryUpdated","queryId":0,"value":[{"_creationTime":1750222681271.6697,"_id":"jd71dy1pftegp7scv1wxkzys5n7j2d97","branchParent":null,"createdAt":1750222681271.0,"generationStatus":"completed","lastMessageAt":1750222681271.0,"model":"gemini-2.5-flash","pinned":false,"threadId":"7706b695-81ea-426d-9916-04b14803c4b2","title":"Greeting","updatedAt":1750222681271.0,"userId":"google:116551804713046434421","userSetTitle":false,"visibility":"visible"}],"logLines":[],"journal":null}]}
      """

    // Create a task to handle the WebSocket connection
    return await withCheckedContinuation { continuation in
      let webSocketTask = URLSession.shared.webSocketTask(with: url)

      // Handle incoming messages
      func receiveMessage() {
        webSocketTask.receive { result in
          switch result {
          case .failure(let error):
            print("WebSocket receive error: \(error)")
            continuation.resume(returning: nil)

          case .success(let message):
            switch message {
            case .string(let text):
              do {
                let t3HistoryResponse = try JSONDecoder().decode(
                  T3HistoryResponse.self, from: text.data(using: .utf8)!)
                let threads = t3HistoryResponse.modifications.map { modification in
                    modification
                }
                print("threads: \(threads)")

              } catch {
                print("Error parsing history: \(error)")
              }

            // Parse response and extract threads/messages
            // TODO: Add parsing logic here

            case .data(let data):
              print("Received binary: \(data)")

            @unknown default:
              break
            }

            // Keep receiving messages
            receiveMessage()
          }
        }
      }

      // Connect and send auth message
      webSocketTask.resume()

      let authMessage = URLSessionWebSocketTask.Message.string(
        """
        {
          "type": "Authenticate",
          "baseVersion": 0,
          "tokenType": "User", 
          "value": "\(ApplicationState.authToken)"
        }
        """
      )

      webSocketTask.send(authMessage) { error in
        if let error = error {
          print("WebSocket send error: \(error)")
          continuation.resume(returning: nil)
          return
        }

        // Send query for threads and messages
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
          """
        )

        webSocketTask.send(queryMessage) { error in
          if let error = error {
            print("WebSocket send error: \(error)")
            continuation.resume(returning: nil)
            return
          }

          // Start receiving messages
          receiveMessage()
        }
      }
    }
  }

  static func sendMessage(messages: [ChatMessage], threadId: String, title: String) async
    -> AsyncThrowingStream<String, Error>
  {
    return AsyncThrowingStream { continuation in
      Task {
        do {
          guard ApplicationState.authToken != "" else {
            continuation.finish(
              throwing: NSError(
                domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No auth token"]))
            return
          }

          let url = URL(string: "https://t3.chat/api/chat")!

          let headers = [
            "Content-Type": "application/json",
            "Cookie": ApplicationState.authToken,
          ]
          let messagesJson = messages.map { message -> [String: Any] in
            var json: [String: Any] = [
              "role": message.role,
              "content": message.content,
              "id": message.id,
              "attachments": message.attachments ?? [],  // Always include empty array if nil
            ]
            return json
          }

          print("messagesJson: \(messagesJson)")

          let body =
            [
              "messages": messagesJson,
              "model": "gemini-2.5-flash",
              "modelParams": [
                "reasoningEffort": "medium",
                "includeSearch": false,
              ],
              "threadMetadata": [
                "id": threadId,
                "title": title + "\n",  // Add newline to match format
              ],
              "preferences": [
                "name": "",
                "occupation": "",
                "selectedTraits": "",
                "additionalInfo": "",
              ],
              "userInfo": [
                "timezone": "Asia/Shanghai"
              ],
            ] as [String: Any]

          print("body: \(body)")

          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.allHTTPHeaderFields = headers
          request.httpBody = try JSONSerialization.data(withJSONObject: body)

          let (data, response) = try await URLSession.shared.data(for: request)

          if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            print("Error: \(httpResponse.statusCode)")
            print("Error: \(data)")
            continuation.finish(
              throwing: NSError(
                domain: "", code: httpResponse.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))
            return
          }

          guard let responseString = String(data: data, encoding: .utf8) else {
            print("Error: Could not convert data to string")
            continuation.finish(
              throwing: NSError(
                domain: "", code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid response encoding"]))
            return
          }

          // Process each line of the response
          for line in responseString.components(separatedBy: .newlines) {
            if line.hasPrefix("0:") {
              let content = line.replacingOccurrences(of: "0:", with: "").replacingOccurrences(
                of: "\"", with: "")
              print("content: \(content)")
              continuation.yield(content)
            }
          }

          continuation.finish()
        } catch {
          print("Error: \(error)")
          continuation.finish(throwing: error)
        }
      }
    }
  }
}
