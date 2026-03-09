import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \SleepRecord.sleepEnd, order: .reverse) private var records: [SleepRecord]

    private var last30Days: [SleepRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
        return records.filter {
            $0.sleepEnd > cutoff &&
            $0.sleepEnd > $0.sleepStart
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                List {
                    if !last30Days.isEmpty {
                        Section("Duração por Dia") {
                            chartView
                                .frame(height: 200)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 4)
                                .liquidGlassCard(cornerRadius: 20)
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    Section("Registros") {
                        if last30Days.isEmpty {
                            ContentUnavailableView(
                                "Sem registros",
                                systemImage: "moon.zzz",
                                description: Text("Os registros de sono aparecerão aqui.")
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        } else {
                            ForEach(last30Days, id: \.persistentModelID) { record in
                                NavigationLink(destination: SleepDetailView(record: record)) {
                                    recordRow(record)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Histórico")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var chartView: some View {
        Chart(last30Days.reversed(), id: \.persistentModelID) { record in
            BarMark(
                x: .value("Data", record.sleepEnd, unit: .day),
                y: .value("Horas", record.normalizedDuration / 3600)
            )
            .foregroundStyle(chartColor(for: record.quality))
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(values: [0, 2, 4, 6, 8, 10]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.white.opacity(0.2))
                AxisValueLabel {
                    if let hours = value.as(Int.self) {
                        Text("\(hours)h")
                            .foregroundStyle(Color.white.opacity(0.78))
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
                    .foregroundStyle(.white)
                Text("\(record.sleepStart.formatted(date: .omitted, time: .shortened)) → \(record.sleepEnd.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Text(formattedDuration(record.normalizedDuration))
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 18)
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
        let safeInterval = max(0, interval)
        let hours = Int(safeInterval) / 3600
        let minutes = (Int(safeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [SleepRecord.self, ActivityTimestamp.self], inMemory: true)
}
