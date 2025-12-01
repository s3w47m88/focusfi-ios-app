import SwiftUI
import SwiftData

@main
struct FocusFiApp: App {
    var modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Transaction.self, BankAccount.self)
        } catch {
            fatalError("Failed to initialize model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
