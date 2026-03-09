import SwiftUI

struct SettingsView: View {
    @AppStorage("sleepWindowStart") private var sleepWindowStart = 20
    @AppStorage("sleepWindowEnd") private var sleepWindowEnd = 10
    @AppStorage("minSleepHours") private var minSleepHours = 4.0
    @AppStorage("healthKitEnabled") private var healthKitEnabled = true
    @State private var showHealthKitAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                LiquidGlassBackground()

                Form {
                    Section {
                        HStack(spacing: 14) {
                            SleepGlyph()

                            VStack(alignment: .leading, spacing: 3) {
                                Text("Preferências do Sono")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("Ajuste horários e integração com Saúde")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.78))
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .liquidGlassCard(cornerRadius: 20)
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        Picker("Início", selection: $sleepWindowStart) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formattedHour(hour)).tag(hour)
                            }
                        }
                        Picker("Fim", selection: $sleepWindowEnd) {
                            ForEach(0..<24, id: \.self) { hour in
                                Text(formattedHour(hour)).tag(hour)
                            }
                        }
                    } header: {
                        Text("Janela de Sono")
                    } footer: {
                        Text("O app detecta sono quando um período de inatividade começa dentro desta janela.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        HStack {
                            Slider(value: $minSleepHours, in: 2...8, step: 0.5)
                            Text("\(minSleepHours, specifier: "%.1f")h")
                                .monospacedDigit()
                                .frame(width: 44)
                        }
                    } header: {
                        Text("Duração Mínima")
                    } footer: {
                        Text("Períodos de inatividade menores que este valor não serão considerados como sono. Períodos acima de 12h também são ignorados para reduzir falsos positivos.")
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        Toggle("Sincronizar com Saúde", isOn: $healthKitEnabled)
                        if healthKitEnabled {
                            Button("Solicitar Permissão") {
                                requestHealthKitPermission()
                            }
                        }
                    } header: {
                        Text("HealthKit")
                    } footer: {
                        Text("Quando ativado, os registros de sono podem ser enviados para o app Saúde.")
                    }
                    .listRowBackground(Color.clear)

                    Section("Sobre") {
                        LabeledContent("Versão", value: "1.0.0")
                        LabeledContent("iOS mínimo", value: "17.0")
                    }
                    .listRowBackground(Color.clear)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Configurações")
            .navigationBarTitleDisplayMode(.inline)
            .alert("HealthKit", isPresented: $showHealthKitAlert) {
                Button("OK") {}
            } message: {
                Text("Permissão solicitada. Verifique as configurações do app Saúde.")
            }
        }
    }

    private func formattedHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let date = Calendar.current.date(from: DateComponents(hour: hour)) ?? .now
        return formatter.string(from: date)
    }

    private func requestHealthKitPermission() {
        Task {
            try? await HealthKitService.shared.requestAuthorization()
            showHealthKitAlert = true
        }
    }
}

#Preview {
    SettingsView()
}
