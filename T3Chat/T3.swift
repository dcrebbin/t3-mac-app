import SwiftUI

struct T3 {

/// Extracts all ConversationThread objects and ConversationMessage objects from an array of ConversationHistory.
/// Returns a tuple containing arrays of ConversationThread and ConversationMessage, or nil if none found.
func getConversationThreads(from histories: [ConversationHistory]) -> (threads: [ConversationThread], messages: [ConversationMessage])? {
    var retrievedThreads: [ConversationThread] = []
    var retrievedMessages: [ConversationMessage] = []
    
    for history in histories {
        switch history.json {
        case .dict(let dict):
            // Process dictionary case
            for (_, value) in dict {
                for array in value {
                    for item in array {
                            
                            print("Attempting \(item)")
                            // Try to decode as a thread
                            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                               let thread = try? JSONDecoder().decode(ConversationThread.self, from: jsonData) {
                                retrievedThreads.append(thread)
                            }
                            
                            // Try to decode as a message
                            if let jsonData = try? JSONSerialization.data(withJSONObject: dict),
                               let message = try? JSONDecoder().decode(ConversationMessage.self, from: jsonData) {
                                retrievedMessages.append(message)
                            }
                            
                        }
                    
                }
            }
            
        case .array(let array):
            // Process array case
            for item in array {
                // Handle nested AnyCodable arrays
                if let nestedArray = item.value as? [AnyCodable] {
                    for nestedItem in nestedArray {
                                                
                        // Handle array case with "messages" or "threads" as first element
                        if let nestedValueArray = nestedItem.value as? [T3_Chat.AnyCodable],
                           let firstElement = nestedValueArray.first?.value as? [String: AnyCodable] {
                        
                               if let messages = firstElement["messages"]?.value as? [T3_Chat.AnyCodable] {
                                for message in messages {
                                    if let messageData = message.value as? [String: AnyCodable] {
                                        print("messageData: \(messageData)")
                                        do {
                                            // Convert AnyCodable values to plain JSON-compatible values
                                            var jsonCompatibleData: [String: Any] = [:]
                                            for (key, value) in messageData {
                                                if let anyValue = value.value as? String {
                                                    jsonCompatibleData[key] = anyValue
                                                } else if let anyValue = value.value as? Bool {
                                                    jsonCompatibleData[key] = anyValue
                                                } else if let anyValue = value.value as? Int {
                                                    jsonCompatibleData[key] = anyValue
                                                } else if let anyValue = value.value as? Double {
                                                    jsonCompatibleData[key] = anyValue
                                                }
                                            }
                                            
                                            let jsonData = try JSONSerialization.data(withJSONObject: jsonCompatibleData)
                                            let retrievedMessage = try JSONDecoder().decode(ConversationMessage.self, from: jsonData)
                                            retrievedMessages.append(retrievedMessage)
                                        } catch {
                                            print("Error processing message data: \(error)")
                                            print("Failed message data: \(messageData)")
                                        }
                                    }
                                }
                            }
                            
                            if let threads = firstElement["threads"]?.value as? [T3_Chat.AnyCodable] {
                                for thread in threads {
                                    if let threadData = thread.value as? [String: AnyCodable] {
                                        print("threadData: \(threadData)")
                                        do {
                                            // Convert AnyCodable values to plain JSON-compatible values
                                            var jsonCompatibleData: [String: Any] = [:]
                                            for (key, value) in threadData {
                                                if let anyValue = value.value as? String {
                                                    jsonCompatibleData[key] = anyValue
                                                } else if let anyValue = value.value as? Bool {
                                                    jsonCompatibleData[key] = anyValue
                                                } else if let anyValue = value.value as? Int {
                                                    jsonCompatibleData[key] = anyValue
                                                } else if let anyValue = value.value as? Double {
                                                    jsonCompatibleData[key] = anyValue
                                                }
                                            }
                                            
                                            let jsonData = try JSONSerialization.data(withJSONObject: jsonCompatibleData)
                                            let retrievedThread = try JSONDecoder().decode(ConversationThread.self, from: jsonData)
                                            retrievedThreads.append(retrievedThread)
                                        } catch {
                                            print("Error processing thread data: \(error)")
                                            print("Failed thread data: \(threadData)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    print("Found \(retrievedThreads.count) threads and \(retrievedMessages.count) messages")
    return (retrievedThreads.isEmpty && retrievedMessages.isEmpty) ? nil : (retrievedThreads, retrievedMessages)
}

static func retrieveChatHistory() async -> (threads: [ConversationThread], messages: [ConversationMessage])? {
    if ApplicationState.authToken == "" {
        return nil
    }

    let url = URL(
        string: "https://t3.chat/api/trpc/getSyncedData?batch=1&input=%7B%220%22%3A%7B%22json%22%3Anull%2C%22meta%22%3A%7B%22values%22%3A%5B%22undefined%22%5D%7D%7D%7D")!

    let headers = [
        "x-trpc-batch": "true",
        "trpc-accept": "application/jsonl",
        "Content-Type": "application/json",
        "Cookie": ApplicationState.authToken,
    ]

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.allHTTPHeaderFields = headers

    do {
        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
            print("Error: \(httpResponse.statusCode)")
            print("Error: \(data)")
            return nil
        }
        
        // Convert data to string and split by newlines
        guard let jsonString = String(data: data, encoding: .utf8) else {
            print("Error: Could not convert data to string")
            return nil
        }
        
        let jsonLines = jsonString.components(separatedBy: .newlines)
            .filter { !$0.isEmpty } // Remove empty lines
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var histories: [ConversationHistory] = []
        
        // Decode each line as a separate JSON object
        for line in jsonLines {
            if let lineData = line.data(using: .utf8),
               let history = try? decoder.decode(ConversationHistory.self, from: lineData) {
                histories.append(history)
            }
        }
        
        print("Found \(histories.count) conversation histories")
        let t3 = T3()
        let (threads, messages) = t3.getConversationThreads(from: histories) ?? ([], [])
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        let threadsJson = try! jsonEncoder.encode(threads)
        let messagesJson = try! jsonEncoder.encode(messages)
        ApplicationState.conversationThreads =  threadsJson.base64EncodedString()
        ApplicationState.conversationMessages = messagesJson.base64EncodedString()
        return (threads, messages)
    } catch {
        print("Error retrieving chat history: \(error)")
        return nil
    }
}
}
