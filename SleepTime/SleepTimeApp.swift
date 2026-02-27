import SwiftUI
import SwiftData

@main
struct SleepTimeApp: App {
    init() {
        BackgroundTaskService.register()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [SleepRecord.self, ActivityTimestamp.self])
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Sono", systemImage: "moon.fill")
                }

            HistoryView()
                .tabItem {
                    Label("Histórico", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            BackgroundTaskService.scheduleRefresh()
        }
    }
}
