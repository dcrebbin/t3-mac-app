import AVFoundation
import CoreText
import HighlightedTextEditor
import SwiftUI

struct AppMessage {
  let text: String
  let isUser: Bool
  let id: String
  let createTime: Double?
  var translation: String?
}

struct ContentView: View {
  @State private var isListening: Bool = false
  @State private var messageIds: [String] = []
  @State private var conversationId: String = ""
  @State private var conversationTitle: String = ""
  @State private var scrollProxy: ScrollViewProxy?
  @State public var errorText: String?
  @State private var isHoveringClearButton: Bool = false
  @State private var isHoveringRetrieveLatestChatButton: Bool = false
  @State private var selectedThread: ConversationThread?
  @State private var webSocketManager = WebSocketManager()
  @State private var textInput: String = ""

  func userMessage(message: AppMessage) -> some View {
    let containsChinese =
      message.text.range(
        of: "[\u{4E00}-\u{9FA5}]", options: .regularExpression
      )

    return VStack(alignment: .trailing, spacing: 2) {
      Text(message.text)
        .font(.system(size: 14))
        .padding(.horizontal, 13)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(20)
        .textSelection(.enabled)
    }
    .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, alignment: .trailing)
  }

  func oaiMessage(message: AppMessage) -> some View {
    VStack(alignment: .leading) {
      HStack(spacing: 2) {
        Image(nsImage: NSImage(named: "OAI")!)
          .resizable()
          .frame(width: 18, height: 18)
          .padding(.all, 4)
          .background(Color.black)
          .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
          .clipShape(Circle())

        let containsChinese =
          message.text.range(
            of: "[\u{4E00}-\u{9FA5}]", options: .regularExpression
          )

        if let codeBlockRange = message.text.range(
          of: "```[\\s\\S]*?```", options: .regularExpression)
        {
          let beforeCode = String(message.text[..<codeBlockRange.lowerBound])
          let code = String(message.text[codeBlockRange])
          let afterCode = String(message.text[codeBlockRange.upperBound...])

          VStack(alignment: .leading) {
            if !beforeCode.isEmpty {
              Text(.init(Constants.convertStringToMarkdown(message: beforeCode)))
                .textSelection(.enabled).font(.system(size: 14))
            }

            let language = code.components(separatedBy: "\n")[0].replacingOccurrences(
              of: "```", with: "")

            VStack(alignment: .leading, spacing: 0) {
              HStack {
                Text(language)
                  .font(.system(size: 14))
                Spacer()
                Button(action: {
                  print("Copy")
                  let pasteboard = NSPasteboard.general
                  pasteboard.clearContents()
                  pasteboard.setString(
                    code.replacingOccurrences(
                      of: "```\\w*\\n?", with: "", options: .regularExpression
                    ),
                    forType: .string)
                }) {
                  Image(systemName: "doc.on.doc")
                }
              }
              .padding(.horizontal, 8)
              .frame(maxWidth: .infinity, minHeight: 35)
              .background(Color.gray.opacity(0.2))
              HighlightedTextEditor(
                text: .constant(
                  code.replacingOccurrences(
                    of: "```\\w*\\n?", with: "", options: .regularExpression)),
                highlightRules:
                  Constants.HIGHLIGHT_RULES

              )
              .frame(
                height: CGFloat(code.components(separatedBy: .newlines).count) * 20)
            }
            .border(Color.gray.opacity(0.2), width: 1)
            .cornerRadius(10)

            if !afterCode.isEmpty {
              Text(.init(Constants.convertStringToMarkdown(message: afterCode)))
                .textSelection(.enabled).font(.system(size: 14))
            }
          }
        } else {
          Text(.init(Constants.convertStringToMarkdown(message: message.text)))
            .font(.system(size: 14))
            .frame(minHeight: 40)
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .textSelection(.enabled)
        }
      }.frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }
    .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, alignment: .leading)

  }

  func logError(error: Error?) {
    print("Error: \(error?.localizedDescription ?? "Unknown error")")
    errorText = "Error: \(error?.localizedDescription ?? "Unknown error")"
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      errorText = nil
    }
  }

  var clear: some View {
    HStack {
      Text("Clear")
      Button(action: {
        print("Clear conversation")
        //        messages = []
        conversationId = ""
        conversationTitle = ""
      }) {
        Image(systemName: "trash").font(.system(size: 20))
          .scaledToFit()
          .padding(.all, 4)
      }.onHover { hovering in
        if hovering {
          isHoveringClearButton = true
        } else {
          isHoveringClearButton = false
        }
      }
      .background(
        isHoveringClearButton
          ? Color.gray.opacity(0.2) : Color.clear
      )
      .buttonStyle(.borderless)
    }
  }

  var body: some View {
    ZStack(alignment: .top) {
      TranslucentView(material: .hudWindow)
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .leading, spacing: 0) {
        TabView {
          VStack(alignment: .leading) {
            MessageView(
              errorText: $errorText,
              selectedThread: $selectedThread,
              webSocketManager: webSocketManager
            )
            if let errorText = errorText {
              Text(errorText)
                .foregroundColor(.red)
                .padding(.all, 4)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
          }
          .background(Color(.clear))
          .tabItem {
            Text("This is a test")
          }
          Settings().tabItem {
            HStack {
              Text("Settings")
              Image(systemName: "gearshape")
                .font(.system(size: 15))
                .scaledToFit()
                .padding(.all, 4)
            }
          }
          threadsView
        }.tabViewStyle(.sidebarAdaptable).frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all).padding(.all, 0)
      }.onAppear {
        Task {
          print("Connecting to web socket")
          await webSocketManager.connect()
        }
      }
      .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity, alignment: .top)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  var threadsView: some View {
    ForEach(webSocketManager.threads, id: \.id) { thread in
      messagesView(threadId: thread.id).tabItem {
        Text(thread.title)
      }.padding(.top, 10)
        .padding(.horizontal, 10)
    }
  }

  func messagesView(threadId: String) -> some View {
    let filteredMessages = webSocketManager.messages.filter { $0.threadId == threadId }
    let sortedMessages = filteredMessages.sorted {
      if let date0 = $0.created_at, let date1 = $1.created_at {
        return date0 < date1
      }
      return false
    }
    let thread = webSocketManager.threads.first { $0.id == threadId }
    return VStack(alignment: .leading, spacing: 0) {
      Text(thread?.title ?? "")
        .font(.headline)
        .padding(.bottom, 10)
      ZStack(alignment: .bottom) {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(sortedMessages, id: \.id) { message in
              if message.role == "user" {
                VStack(alignment: .trailing) {
                  Text(.init(Constants.convertStringToMarkdown(message: message.content)))
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(.all, 10)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }.frame(maxWidth: .infinity, alignment: .trailing).padding(.bottom, 10)
              } else {
                Text(.init(Constants.convertStringToMarkdown(message: message.content)))
                  .font(.body)
                  .padding(.top, 10)
                  .textSelection(.enabled)
              }
            }
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        ZStack(alignment: .bottom) {
          TextField("", text: $textInput)
            .onSubmit {
              Task {
                print("newMessage: \(textInput)")

                let newMessage = ConversationMessage(
                  id: UUID().uuidString,
                  role: "user",
                  model: "gemini-2.5-flash",
                  status: threadId,
                  content: textInput,
                  threadId: threadId,
                  created_at: Date().ISO8601Format(),
                  modelParams: ["reasoningEffort": "medium"],
                  attachments: nil,
                  providerMetadata: nil,
                  errorReason: ""
                )
                webSocketManager.messages.append(newMessage)

                var chatMessages = filteredMessages.map {
                  ChatMessage(
                    role: $0.role, content: $0.content, id: $0.id, attachments: $0.attachments)
                }
                chatMessages.append(
                  ChatMessage(
                    role: "user", content: textInput, id: UUID().uuidString, attachments: nil))
                let stream = await T3.sendMessage(
                  messages: chatMessages, threadId: threadId, title: thread?.title ?? "")
                textInput = ""

                let responseMessage = ConversationMessage(
                  id: UUID().uuidString,
                  role: "assistant",
                  model: "gemini-2.5-flash",
                  status: threadId,
                  content: "",
                  threadId: threadId,
                  created_at: Date().ISO8601Format(),
                  modelParams: ["reasoningEffort": "medium"],
                  attachments: nil,
                  providerMetadata: nil,
                  errorReason: ""
                )
                webSocketManager.messages.append(responseMessage)
                for try await content in stream {
                  print("received content: \(content)")
                  if let index = webSocketManager.messages.firstIndex(where: {
                    $0.id == responseMessage.id
                  }) {
                    webSocketManager.messages[index].content =
                      webSocketManager.messages[index].content + content
                  }
                }
              }
            }
            .padding(.horizontal, 10)
            .frame(height: 60)
            .textFieldStyle(PlainTextFieldStyle())
            .border(Color.white.opacity(0.2), width: 1)
            .background(
              .ultraThinMaterial
            )
            .clipShape(.rect(topLeadingRadius: 10, topTrailingRadius: 10))
        }
      }
    }
  }
}

