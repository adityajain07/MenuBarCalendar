import SwiftUI

struct MenuView: View {
    @ObservedObject var vm: CalendarViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !vm.hasAccess {
                noAccessView
            } else if vm.events.isEmpty {
                emptyView
            } else {
                eventListView
            }

            Divider()
            settingsSection
            Divider()
            bottomBar
        }
        .padding()
        .frame(width: 320)
    }

    // MARK: - No Access

    private var noAccessView: some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Calendar access required")
                .font(.headline)
            Text("Grant access in System Settings → Privacy & Security → Calendars")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No more events today")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: - Event List

    private var eventListView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Today's Events")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            ForEach(vm.events) { event in
                eventRow(event)
            }
        }
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(nsColor: event.calendarColor))
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                if event.isAllDay {
                    Text("All day · \(event.calendarName)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(timeString(event.startDate)) – \(timeString(event.endDate)) · \(event.calendarName)")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !event.isAllDay {
                Text(relativeTime(event.startDate))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(urgencyColor(event.startDate))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isNext(event) ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Remind me")
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("", selection: $vm.reminderMinutes) {
                    ForEach([5, 10, 15, 20, 30], id: \.self) { m in
                        Text("\(m) min before").tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
            }

            DisclosureGroup {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(vm.availableCalendars, id: \.id) { cal in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(nsColor: cal.color))
                                .frame(width: 8, height: 8)

                            Text(cal.title)
                                .font(.system(size: 12))

                            Spacer()

                            Image(systemName: vm.selectedCalendarIDs.contains(cal.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(vm.selectedCalendarIDs.contains(cal.id) ? .blue : .secondary)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { vm.toggleCalendar(cal.id) }
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("Calendars")
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Button(action: { vm.fetchEvents() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .help("Refresh")

            Spacer()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func relativeTime(_ date: Date) -> String {
        let mins = Int(date.timeIntervalSince(Date()) / 60)
        if mins < 0 { return "now" }
        if mins < 1 { return "<1m" }
        if mins < 60 { return "\(mins)m" }
        let h = mins / 60
        let m = mins % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }

    private func urgencyColor(_ date: Date) -> Color {
        let mins = date.timeIntervalSince(Date()) / 60
        if mins <= 5 { return .red }
        if mins <= 15 { return .orange }
        return .secondary
    }

    private func isNext(_ event: CalendarEvent) -> Bool {
        guard let next = vm.nextEvent else { return false }
        return event.id == next.id
    }
}
