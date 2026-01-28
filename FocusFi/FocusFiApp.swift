import SwiftUI
import SwiftData

@main
struct FocusFiApp: App {
    var modelContainer: ModelContainer
    @StateObject private var authService = AuthService.shared

    init() {
        let schema = Schema([Transaction.self, BankAccount.self])
        let storeURL = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FocusFi.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            try? FileManager.default.removeItem(at: storeURL)
            do {
                modelContainer = try ModelContainer(for: schema, configurations: config)
            } catch {
                modelContainer = try! ModelContainer(
                    for: schema,
                    configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                )
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
        }
        .modelContainer(modelContainer)
    }
}