struct MessageView: View {
  @Binding var errorText: String?
  @State var isRetrievingChatHistory: Bool = false
  @State var isHoveringRetrieveLatestChatButton: Bool = false
  @Binding var selectedThread: ConversationThread?
  let webSocketManager: WebSocketManager

  var body: some View {
    VStack {
      HStack(alignment: .center) {
        Text("Retrieve chat history").padding(.leading, 10)
        Button(action: {
          Task {
            if !isRetrievingChatHistory {
              isRetrievingChatHistory = true
              await webSocketManager.connect()
              isRetrievingChatHistory = false
            }
          }
        }) {
          Image(
            systemName: "arrow.clockwise"
          )
          .font(.system(size: 15))
          .scaledToFit()
          .padding(.all, 4)
          .rotationEffect(.degrees(isRetrievingChatHistory ? 360 : 0))
          .animation(
            isRetrievingChatHistory
              ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default,
            value: isRetrievingChatHistory
          )
        }
        .background(
          isHoveringRetrieveLatestChatButton
            ? Color.gray.opacity(0.2) : Color.clear
        )
        .cornerRadius(8)
        .onHover { hovering in
          if hovering {
            isHoveringRetrieveLatestChatButton = true
          } else {
            isHoveringRetrieveLatestChatButton = false
          }
        }
        .buttonStyle(.borderless)
      }
      .frame(maxWidth: .infinity, minHeight: 60)
    }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

#Preview {
  ContentView()
}
