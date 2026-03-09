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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Sono", systemImage: "moon.stars.fill")
                }

            HistoryView()
                .tabItem {
                    Label("Histórico", systemImage: "chart.bar.fill")
                }

            SessionsView()
                .tabItem {
                    Label("Sessões", systemImage: "list.bullet.clipboard")
                }

            SettingsView()
                .tabItem {
                    Label("Ajustes", systemImage: "gear")
                }
        }
        .tint(LiquidGlassTheme.accent)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .onChange(of: scenePhase) { _, phase in
            guard phase == .background else { return }
            BackgroundTaskService.scheduleRefresh()
        }
    }
}

enum LiquidGlassTheme {
    static let accent = Color(red: 0.47, green: 0.86, blue: 1.0)
    static let sky = Color(red: 0.35, green: 0.62, blue: 1.0)
    static let cyan = Color(red: 0.35, green: 0.96, blue: 0.9)
    static let indigo = Color(red: 0.08, green: 0.12, blue: 0.27)
    static let violet = Color(red: 0.17, green: 0.19, blue: 0.36)
}

struct LiquidGlassBackground: View {
    var body: some View {
        LinearGradient(
            colors: [LiquidGlassTheme.indigo, LiquidGlassTheme.violet, Color(red: 0.08, green: 0.22, blue: 0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LiquidGlassTheme.sky.opacity(0.9), LiquidGlassTheme.cyan.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 24)
                .offset(x: 80, y: -90)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [LiquidGlassTheme.cyan.opacity(0.5), LiquidGlassTheme.sky.opacity(0.25)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 280, height: 280)
                .blur(radius: 34)
                .offset(x: -70, y: 120)
        }
        .ignoresSafeArea()
    }
}

private struct LiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.65), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.2), radius: 24, x: 0, y: 12)
    }
}

extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
}

struct SleepGlyph: View {
    var body: some View {
        Image(systemName: "moon.stars.fill")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(
                LinearGradient(
                    colors: [LiquidGlassTheme.cyan, Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 58, height: 58)
            .liquidGlassCard(cornerRadius: 18)
    }
}
