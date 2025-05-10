import SwiftUI

struct T3 {

/// Extracts all ConversationThread objects and ConversationMessage objects from an array of ConversationHistory.
/// Returns a tuple containing arrays of ConversationThread and ConversationMessage, or nil if none found.
func getConversationThreads(from histories: [ConversationHistory]) -> (threads: [ConversationThread], messages: [ConversationMessage])? {
    var retrievedThreads: [ConversationThread] = []
    var messages: [ConversationMessage] = []
    
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
                                messages.append(message)
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
                            /*
                                firstElement: ["threads": T3_Chat.AnyCodable(value: [T3_Chat.AnyCodable(value: ["last_message_at": T3_Chat.AnyCodable(value: "2025-01-12T10:39:41.108Z"), "status": T3_Chat.AnyCodable(value: "done"), "user_edited_title": T3_Chat.AnyCodable(value: false), "updated_at": T3_Chat.AnyCodable(value: "2025-01-12T10:39:41.108Z"), "model": T3_Chat.AnyCodable(value: "gpt-4o-mini"), "created_at": T3_Chat.AnyCodable(value: "2025-01-12T10:39:41.054Z"), "id": T3_Chat.AnyCodable(value: "d3ff6609-e655-4150-9aa8-5e0551ac80a9"), "title": T3_Chat.AnyCodable(value: "New Thread")]), T3_Chat.AnyCodable(value: ["created_at": T3_Chat.AnyCodable(value: "2025-01-12T17:48:46.173Z"), "user_edited_title": T3_Chat.AnyCodable(value: false), "id": T3_Chat.AnyCodable(value: "d7893cb5-8875-4272-9e44-a1f6cd6ca782"), "model": T3_Chat.AnyCodable(value: "gpt-4o-mini"), "title": T3_Chat.AnyCodable(value: ""), "status": T3_Chat.AnyCodable(value: "deleted"), "last_message_at": T3_Chat.AnyCodable(value: "2025-01-12T17:48:46.241Z"), 
                            */
                            
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
    
    print("Found \(retrievedThreads.count) threads and \(messages.count) messages")
    return (retrievedThreads.isEmpty && messages.isEmpty) ? nil : (retrievedThreads, messages)
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
        return t3.getConversationThreads(from: histories)
    } catch {
        print("Error retrieving chat history: \(error)")
        return nil
    }
}
}
