import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \SleepRecord.sleepEnd, order: .reverse) private var records: [SleepRecord]

    private var last30Days: [SleepRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return records.filter { $0.sleepEnd > cutoff }
    }

    var body: some View {
        NavigationStack {
            List {
                if !last30Days.isEmpty {
                    Section("Duração por Dia") {
                        chartView
                            .frame(height: 200)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                }

                Section("Registros") {
                    if last30Days.isEmpty {
                        ContentUnavailableView(
                            "Sem registros",
                            systemImage: "moon.zzz",
                            description: Text("Os registros de sono aparecerão aqui.")
                        )
                    } else {
                        ForEach(last30Days, id: \.sleepStart) { record in
                            NavigationLink(destination: SleepDetailView(record: record)) {
                                recordRow(record)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Histórico")
        }
    }

    private var chartView: some View {
        Chart(last30Days.reversed(), id: \.sleepStart) { record in
            BarMark(
                x: .value("Data", record.sleepEnd, unit: .day),
                y: .value("Horas", record.duration / 3600)
            )
            .foregroundStyle(chartColor(for: record.quality))
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let hours = value.as(Int.self) {
                        Text("\(hours)h")
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private func recordRow(_ record: SleepRecord) -> some View {
        HStack {
            Image(systemName: record.quality.icon)
                .foregroundStyle(qualityColor(record.quality))
                .font(.title2)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(record.sleepEnd.formatted(date: .abbreviated, time: .omitted))
                    .font(.headline)
                Text("\(record.sleepStart.formatted(date: .omitted, time: .shortened)) → \(record.sleepEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(formattedDuration(record.duration))
                .font(.headline.monospacedDigit())
        }
        .padding(.vertical, 4)
    }

    private func chartColor(for quality: SleepQuality) -> Color {
        qualityColor(quality)
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
}

#Preview {
    HistoryView()
        .modelContainer(for: [SleepRecord.self, ActivityTimestamp.self], inMemory: true)
}
