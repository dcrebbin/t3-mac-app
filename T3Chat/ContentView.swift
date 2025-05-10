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
        messages = []
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

  @State public var threads: [ConversationThread] = []
  @State public var messages: [ConversationMessage] = []
  @State private var newMessage: String = ""
  func messagesView(threadId: String) -> some View {
      let messages = messages.filter { $0.threadId == threadId }
      let sortedMessages = messages.sorted { 
          if let date0 = $0.created_at, let date1 = $1.created_at {
          return date0 < date1
        }
        return false
      }
      let thread = threads.first { $0.id == threadId }
      return VStack(alignment: .leading, spacing: 0) {
        Text(thread?.title ?? "")
          .font(.headline)
          .padding(.bottom, 10)
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
                    .padding(.bottom, 10)
                    .textSelection(.enabled)
                }
              }
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        TextField("New message", text: $newMessage)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding(.bottom, 10)
      }
  }
  
  var threadsView: some View {
    ForEach(threads, id: \.id) { thread in
      messagesView(threadId: thread.id).tabItem {
        Text(thread.title)
      }.padding(.all, 10)
    }
  }

  var body: some View {
    ZStack(alignment: .top) {
      TranslucentView(material: .hudWindow)
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .leading, spacing: 0) {
        TabView {
            VStack(alignment: .leading) {
            MessageView(errorText: $errorText, selectedThread: $selectedThread, threads: $threads, messages: $messages)
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
          threadsView
        }.tabViewStyle(.sidebarAdaptable).frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all).padding(.all, 0)
      }.onAppear {
        if ApplicationState.conversationThreads.count > 0 && ApplicationState.conversationMessages.count > 0 && threads.count == 0 && messages.count == 0 {
          print("ApplicationState.conversationThreads: \(ApplicationState.conversationThreads)")
          print("ApplicationState.conversationMessages: \(ApplicationState.conversationMessages)")
          let threadsData = Data(base64Encoded: ApplicationState.conversationThreads)
          let messagesData = Data(base64Encoded: ApplicationState.conversationMessages)
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .iso8601
          threads = try! decoder.decode([ConversationThread].self, from: threadsData ?? Data())
          messages = try! decoder.decode([ConversationMessage].self, from: messagesData ?? Data())
        }
      }
      .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity,alignment: .top)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
  }
}

#Preview {
  ContentView()
}

struct MessageView: View {
  @Binding var errorText: String?

  @State var isRetrievingChatHistory: Bool = false
  @State var isHoveringRetrieveLatestChatButton: Bool = false
  @Binding var selectedThread: ConversationThread?
  @Binding var threads: [ConversationThread]
  @Binding var messages: [ConversationMessage]

  func retrieveChatHistory() async {
    print("Retrieving chat history")
    isRetrievingChatHistory = true
    if let result = await T3.retrieveChatHistory() {
      threads = result.threads
      messages = result.messages
      print("Found \(threads.count) threads and \(messages.count) messages")
    }
    isRetrievingChatHistory = false
  }

  var body: some View {
    VStack {
      HStack(alignment: .center) {
        Text("Retrieve chat history").padding(.leading, 10)
        Button(action: {
          Task {
            if !isRetrievingChatHistory {
              await retrieveChatHistory()
            }
          }
        }) {
          Image(
            systemName:"arrow.clockwise"
          )
          .font(.system(size: 15))
          .scaledToFit()
          .padding(.all, 4)
          .rotationEffect(.degrees(isRetrievingChatHistory ? 360 : 0))
          .animation(
            isRetrievingChatHistory ? 
              Animation.linear(duration: 1).repeatForever(autoreverses: false) : 
              .default,
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
