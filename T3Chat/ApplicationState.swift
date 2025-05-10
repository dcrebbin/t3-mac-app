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
}
