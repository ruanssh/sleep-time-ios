import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SleepRecord.sleepEnd, order: .reverse) private var records: [SleepRecord]
    @Query(sort: \ActivityTimestamp.date, order: .reverse) private var timestamps: [ActivityTimestamp]
    @State private var showHealthKitAlert = false
    @State private var healthKitMessage = ""
    @State private var showDetectionAlert = false
    @State private var detectionAlertMessage = ""

    private var lastNight: SleepRecord? {
        records.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let record = lastNight {
                        sleepCard(record)
                    } else {
                        noDataCard
                    }

                    detectButton
                    healthKitButton
                }
                .padding()
            }
            .navigationTitle("SleepTime")
            .onAppear {
                recordActivity()
                detectSleep(silent: true)
            }
            .alert("Detecção de Sono", isPresented: $showDetectionAlert) {
                Button("OK") {}
            } message: {
                Text(detectionAlertMessage)
            }
            .alert("HealthKit", isPresented: $showHealthKitAlert) {
                Button("OK") {}
            } message: {
                Text(healthKitMessage)
            }
        }
    }

    private func sleepCard(_ record: SleepRecord) -> some View {
        VStack(spacing: 16) {
            Image(systemName: record.quality.icon)
                .font(.system(size: 48))
                .foregroundStyle(qualityColor(record.quality))

            Text(formattedDuration(record.duration))
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text("de sono")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 32) {
                VStack {
                    Text("Dormiu")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(record.sleepStart.formatted(date: .omitted, time: .shortened))
                        .font(.title3.bold())
                }
                VStack {
                    Text("Acordou")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(record.sleepEnd.formatted(date: .omitted, time: .shortened))
                        .font(.title3.bold())
                }
            }

            Label(record.quality.label, systemImage: record.quality.icon)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(qualityColor(record.quality).opacity(0.15))
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var noDataCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Nenhum sono detectado")
                .font(.title3)
            if timestamps.isEmpty {
                Text("Use o app por alguns dias para que o sono seja detectado automaticamente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("\(timestamps.count) registro(s) de atividade")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let last = timestamps.first {
                    Text("Último: \(last.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var detectButton: some View {
        Button {
            detectSleep(silent: false)
        } label: {
            Label("Detectar Sono", systemImage: "waveform.path.ecg")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var healthKitButton: some View {
        Button {
            syncHealthKit()
        } label: {
            Label("Sincronizar com Saúde", systemImage: "heart.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.pink)
    }

    private func recordActivity() {
        let timestamp = ActivityTimestamp(date: .now, source: .foreground)
        context.insert(timestamp)
    }

    private func detectSleep(silent: Bool) {
        let last48h = Date.now.addingTimeInterval(-48 * 3600)
        let recentTimestamps = timestamps.filter { $0.date > last48h }

        guard recentTimestamps.count >= 2 else {
            if !silent {
                detectionAlertMessage = "Ainda não há dados suficientes. O app precisa de pelo menos 2 registros de atividade para detectar sono. Continue usando normalmente."
                showDetectionAlert = true
            }
            return
        }

        let newRecords = SleepDetectionService.detectSleepIncludingNow(
            timestamps: recentTimestamps,
            existingRecords: records
        )
        for record in newRecords {
            context.insert(record)
        }

        if !silent {
            if let longest = newRecords.max(by: { $0.duration < $1.duration }) {
                detectionAlertMessage = "Sono detectado! \(formattedDuration(longest.duration)) de sono registrado."
            } else {
                detectionAlertMessage = "Nenhum período de sono encontrado nas últimas 48h."
            }
            showDetectionAlert = true
        }
    }

    private func syncHealthKit() {
        guard let record = lastNight, !record.syncedToHealthKit else {
            healthKitMessage = record == nil ? "Nenhum registro para sincronizar." : "Já sincronizado."
            showHealthKitAlert = true
            return
        }

        Task {
            do {
                try await HealthKitService.shared.requestAuthorization()
                try await HealthKitService.shared.saveSleepRecord(record)
                record.syncedToHealthKit = true
                healthKitMessage = "Sono sincronizado com o app Saúde!"
            } catch {
                healthKitMessage = "Erro: \(error.localizedDescription)"
            }
            showHealthKitAlert = true
        }
    }

    private func qualityColor(_ quality: SleepQuality) -> Color {
        switch quality {
        case .poor: .red
        case .fair: .orange
        case .good: .green
        }
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    private var record: SleepRecord? { lastNight }
}

#Preview {
    HomeView()
        .modelContainer(for: [SleepRecord.self, ActivityTimestamp.self], inMemory: true)
}
