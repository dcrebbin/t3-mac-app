import SwiftUI

struct Settings: View {

  @State private var authToken = ApplicationState.authToken

  var body: some View {

    var version =
      Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

    ScrollView {
      VStack(alignment: .leading) {
        Text("T3 Chat for Mac v" + version).padding(.leading, 10).padding(.top, 10)
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
          "Note: this is your T3 Chat auth token which is used to perform elevated actions for your account (dangerous)."
        ).font(.system(size: 10)).padding(.leading, 10).textSelection(.enabled)
        Spacer()
        Text("1. Retrieve your auth cookie via your browser's developer tools").padding(
          .leading, 10
        )
        .textSelection(.enabled)
        Text("2. Developer Tools -> Application -> Cookies -> accessToken | access_token").padding(
          .leading, 10
        ).textSelection(.enabled)
        Text(
          "3. Copy & paste it into the field above"
        ).padding(.leading, 10).textSelection(.enabled)
        Spacer()
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}
