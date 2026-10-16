import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        PlateHostRepresentable()
            .ignoresSafeArea()
    }
}

@MainActor
private struct PlateHostRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> PlateHostController {
        PlateHostController(session: PlateSession.live())
    }

    func updateUIViewController(_ uiViewController: PlateHostController, context: Context) {}
}

#Preview {
    ContentView()
}
