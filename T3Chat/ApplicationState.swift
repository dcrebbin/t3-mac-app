import SwiftUI

struct ApplicationState {
    static var authToken: String {
        get {
            UserDefaults.standard.string(forKey: "authToken") ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "authToken")
        }
    }

    static var conversationThreads: String {
        get {
            UserDefaults.standard.object(forKey: "conversationThreads") as? String ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "conversationThreads")
        }
    }

    static var conversationMessages: String {
        get {
            UserDefaults.standard.object(forKey: "conversationMessages") as? String ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "conversationMessages")
        }
    }
}
