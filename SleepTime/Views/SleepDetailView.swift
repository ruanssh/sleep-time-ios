import SwiftUI

struct SleepDetailView: View {
    let record: SleepRecord
    @State private var showHealthKitAlert = false
    @State private var healthKitMessage = ""

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: record.quality.icon)
                        .font(.system(size: 56))
                        .foregroundStyle(qualityColor)

                    Text(formattedDuration(record.duration))
                        .font(.system(size: 40, weight: .bold, design: .rounded))

                    Label(record.quality.label, systemImage: record.quality.icon)
                        .font(.headline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(qualityColor.opacity(0.15))
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Detalhes") {
                LabeledContent("Dormiu") {
                    Text(record.sleepStart.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Acordou") {
                    Text(record.sleepEnd.formatted(date: .abbreviated, time: .shortened))
                }
                LabeledContent("Duração") {
                    Text(formattedDuration(record.duration))
                }
                LabeledContent("Qualidade") {
                    Text(record.quality.label)
                }
            }

            Section {
                LabeledContent("HealthKit") {
                    if record.syncedToHealthKit {
                        Label("Sincronizado", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button("Sincronizar") {
                            syncToHealthKit()
                        }
                    }
                }
            }
        }
        .navigationTitle(record.sleepEnd.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .alert("HealthKit", isPresented: $showHealthKitAlert) {
            Button("OK") {}
        } message: {
            Text(healthKitMessage)
        }
    }

    private var qualityColor: Color {
        switch record.quality {
        case .poor: .red
        case .fair: .orange
        case .good: .green
        }
    }

    private func syncToHealthKit() {
        Task {
            do {
                try await HealthKitService.shared.requestAuthorization()
                try await HealthKitService.shared.saveSleepRecord(record)
                record.syncedToHealthKit = true
                healthKitMessage = "Sincronizado com sucesso!"
            } catch {
                healthKitMessage = "Erro: \(error.localizedDescription)"
            }
            showHealthKitAlert = true
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
