import SwiftUI
import ServiceManagement

struct PreferencesWindow: View {
    @AppStorage("timerInterval") private var timerInterval: Int = 30
    @AppStorage("workHoursStart") private var workHoursStart: Int = 9
    @AppStorage("workHoursEnd") private var workHoursEnd: Int = 17
    @State private var launchAtLogin: Bool = false

    let timerOptions = [15, 30, 45, 60]
    let hourOptions = Array(0...23)

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Timer Preferences")
                .font(.title2)
                .padding(.bottom, 10)

            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Timer Interval:")
                        .frame(width: 130, alignment: .leading)

                    Picker("", selection: $timerInterval) {
                        ForEach(timerOptions, id: \.self) { interval in
                            Text("\(interval) minutes").tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                HStack {
                    Text("Work Hours Start:")
                        .frame(width: 130, alignment: .leading)

                    Picker("", selection: $workHoursStart) {
                        ForEach(hourOptions, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                HStack {
                    Text("Work Hours End:")
                        .frame(width: 130, alignment: .leading)

                    Picker("", selection: $workHoursEnd) {
                        ForEach(hourOptions, id: \.self) { hour in
                            Text(formatHour(hour)).tag(hour)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        setLaunchAtLogin(enabled: newValue)
                    }
            }

            Spacer()

            Text("Changes take effect on the next scheduled notification.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 400, height: 300)
        .onAppear {
            checkLaunchAtLoginStatus()
        }
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = 0
        if let date = calendar.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }

    private func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error)")
            }
        }
    }

    private func checkLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}
