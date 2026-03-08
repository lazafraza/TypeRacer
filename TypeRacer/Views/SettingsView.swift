import SwiftUI

struct SettingsView: View {
    @AppStorage("nickname", store: UserDefaults(suiteName: "group.com.typeracer.shared"))
    private var nickname: String = "Player"

    var body: some View {
        Form {
            Section("Profile") {
                HStack {
                    Text("Nickname")
                    Spacer()
                    TextField("Nickname", text: $nickname)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
