import SwiftUI

@main
struct CarboCreditApp: App {
    @StateObject private var store = CarboCreditStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
