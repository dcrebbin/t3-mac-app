import SwiftUI

struct Settings: View {

    @State private var authToken = ApplicationState.authToken

    var body: some View {

        var version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        ScrollView {
            VStack(alignment: .leading) {
                Text("Voice Mode Chat for Mac v" + version).padding(.leading, 10).padding(.top, 10)
                Divider()
                Text("Auth Token*").bold().font(.system(size: 12)).padding(.leading, 10).padding(
                    .top, 10)
                HStack {
                    SecureField("", text: $authToken)
                        .padding(.horizontal, 10)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: authToken) {
                            ApplicationState.authToken = authToken
                            UserDefaults.standard.set(authToken, forKey: "authToken")
                        }
                }
                Text("*Auth Token Tutorial").bold().padding(.top, 10).padding(.leading, 10)
                Text(
                    "Note: this isn't just your OpenAI API key: this is your user auth token which is used to perform elevated actions for your account (dangerous)."
                ).font(.system(size: 10)).padding(.leading, 10).textSelection(.enabled)
                Spacer()
                Text("1. (Whilst logged in) head to: https://chatgpt.com").padding(.leading, 10)
                    .textSelection(.enabled)
                Text("2. Open your browser's developer tools and view the Network tab").padding(
                    .leading, 10
                ).textSelection(.enabled)
                Text("3. Find the request to: https://chatgpt.com/backend-api/conversations")
                    .padding(.leading, 10).textSelection(.enabled)
                Text(
                    "4. Copy & paste the Authorization header value (eyJhbGci...) into the field above"
                ).padding(.leading, 10).textSelection(.enabled)
                Image("AuthTokenTutorial")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 700, alignment: .center)
                    .padding(.leading, 10)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
