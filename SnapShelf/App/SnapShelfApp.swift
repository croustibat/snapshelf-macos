import SwiftUI

@main
struct SnapShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ScreenshotStore()
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some Scene {
        MenuBarExtra("SnapShelf", systemImage: "photo.stack") {
            ShelfView()
                .environmentObject(store)
                .environmentObject(settingsViewModel)
                .frame(width: 440, height: 620)
                .task {
                    settingsViewModel.bind(to: store)
                    await store.start()
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
                .environmentObject(settingsViewModel)
                .frame(width: 460, height: 280)
                .task {
                    settingsViewModel.bind(to: store)
                }
        }
    }
}
