import SwiftUI
import ServiceManagement

struct PreferencesWindow: View {
    @AppStorage("workHoursStart") private var workHoursStart: Int = 9
    @AppStorage("workHoursEnd") private var workHoursEnd: Int = 17
    @State private var launchAtLogin: Bool = false
    @StateObject private var remindersViewModel: RemindersViewModel

    let intervalOptions = [15, 30, 45, 60, 90, 120]
    let hourOptions = Array(0...23)

    init() {
        _remindersViewModel = StateObject(
            wrappedValue: RemindersViewModel(
                exerciseManager: ExerciseManager(),
                onScheduleChange: {}
            )
        )
    }

    init(exerciseManager: ExerciseManager, onScheduleChange: @escaping () -> Void) {
        _remindersViewModel = StateObject(
            wrappedValue: RemindersViewModel(
                exerciseManager: exerciseManager,
                onScheduleChange: onScheduleChange
            )
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Health Timer Preferences")
                .font(.title2)
                .padding(.bottom, 10)

            remindersSection

            Spacer()

            Text("Changes take effect on the next scheduled notification.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .frame(width: 520, height: 430)
        .onAppear {
            checkLaunchAtLoginStatus()
        }
    }

    private var remindersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Reminders")
                .font(.headline)

            remindersList

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
    }

    private var remindersList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach($remindersViewModel.exercises, id: \.id) { exercise in
                HStack {
                    Text(exercise.wrappedValue.name)
                        .frame(width: 180, alignment: .leading)

                    Picker("", selection: exercise.intervalMinutes) {
                        ForEach(0..<intervalOptions.count, id: \.self) { (index: Int) in
                            let interval = intervalOptions[index]
                            Text(intervalLabel(for: interval)).tag(interval)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 110)
                    .onChange(of: exercise.intervalMinutes.wrappedValue) { newValue in
                        remindersViewModel.updateInterval(id: exercise.wrappedValue.id, minutes: newValue)
                    }

                    Toggle("Enabled", isOn: exercise.enabled)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: exercise.enabled.wrappedValue) { newValue in
                            remindersViewModel.updateEnabled(id: exercise.wrappedValue.id, enabled: newValue)
                        }
                }
            }
        }
    }

    private func intervalLabel(for interval: Int) -> String {
        if interval < 60 {
            return "\(interval)m"
        }
        let hours = interval / 60
        let minutes = interval % 60
        if minutes == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(minutes)m"
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
