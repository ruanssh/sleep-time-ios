import SwiftUI

struct SleepDetailView: View {
    let record: SleepRecord
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editedSleepStart: Date
    @State private var editedSleepEnd: Date
    @State private var isEditing: Bool
    @State private var showDeleteAlert = false
    @State private var showHealthKitAlert = false
    @State private var healthKitMessage = ""

    init(record: SleepRecord, isEditing: Bool = false) {
        self.record = record
        self._editedSleepStart = State(initialValue: record.sleepStart)
        self._editedSleepEnd = State(initialValue: record.sleepEnd)
        self._isEditing = State(initialValue: isEditing)
    }

    var body: some View {
        ZStack {
            LiquidGlassBackground()

            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: record.quality.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(qualityColor)

                        Text(formattedDuration(record.normalizedDuration))
                            .font(.system(size: 40, weight: .bold, design: .rounded))

                        Label(record.quality.label, systemImage: record.quality.icon)
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(qualityColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 22)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section("Detalhes") {
                    if isEditing {
                        DatePicker("Dormiu", selection: $editedSleepStart)
                        DatePicker("Acordou", selection: $editedSleepEnd)
                    } else {
                        LabeledContent("Dormiu") {
                            Text(record.sleepStart.formatted(date: .abbreviated, time: .shortened))
                        }
                        LabeledContent("Acordou") {
                            Text(record.sleepEnd.formatted(date: .abbreviated, time: .shortened))
                        }
                    }
                    if isEditing && !isValidRange {
                        Label("\"Acordou\" deve ser depois de \"Dormiu\"", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    LabeledContent("Duração") {
                        let duration = isEditing ? editedSleepEnd.timeIntervalSince(editedSleepStart) : record.normalizedDuration
                        Text(duration > 0 ? formattedDuration(duration) : "--")
                    }
                    LabeledContent("Qualidade") {
                        Text(record.quality.label)
                    }
                }
                .listRowBackground(Color.clear)

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
                .listRowBackground(Color.clear)

                if isEditing {
                    Section {
                        Button("Excluir Registro", role: .destructive) {
                            showDeleteAlert = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .listStyle(.insetGrouped)
        }
        .navigationTitle(record.sleepEnd.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isEditing {
                    Button("Salvar") {
                        saveChanges()
                    }
                    .bold()
                    .disabled(!isValidRange)
                } else {
                    Button("Editar") {
                        isEditing = true
                    }
                }
            }
            if isEditing {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancelar") {
                        editedSleepStart = record.sleepStart
                        editedSleepEnd = record.sleepEnd
                        isEditing = false
                    }
                }
            }
        }
        .alert("HealthKit", isPresented: $showHealthKitAlert) {
            Button("OK") {}
        } message: {
            Text(healthKitMessage)
        }
        .alert("Excluir registro?", isPresented: $showDeleteAlert) {
            Button("Excluir", role: .destructive) {
                modelContext.delete(record)
                dismiss()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita.")
        }
    }

    private var qualityColor: Color {
        switch record.quality {
        case .poor: .red
        case .fair: .orange
        case .good: .green
        }
    }

    private var isValidRange: Bool {
        editedSleepEnd > editedSleepStart
    }

    private func saveChanges() {
        guard isValidRange else { return }
        record.sleepStart = editedSleepStart
        record.sleepEnd = editedSleepEnd
        record.refreshDuration()
        record.syncedToHealthKit = false
        isEditing = false
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
        let safeInterval = max(0, interval)
        let hours = Int(safeInterval) / 3600
        let minutes = (Int(safeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
