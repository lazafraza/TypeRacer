import SwiftUI

struct CompactView: View {
    let onStartRace: () -> Void

    var body: some View {
        Button(action: onStartRace) {
            HStack(spacing: 12) {
                Image(systemName: "flag.checkered")
                    .font(.title2)
                Text("Start a Type Race!")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundStyle(.white)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
}
