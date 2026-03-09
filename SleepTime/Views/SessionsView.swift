import SwiftUI
import SwiftData

struct SessionsView: View {
    @Query(sort: \SleepRecord.sleepEnd, order: .reverse) private var records: [SleepRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var recordToDelete: SleepRecord?
    @State private var showDeleteAlert = false
    @State private var newRecord: SleepRecord?
    @State private var navigateToNew = false

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                Group {
                    if records.isEmpty {
                        ContentUnavailableView(
                            "Sem sessões",
                            systemImage: "moon.zzz",
                            description: Text("As sessões de sono aparecerão aqui.")
                        )
                        .foregroundStyle(.white.opacity(0.9))
                    } else {
                        List {
                            ForEach(records, id: \.persistentModelID) { record in
                                NavigationLink(destination: SleepDetailView(record: record)) {
                                    recordRow(record)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { indexSet in
                                if let index = indexSet.first {
                                    recordToDelete = records[index]
                                    showDeleteAlert = true
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Sessões")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        addManualSession()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Excluir registro?", isPresented: $showDeleteAlert) {
                Button("Excluir", role: .destructive) {
                    if let record = recordToDelete {
                        modelContext.delete(record)
                        recordToDelete = nil
                    }
                }
                Button("Cancelar", role: .cancel) {
                    recordToDelete = nil
                }
            } message: {
                Text("Esta ação não pode ser desfeita.")
            }
            .navigationDestination(isPresented: $navigateToNew) {
                if let record = newRecord {
                    SleepDetailView(record: record, isEditing: true)
                }
            }
        }
    }

    private func addManualSession() {
        let calendar = Calendar.current
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let sleepStart = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: yesterday)!
        let sleepEnd = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now)!

        let record = SleepRecord(sleepStart: sleepStart, sleepEnd: sleepEnd)
        modelContext.insert(record)
        newRecord = record
        navigateToNew = true
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
    SessionsView()
        .modelContainer(for: [SleepRecord.self, ActivityTimestamp.self], inMemory: true)
}
